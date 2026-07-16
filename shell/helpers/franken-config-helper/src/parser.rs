use std::collections::{BTreeMap, BTreeSet};
use std::ops::Range;

use toml::Spanned;
use toml::de::{DeInteger, DeTable, DeValue};

use crate::diagnostic::{Diagnostic, Severity, SourceSpan};
use crate::migration;
use crate::schema::{
    AppearanceMode, AutoOrPixels, CURRENT_SCHEMA_VERSION, CommandDefinition, Configuration,
    ContextOverflow, ContextPriority, ControlCenterEdge, DynamicColorSource, Edge, FallbackMode,
    FirstDayOfWeek, FocusedWindowAction, MonthFormat, NetworkSpeedShow, NetworkSpeedUnit,
    OverviewProvider, ScrollDirection, SpecialWorkspace, TimeFormat, VerticalDateTimeLayout,
    VicinaePosition,
};

pub struct ValidationResult {
    pub detected_source_schema_version: Option<u32>,
    pub effective_schema_version: Option<u32>,
    pub migration_occurred: bool,
    pub normalized_configuration: Option<Configuration>,
    pub warnings: Vec<Diagnostic>,
    pub errors: Vec<Diagnostic>,
}

struct Located<T> {
    value: T,
    span: Range<usize>,
}

struct ConfigParser<'a> {
    source_id: &'a str,
    source_text: &'a str,
    warnings: Vec<Diagnostic>,
    errors: Vec<Diagnostic>,
    locations: BTreeMap<String, Range<usize>>,
}

pub fn validate_and_normalize(source_id: &str, source_text: &str) -> ValidationResult {
    let root = match DeTable::parse(source_text) {
        Ok(root) => root,
        Err(error) => {
            return ValidationResult {
                detected_source_schema_version: None,
                effective_schema_version: None,
                migration_occurred: false,
                normalized_configuration: None,
                warnings: Vec::new(),
                errors: vec![Diagnostic::from_span(
                    Severity::Error,
                    "CONFIG_TOML_PARSE_ERROR",
                    error.message(),
                    None,
                    SourceSpan {
                        identifier: source_id,
                        text: source_text,
                        span: error.span(),
                    },
                    Some("Correct the TOML syntax and validate the file again."),
                )],
            };
        }
    };

    let mut parser = ConfigParser {
        source_id,
        source_text,
        warnings: Vec::new(),
        errors: Vec::new(),
        locations: BTreeMap::new(),
    };

    let detected_source_schema_version = parser.detect_schema_version(root.get_ref());
    let Some(source_schema_version) = detected_source_schema_version else {
        return parser.finish(None, None, false);
    };

    if source_schema_version > CURRENT_SCHEMA_VERSION {
        parser.error(
            "CONFIG_SCHEMA_TOO_NEW",
            format!(
                "schema version {source_schema_version} is newer than the supported schema version {CURRENT_SCHEMA_VERSION}"
            ),
            Some("schemaVersion"),
            parser.location("schemaVersion"),
            Some("Upgrade Franken Shell or validate with a helper that supports this schema."),
        );
        return parser.finish(Some(source_schema_version), None, false);
    }

    let mut config = Configuration {
        schema_version: source_schema_version,
        ..Configuration::default()
    };
    parser.parse_root(root.get_ref(), &mut config);

    let migration = match migration::migrate(&mut config, source_schema_version) {
        Ok(migration) => migration,
        Err(error) => {
            parser.error(
                "CONFIG_MIGRATION_PATH_MISSING",
                error.to_string(),
                Some("schemaVersion"),
                parser.location("schemaVersion"),
                Some("Use a helper version that contains every sequential migration step."),
            );
            return parser.finish(Some(source_schema_version), None, false);
        }
    };

    if migration.occurred {
        parser.warning(
            "CONFIG_MIGRATED_IN_MEMORY",
            format!(
                "configuration schema {source_schema_version} was migrated in memory to schema {}",
                migration.effective_version
            ),
            Some("schemaVersion"),
            parser.location("schemaVersion"),
            Some("The source file was not changed."),
        );
    }

    parser.semantic_validation(&config);

    let normalized_configuration = parser.errors.is_empty().then_some(config);
    parser
        .finish(
            Some(source_schema_version),
            Some(migration.effective_version),
            migration.occurred,
        )
        .with_configuration(normalized_configuration)
}

impl ValidationResult {
    fn with_configuration(mut self, configuration: Option<Configuration>) -> Self {
        self.normalized_configuration = configuration;
        self
    }
}

impl ConfigParser<'_> {
    fn finish(
        self,
        detected: Option<u32>,
        effective: Option<u32>,
        migration_occurred: bool,
    ) -> ValidationResult {
        ValidationResult {
            detected_source_schema_version: detected,
            effective_schema_version: effective,
            migration_occurred,
            normalized_configuration: None,
            warnings: self.warnings,
            errors: self.errors,
        }
    }

    fn detect_schema_version(&mut self, root: &DeTable<'_>) -> Option<u32> {
        let Some(value) = root.get("schemaVersion") else {
            self.error(
                "CONFIG_SCHEMA_VERSION_REQUIRED",
                "required field schemaVersion is missing",
                Some("schemaVersion"),
                None,
                Some("Add schemaVersion = 1 at the top level."),
            );
            return None;
        };
        self.remember("schemaVersion", value.span());
        let Some(integer) = value.get_ref().as_integer() else {
            self.type_error("schemaVersion", "integer", value);
            return None;
        };
        let Some(version) = integer_to_u32(integer) else {
            self.error(
                "CONFIG_VALUE_OUT_OF_RANGE",
                "schemaVersion must be a non-negative 32-bit integer",
                Some("schemaVersion"),
                Some(value.span()),
                Some("Use schemaVersion = 1 for the current schema."),
            );
            return None;
        };
        Some(version)
    }

    fn parse_root(&mut self, root: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            root,
            &[
                "schemaVersion",
                "shell",
                "appearance",
                "bar",
                "controlCenter",
                "workspaces",
                "integrations",
                "commands",
            ],
            "",
        );

        if let Some(table) = self.optional_table(root, "shell", "shell") {
            self.parse_shell(table, config);
        }
        if let Some(table) = self.optional_table(root, "appearance", "appearance") {
            self.parse_appearance(table, config);
        }
        if let Some(table) = self.optional_table(root, "bar", "bar") {
            self.parse_bar(table, config);
        }
        if let Some(table) = self.optional_table(root, "controlCenter", "controlCenter") {
            self.parse_control_center(table, config);
        }
        if let Some(table) = self.optional_table(root, "workspaces", "workspaces") {
            self.parse_workspaces(table, config);
        }
        if let Some(table) = self.optional_table(root, "integrations", "integrations") {
            self.parse_integrations(table, config);
        }
        if let Some(table) = self.optional_table(root, "commands", "commands") {
            config.commands = self.parse_commands(table);
        }
    }

    fn parse_shell(&mut self, table: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            table,
            &[
                "language",
                "timeFormat",
                "firstDayOfWeek",
                "startup",
                "reload",
            ],
            "shell",
        );
        if let Some(value) = self.string(table, "language", "shell.language") {
            if value.value.is_empty() {
                self.error(
                    "CONFIG_VALUE_REQUIRED",
                    "shell.language must not be empty",
                    Some("shell.language"),
                    Some(value.span),
                    Some("Use \"system\" or an explicit locale such as \"en-IN\"."),
                );
            } else {
                config.shell.language = value.value;
            }
        }
        if let Some(value) = self.string(table, "timeFormat", "shell.timeFormat") {
            match value.value.as_str() {
                "24h" => config.shell.time_format = TimeFormat::TwentyFourHour,
                "12h" => config.shell.time_format = TimeFormat::TwelveHour,
                _ => self.invalid_enum("shell.timeFormat", &value, &["24h", "12h"]),
            }
        }
        if let Some(value) = self.string(table, "firstDayOfWeek", "shell.firstDayOfWeek") {
            match value.value.as_str() {
                "system" => config.shell.first_day_of_week = FirstDayOfWeek::System,
                "monday" => config.shell.first_day_of_week = FirstDayOfWeek::Monday,
                "sunday" => config.shell.first_day_of_week = FirstDayOfWeek::Sunday,
                _ => self.invalid_enum(
                    "shell.firstDayOfWeek",
                    &value,
                    &["system", "monday", "sunday"],
                ),
            }
        }
        if let Some(startup) = self.optional_table(table, "startup", "shell.startup") {
            self.warn_unknown_fields(
                startup,
                &["showReadinessToast", "restoreSessionState"],
                "shell.startup",
            );
            self.assign_bool(
                startup,
                "showReadinessToast",
                "shell.startup.showReadinessToast",
                &mut config.shell.startup.show_readiness_toast,
            );
            self.assign_bool(
                startup,
                "restoreSessionState",
                "shell.startup.restoreSessionState",
                &mut config.shell.startup.restore_session_state,
            );
        }
        if let Some(reload) = self.optional_table(table, "reload", "shell.reload") {
            self.warn_unknown_fields(reload, &["watchConfig", "debounceMs"], "shell.reload");
            self.assign_bool(
                reload,
                "watchConfig",
                "shell.reload.watchConfig",
                &mut config.shell.reload.watch_config,
            );
            self.assign_u32(
                reload,
                "debounceMs",
                "shell.reload.debounceMs",
                &mut config.shell.reload.debounce_ms,
            );
        }
    }

    fn parse_appearance(&mut self, table: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            table,
            &[
                "mode",
                "fallbackMode",
                "iconTheme",
                "reducedMotion",
                "highContrast",
                "dynamicColors",
                "surfaceOpacity",
                "blur",
                "font",
            ],
            "appearance",
        );
        if let Some(value) = self.string(table, "mode", "appearance.mode") {
            match value.value.as_str() {
                "dynamic" => config.appearance.mode = AppearanceMode::Dynamic,
                "dark" => config.appearance.mode = AppearanceMode::Dark,
                "light" => config.appearance.mode = AppearanceMode::Light,
                _ => self.invalid_enum("appearance.mode", &value, &["dynamic", "dark", "light"]),
            }
        }
        if let Some(value) = self.string(table, "fallbackMode", "appearance.fallbackMode") {
            match value.value.as_str() {
                "dark" => config.appearance.fallback_mode = FallbackMode::Dark,
                "light" => config.appearance.fallback_mode = FallbackMode::Light,
                _ => self.invalid_enum("appearance.fallbackMode", &value, &["dark", "light"]),
            }
        }
        self.assign_nonempty_string(
            table,
            "iconTheme",
            "appearance.iconTheme",
            &mut config.appearance.icon_theme,
        );
        self.assign_bool(
            table,
            "reducedMotion",
            "appearance.reducedMotion",
            &mut config.appearance.reduced_motion,
        );
        self.assign_bool(
            table,
            "highContrast",
            "appearance.highContrast",
            &mut config.appearance.high_contrast,
        );

        if let Some(dynamic) =
            self.optional_table(table, "dynamicColors", "appearance.dynamicColors")
        {
            self.warn_unknown_fields(
                dynamic,
                &["enabled", "source", "transition"],
                "appearance.dynamicColors",
            );
            self.assign_bool(
                dynamic,
                "enabled",
                "appearance.dynamicColors.enabled",
                &mut config.appearance.dynamic_colors.enabled,
            );
            if let Some(value) = self.string(dynamic, "source", "appearance.dynamicColors.source") {
                match value.value.as_str() {
                    "caelestia" => {
                        config.appearance.dynamic_colors.source = DynamicColorSource::Caelestia
                    }
                    _ => {
                        self.invalid_enum("appearance.dynamicColors.source", &value, &["caelestia"])
                    }
                }
            }
            self.assign_bool(
                dynamic,
                "transition",
                "appearance.dynamicColors.transition",
                &mut config.appearance.dynamic_colors.transition,
            );
        }

        if let Some(opacity) =
            self.optional_table(table, "surfaceOpacity", "appearance.surfaceOpacity")
        {
            self.warn_unknown_fields(
                opacity,
                &["bar", "controlCenter", "popover", "notification"],
                "appearance.surfaceOpacity",
            );
            self.assign_bounded_f64(
                opacity,
                "bar",
                "appearance.surfaceOpacity.bar",
                0.75,
                1.0,
                &mut config.appearance.surface_opacity.bar,
            );
            self.assign_bounded_f64(
                opacity,
                "controlCenter",
                "appearance.surfaceOpacity.controlCenter",
                0.75,
                1.0,
                &mut config.appearance.surface_opacity.control_center,
            );
            self.assign_bounded_f64(
                opacity,
                "popover",
                "appearance.surfaceOpacity.popover",
                0.75,
                1.0,
                &mut config.appearance.surface_opacity.popover,
            );
            self.assign_bounded_f64(
                opacity,
                "notification",
                "appearance.surfaceOpacity.notification",
                0.75,
                1.0,
                &mut config.appearance.surface_opacity.notification,
            );
        }

        if let Some(blur) = self.optional_table(table, "blur", "appearance.blur") {
            self.warn_unknown_fields(blur, &["enabled", "popovers"], "appearance.blur");
            self.assign_bool(
                blur,
                "enabled",
                "appearance.blur.enabled",
                &mut config.appearance.blur.enabled,
            );
            self.assign_bool(
                blur,
                "popovers",
                "appearance.blur.popovers",
                &mut config.appearance.blur.popovers,
            );
        }

        if let Some(font) = self.optional_table(table, "font", "appearance.font") {
            self.warn_unknown_fields(font, &["family", "scale"], "appearance.font");
            self.assign_nonempty_string(
                font,
                "family",
                "appearance.font.family",
                &mut config.appearance.font.family,
            );
            self.assign_bounded_f64(
                font,
                "scale",
                "appearance.font.scale",
                0.8,
                1.5,
                &mut config.appearance.font.scale,
            );
        }
    }

    fn parse_bar(&mut self, table: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            table,
            &[
                "enabled",
                "edge",
                "thickness",
                "visibleOn",
                "hideInFullscreen",
                "autohide",
                "layout",
                "workspacePager",
                "contextRegion",
                "networkSpeed",
                "battery",
                "dateTime",
                "vicinae",
            ],
            "bar",
        );
        self.assign_bool(table, "enabled", "bar.enabled", &mut config.bar.enabled);
        if let Some(value) = self.string(table, "edge", "bar.edge") {
            match value.value.as_str() {
                "left" => config.bar.edge = Edge::Left,
                "right" => config.bar.edge = Edge::Right,
                "top" => config.bar.edge = Edge::Top,
                "bottom" => config.bar.edge = Edge::Bottom,
                _ => self.invalid_enum("bar.edge", &value, &["left", "right", "top", "bottom"]),
            }
        }
        if let Some(value) = table.get("thickness") {
            self.remember("bar.thickness", value.span());
            if let Some(auto_or_pixels) = self.auto_or_positive_pixels(value, "bar.thickness") {
                config.bar.thickness = auto_or_pixels;
            }
        }
        self.assign_nonempty_string(
            table,
            "visibleOn",
            "bar.visibleOn",
            &mut config.bar.visible_on,
        );
        self.assign_bool(
            table,
            "hideInFullscreen",
            "bar.hideInFullscreen",
            &mut config.bar.hide_in_fullscreen,
        );

        if let Some(autohide) = self.optional_table(table, "autohide", "bar.autohide") {
            self.warn_unknown_fields(
                autohide,
                &[
                    "enabled",
                    "revealDelayMs",
                    "hideDelayMs",
                    "activationWidth",
                    "revealOverFullscreen",
                ],
                "bar.autohide",
            );
            self.assign_bool(
                autohide,
                "enabled",
                "bar.autohide.enabled",
                &mut config.bar.autohide.enabled,
            );
            self.assign_u32(
                autohide,
                "revealDelayMs",
                "bar.autohide.revealDelayMs",
                &mut config.bar.autohide.reveal_delay_ms,
            );
            self.assign_u32(
                autohide,
                "hideDelayMs",
                "bar.autohide.hideDelayMs",
                &mut config.bar.autohide.hide_delay_ms,
            );
            self.assign_positive_f64(
                autohide,
                "activationWidth",
                "bar.autohide.activationWidth",
                &mut config.bar.autohide.activation_width,
            );
            self.assign_bool(
                autohide,
                "revealOverFullscreen",
                "bar.autohide.revealOverFullscreen",
                &mut config.bar.autohide.reveal_over_fullscreen,
            );
        }

        if let Some(layout) = self.optional_table(table, "layout", "bar.layout") {
            self.warn_unknown_fields(layout, &["start", "context", "end"], "bar.layout");
            self.assign_string_array(
                layout,
                "start",
                "bar.layout.start",
                &mut config.bar.layout.start,
            );
            self.assign_string_array(
                layout,
                "context",
                "bar.layout.context",
                &mut config.bar.layout.context,
            );
            self.assign_string_array(layout, "end", "bar.layout.end", &mut config.bar.layout.end);
        }

        if let Some(pager) = self.optional_table(table, "workspacePager", "bar.workspacePager") {
            self.warn_unknown_fields(
                pager,
                &[
                    "groupSize",
                    "showOccupancy",
                    "showApplicationIcons",
                    "scrollEnabled",
                    "scrollDirection",
                ],
                "bar.workspacePager",
            );
            self.assign_bounded_u32(
                pager,
                "groupSize",
                "bar.workspacePager.groupSize",
                3,
                10,
                &mut config.bar.workspace_pager.group_size,
            );
            self.assign_bool(
                pager,
                "showOccupancy",
                "bar.workspacePager.showOccupancy",
                &mut config.bar.workspace_pager.show_occupancy,
            );
            self.assign_bool(
                pager,
                "showApplicationIcons",
                "bar.workspacePager.showApplicationIcons",
                &mut config.bar.workspace_pager.show_application_icons,
            );
            self.assign_bool(
                pager,
                "scrollEnabled",
                "bar.workspacePager.scrollEnabled",
                &mut config.bar.workspace_pager.scroll_enabled,
            );
            if let Some(value) = self.string(
                pager,
                "scrollDirection",
                "bar.workspacePager.scrollDirection",
            ) {
                match value.value.as_str() {
                    "natural" => {
                        config.bar.workspace_pager.scroll_direction = ScrollDirection::Natural
                    }
                    _ => self.invalid_enum(
                        "bar.workspacePager.scrollDirection",
                        &value,
                        &["natural"],
                    ),
                }
            }
        }

        if let Some(region) = self.optional_table(table, "contextRegion", "bar.contextRegion") {
            self.warn_unknown_fields(
                region,
                &["slots", "overflow", "priority"],
                "bar.contextRegion",
            );
            self.assign_positive_u32(
                region,
                "slots",
                "bar.contextRegion.slots",
                &mut config.bar.context_region.slots,
            );
            if let Some(value) = self.string(region, "overflow", "bar.contextRegion.overflow") {
                match value.value.as_str() {
                    "stack" => config.bar.context_region.overflow = ContextOverflow::Stack,
                    _ => self.invalid_enum("bar.contextRegion.overflow", &value, &["stack"]),
                }
            }
            if let Some(values) =
                self.string_array(region, "priority", "bar.contextRegion.priority")
            {
                let mut priorities = Vec::with_capacity(values.len());
                for value in values {
                    let priority = match value.value.as_str() {
                        "critical" => Some(ContextPriority::Critical),
                        "privacy" => Some(ContextPriority::Privacy),
                        "recording" => Some(ContextPriority::Recording),
                        "connectivity" => Some(ContextPriority::Connectivity),
                        "devices" => Some(ContextPriority::Devices),
                        "activity" => Some(ContextPriority::Activity),
                        _ => {
                            self.invalid_enum(
                                "bar.contextRegion.priority",
                                &value,
                                &[
                                    "critical",
                                    "privacy",
                                    "recording",
                                    "connectivity",
                                    "devices",
                                    "activity",
                                ],
                            );
                            None
                        }
                    };
                    if let Some(priority) = priority {
                        priorities.push(priority);
                    }
                }
                config.bar.context_region.priority = priorities;
            }
        }

        if let Some(speed) = self.optional_table(table, "networkSpeed", "bar.networkSpeed") {
            self.warn_unknown_fields(
                speed,
                &[
                    "enabled",
                    "show",
                    "unit",
                    "base",
                    "decimals",
                    "updateIntervalMs",
                    "smoothingWindow",
                    "zeroFormat",
                ],
                "bar.networkSpeed",
            );
            self.assign_bool(
                speed,
                "enabled",
                "bar.networkSpeed.enabled",
                &mut config.bar.network_speed.enabled,
            );
            if let Some(value) = self.string(speed, "show", "bar.networkSpeed.show") {
                match value.value.as_str() {
                    "download" => config.bar.network_speed.show = NetworkSpeedShow::Download,
                    _ => self.invalid_enum("bar.networkSpeed.show", &value, &["download"]),
                }
            }
            if let Some(value) = self.string(speed, "unit", "bar.networkSpeed.unit") {
                match value.value.as_str() {
                    "bytes" => config.bar.network_speed.unit = NetworkSpeedUnit::Bytes,
                    "bits" => config.bar.network_speed.unit = NetworkSpeedUnit::Bits,
                    _ => self.invalid_enum("bar.networkSpeed.unit", &value, &["bytes", "bits"]),
                }
            }
            if let Some(value) = self.u32(speed, "base", "bar.networkSpeed.base") {
                match value.value {
                    1000 | 1024 => config.bar.network_speed.base = value.value,
                    _ => self.error(
                        "CONFIG_VALUE_OUT_OF_RANGE",
                        "bar.networkSpeed.base must be 1000 or 1024",
                        Some("bar.networkSpeed.base"),
                        Some(value.span),
                        Some("Use base = 1000 or base = 1024."),
                    ),
                }
            }
            self.assign_u32(
                speed,
                "decimals",
                "bar.networkSpeed.decimals",
                &mut config.bar.network_speed.decimals,
            );
            self.assign_positive_u32(
                speed,
                "updateIntervalMs",
                "bar.networkSpeed.updateIntervalMs",
                &mut config.bar.network_speed.update_interval_ms,
            );
            self.assign_positive_u32(
                speed,
                "smoothingWindow",
                "bar.networkSpeed.smoothingWindow",
                &mut config.bar.network_speed.smoothing_window,
            );
            self.assign_nonempty_string(
                speed,
                "zeroFormat",
                "bar.networkSpeed.zeroFormat",
                &mut config.bar.network_speed.zero_format,
            );
        }

        if let Some(battery) = self.optional_table(table, "battery", "bar.battery") {
            self.warn_unknown_fields(
                battery,
                &["showPercentSign", "chargingAnimation"],
                "bar.battery",
            );
            self.assign_bool(
                battery,
                "showPercentSign",
                "bar.battery.showPercentSign",
                &mut config.bar.battery.show_percent_sign,
            );
            self.assign_bool(
                battery,
                "chargingAnimation",
                "bar.battery.chargingAnimation",
                &mut config.bar.battery.charging_animation,
            );
        }

        if let Some(date_time) = self.optional_table(table, "dateTime", "bar.dateTime") {
            self.warn_unknown_fields(
                date_time,
                &["showDate", "monthFormat", "verticalLayout"],
                "bar.dateTime",
            );
            self.assign_bool(
                date_time,
                "showDate",
                "bar.dateTime.showDate",
                &mut config.bar.date_time.show_date,
            );
            if let Some(value) = self.string(date_time, "monthFormat", "bar.dateTime.monthFormat") {
                match value.value.as_str() {
                    "shortText" => config.bar.date_time.month_format = MonthFormat::ShortText,
                    _ => self.invalid_enum("bar.dateTime.monthFormat", &value, &["shortText"]),
                }
            }
            if let Some(value) =
                self.string(date_time, "verticalLayout", "bar.dateTime.verticalLayout")
            {
                match value.value.as_str() {
                    "stacked" => {
                        config.bar.date_time.vertical_layout = VerticalDateTimeLayout::Stacked
                    }
                    _ => self.invalid_enum("bar.dateTime.verticalLayout", &value, &["stacked"]),
                }
            }
        }

        if let Some(vicinae) = self.optional_table(table, "vicinae", "bar.vicinae") {
            self.warn_unknown_fields(vicinae, &["show", "position"], "bar.vicinae");
            self.assign_bool(
                vicinae,
                "show",
                "bar.vicinae.show",
                &mut config.bar.vicinae.show,
            );
            if let Some(value) = self.string(vicinae, "position", "bar.vicinae.position") {
                match value.value.as_str() {
                    "absoluteEnd" => config.bar.vicinae.position = VicinaePosition::AbsoluteEnd,
                    _ => self.invalid_enum("bar.vicinae.position", &value, &["absoluteEnd"]),
                }
            }
        }
    }

    fn parse_control_center(&mut self, table: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            table,
            &[
                "enabled",
                "edge",
                "width",
                "defaultPage",
                "restoreLastPageForMs",
                "quickControls",
                "sliders",
                "tabs",
                "edgeDrag",
                "scrim",
            ],
            "controlCenter",
        );
        self.assign_bool(
            table,
            "enabled",
            "controlCenter.enabled",
            &mut config.control_center.enabled,
        );
        if let Some(value) = self.string(table, "edge", "controlCenter.edge") {
            match value.value.as_str() {
                "right" => config.control_center.edge = ControlCenterEdge::Right,
                _ => self.invalid_enum("controlCenter.edge", &value, &["right"]),
            }
        }
        if let Some(value) = table.get("width") {
            self.remember("controlCenter.width", value.span());
            if let Some(auto_or_pixels) = self.auto_or_positive_pixels(value, "controlCenter.width")
            {
                config.control_center.width = auto_or_pixels;
            }
        }
        self.assign_nonempty_string(
            table,
            "defaultPage",
            "controlCenter.defaultPage",
            &mut config.control_center.default_page,
        );
        self.assign_u32(
            table,
            "restoreLastPageForMs",
            "controlCenter.restoreLastPageForMs",
            &mut config.control_center.restore_last_page_for_ms,
        );
        self.assign_string_array(
            table,
            "quickControls",
            "controlCenter.quickControls",
            &mut config.control_center.quick_controls,
        );
        self.assign_string_array(
            table,
            "sliders",
            "controlCenter.sliders",
            &mut config.control_center.sliders,
        );
        self.assign_string_array(
            table,
            "tabs",
            "controlCenter.tabs",
            &mut config.control_center.tabs,
        );

        if let Some(edge_drag) = self.optional_table(table, "edgeDrag", "controlCenter.edgeDrag") {
            self.warn_unknown_fields(
                edge_drag,
                &[
                    "enabled",
                    "activationWidth",
                    "minimumDistance",
                    "openThreshold",
                    "velocityThreshold",
                    "horizontalIntentRatio",
                    "allowInFullscreen",
                ],
                "controlCenter.edgeDrag",
            );
            self.assign_bool(
                edge_drag,
                "enabled",
                "controlCenter.edgeDrag.enabled",
                &mut config.control_center.edge_drag.enabled,
            );
            self.assign_positive_f64(
                edge_drag,
                "activationWidth",
                "controlCenter.edgeDrag.activationWidth",
                &mut config.control_center.edge_drag.activation_width,
            );
            self.assign_positive_f64(
                edge_drag,
                "minimumDistance",
                "controlCenter.edgeDrag.minimumDistance",
                &mut config.control_center.edge_drag.minimum_distance,
            );
            self.assign_bounded_f64(
                edge_drag,
                "openThreshold",
                "controlCenter.edgeDrag.openThreshold",
                0.0,
                1.0,
                &mut config.control_center.edge_drag.open_threshold,
            );
            self.assign_positive_f64(
                edge_drag,
                "velocityThreshold",
                "controlCenter.edgeDrag.velocityThreshold",
                &mut config.control_center.edge_drag.velocity_threshold,
            );
            self.assign_positive_f64(
                edge_drag,
                "horizontalIntentRatio",
                "controlCenter.edgeDrag.horizontalIntentRatio",
                &mut config.control_center.edge_drag.horizontal_intent_ratio,
            );
            self.assign_bool(
                edge_drag,
                "allowInFullscreen",
                "controlCenter.edgeDrag.allowInFullscreen",
                &mut config.control_center.edge_drag.allow_in_fullscreen,
            );
        }

        if let Some(scrim) = self.optional_table(table, "scrim", "controlCenter.scrim") {
            self.warn_unknown_fields(scrim, &["enabled", "dismissOnClick"], "controlCenter.scrim");
            self.assign_bool(
                scrim,
                "enabled",
                "controlCenter.scrim.enabled",
                &mut config.control_center.scrim.enabled,
            );
            self.assign_bool(
                scrim,
                "dismissOnClick",
                "controlCenter.scrim.dismissOnClick",
                &mut config.control_center.scrim.dismiss_on_click,
            );
        }
    }

    fn parse_workspaces(&mut self, table: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            table,
            &["special", "numbered", "overview", "focusedWindowActions"],
            "workspaces",
        );
        if let Some(value) = table.get("special") {
            self.remember("workspaces.special", value.span());
            if let Some(array) = value.get_ref().as_array() {
                let mut special = Vec::with_capacity(array.len());
                for (index, entry) in array.iter().enumerate() {
                    let path = format!("workspaces.special[{index}]");
                    let Some(table) = entry.get_ref().as_table() else {
                        self.type_error(&path, "table", entry);
                        continue;
                    };
                    self.warn_unknown_fields(
                        table,
                        &[
                            "id",
                            "hyprlandName",
                            "label",
                            "icon",
                            "shortcutHint",
                            "defaultApplication",
                        ],
                        &path,
                    );
                    let id = self.required_nonempty_string(table, "id", &format!("{path}.id"));
                    let hyprland_name = self.required_nonempty_string(
                        table,
                        "hyprlandName",
                        &format!("{path}.hyprlandName"),
                    );
                    let label =
                        self.required_nonempty_string(table, "label", &format!("{path}.label"));
                    let icon =
                        self.required_nonempty_string(table, "icon", &format!("{path}.icon"));
                    let shortcut_hint = self.optional_nonempty_string(
                        table,
                        "shortcutHint",
                        &format!("{path}.shortcutHint"),
                    );
                    let default_application = self.optional_nonempty_string(
                        table,
                        "defaultApplication",
                        &format!("{path}.defaultApplication"),
                    );
                    if let (Some(id), Some(hyprland_name), Some(label), Some(icon)) =
                        (id, hyprland_name, label, icon)
                    {
                        special.push(SpecialWorkspace {
                            id,
                            hyprland_name,
                            label,
                            icon,
                            shortcut_hint,
                            default_application,
                        });
                    }
                }
                config.workspaces.special = special;
            } else {
                self.type_error("workspaces.special", "array of tables", value);
            }
        }

        if let Some(numbered) = self.optional_table(table, "numbered", "workspaces.numbered") {
            self.warn_unknown_fields(
                numbered,
                &["minimum", "maximum", "groupSize", "wrap", "semanticLabels"],
                "workspaces.numbered",
            );
            self.assign_positive_u32(
                numbered,
                "minimum",
                "workspaces.numbered.minimum",
                &mut config.workspaces.numbered.minimum,
            );
            self.assign_positive_u32(
                numbered,
                "maximum",
                "workspaces.numbered.maximum",
                &mut config.workspaces.numbered.maximum,
            );
            self.assign_positive_u32(
                numbered,
                "groupSize",
                "workspaces.numbered.groupSize",
                &mut config.workspaces.numbered.group_size,
            );
            self.assign_bool(
                numbered,
                "wrap",
                "workspaces.numbered.wrap",
                &mut config.workspaces.numbered.wrap,
            );
            if let Some(labels) = self.optional_table(
                numbered,
                "semanticLabels",
                "workspaces.numbered.semanticLabels",
            ) {
                let mut normalized = BTreeMap::new();
                for (key, value) in labels {
                    let key_text = key.get_ref().as_ref();
                    let path = format!("workspaces.numbered.semanticLabels.{key_text}");
                    let workspace = match key_text.parse::<u32>() {
                        Ok(workspace) if workspace > 0 => workspace,
                        _ => {
                            self.error(
                                "CONFIG_INVALID_STABLE_ID",
                                "semantic label keys must be positive workspace numbers",
                                Some(&path),
                                Some(key.span()),
                                Some("Use numeric keys such as 1 = \"Browser\"."),
                            );
                            continue;
                        }
                    };
                    self.remember(&path, value.span());
                    if let Some(label) = value.get_ref().as_str() {
                        if label.is_empty() {
                            self.error(
                                "CONFIG_VALUE_REQUIRED",
                                "semantic workspace labels must not be empty",
                                Some(&path),
                                Some(value.span()),
                                None,
                            );
                        } else {
                            normalized.insert(workspace, label.to_owned());
                        }
                    } else {
                        self.type_error(&path, "string", value);
                    }
                }
                config.workspaces.numbered.semantic_labels = normalized;
            }
        }

        if let Some(overview) = self.optional_table(table, "overview", "workspaces.overview") {
            self.warn_unknown_fields(
                overview,
                &[
                    "provider",
                    "openOnActiveWorkspaceClick",
                    "rows",
                    "columns",
                    "showSpecialWorkspaces",
                    "hideEmptyRows",
                ],
                "workspaces.overview",
            );
            if let Some(value) = self.string(overview, "provider", "workspaces.overview.provider") {
                match value.value.as_str() {
                    "quickshell-overview" => {
                        config.workspaces.overview.provider = OverviewProvider::QuickshellOverview
                    }
                    _ => self.invalid_enum(
                        "workspaces.overview.provider",
                        &value,
                        &["quickshell-overview"],
                    ),
                }
            }
            self.assign_bool(
                overview,
                "openOnActiveWorkspaceClick",
                "workspaces.overview.openOnActiveWorkspaceClick",
                &mut config.workspaces.overview.open_on_active_workspace_click,
            );
            self.assign_positive_u32(
                overview,
                "rows",
                "workspaces.overview.rows",
                &mut config.workspaces.overview.rows,
            );
            self.assign_positive_u32(
                overview,
                "columns",
                "workspaces.overview.columns",
                &mut config.workspaces.overview.columns,
            );
            self.assign_bool(
                overview,
                "showSpecialWorkspaces",
                "workspaces.overview.showSpecialWorkspaces",
                &mut config.workspaces.overview.show_special_workspaces,
            );
            self.assign_bool(
                overview,
                "hideEmptyRows",
                "workspaces.overview.hideEmptyRows",
                &mut config.workspaces.overview.hide_empty_rows,
            );
        }

        if let Some(actions) = self.optional_table(
            table,
            "focusedWindowActions",
            "workspaces.focusedWindowActions",
        ) {
            self.warn_unknown_fields(
                actions,
                &["enabled", "actions"],
                "workspaces.focusedWindowActions",
            );
            self.assign_bool(
                actions,
                "enabled",
                "workspaces.focusedWindowActions.enabled",
                &mut config.workspaces.focused_window_actions.enabled,
            );
            if let Some(values) = self.string_array(
                actions,
                "actions",
                "workspaces.focusedWindowActions.actions",
            ) {
                let mut normalized = Vec::with_capacity(values.len());
                for value in values {
                    let action = match value.value.as_str() {
                        "moveToWorkspace" => Some(FocusedWindowAction::MoveToWorkspace),
                        "moveToSpecialWorkspace" => {
                            Some(FocusedWindowAction::MoveToSpecialWorkspace)
                        }
                        "toggleFloating" => Some(FocusedWindowAction::ToggleFloating),
                        "toggleFullscreen" => Some(FocusedWindowAction::ToggleFullscreen),
                        "close" => Some(FocusedWindowAction::Close),
                        "kill" => Some(FocusedWindowAction::Kill),
                        _ => {
                            self.invalid_enum(
                                "workspaces.focusedWindowActions.actions",
                                &value,
                                &[
                                    "moveToWorkspace",
                                    "moveToSpecialWorkspace",
                                    "toggleFloating",
                                    "toggleFullscreen",
                                    "close",
                                    "kill",
                                ],
                            );
                            None
                        }
                    };
                    if let Some(action) = action {
                        normalized.push(action);
                    }
                }
                config.workspaces.focused_window_actions.actions = normalized;
            }
        }
    }

    fn parse_integrations(&mut self, table: &DeTable<'_>, config: &mut Configuration) {
        self.warn_unknown_fields(
            table,
            &["caelestia", "vicinae", "overview", "autoCpuFreq"],
            "integrations",
        );
        if let Some(caelestia) = self.optional_table(table, "caelestia", "integrations.caelestia") {
            self.warn_unknown_fields(
                caelestia,
                &["enabled", "dynamicColors", "services"],
                "integrations.caelestia",
            );
            self.assign_bool(
                caelestia,
                "enabled",
                "integrations.caelestia.enabled",
                &mut config.integrations.caelestia.enabled,
            );
            self.assign_bool(
                caelestia,
                "dynamicColors",
                "integrations.caelestia.dynamicColors",
                &mut config.integrations.caelestia.dynamic_colors,
            );
            self.assign_string_array(
                caelestia,
                "services",
                "integrations.caelestia.services",
                &mut config.integrations.caelestia.services,
            );
        }
        if let Some(vicinae) = self.optional_table(table, "vicinae", "integrations.vicinae") {
            self.warn_unknown_fields(
                vicinae,
                &[
                    "enabled",
                    "required",
                    "themeSync",
                    "extensionEnabled",
                    "shortcutMenu",
                ],
                "integrations.vicinae",
            );
            self.assign_bool(
                vicinae,
                "enabled",
                "integrations.vicinae.enabled",
                &mut config.integrations.vicinae.enabled,
            );
            self.assign_bool(
                vicinae,
                "required",
                "integrations.vicinae.required",
                &mut config.integrations.vicinae.required,
            );
            self.assign_bool(
                vicinae,
                "themeSync",
                "integrations.vicinae.themeSync",
                &mut config.integrations.vicinae.theme_sync,
            );
            self.assign_bool(
                vicinae,
                "extensionEnabled",
                "integrations.vicinae.extensionEnabled",
                &mut config.integrations.vicinae.extension_enabled,
            );
            self.assign_string_array(
                vicinae,
                "shortcutMenu",
                "integrations.vicinae.shortcutMenu",
                &mut config.integrations.vicinae.shortcut_menu,
            );
        }
        if let Some(overview) = self.optional_table(table, "overview", "integrations.overview") {
            self.warn_unknown_fields(
                overview,
                &[
                    "enabled",
                    "provider",
                    "required",
                    "instanceName",
                    "themeSync",
                    "configSync",
                ],
                "integrations.overview",
            );
            self.assign_bool(
                overview,
                "enabled",
                "integrations.overview.enabled",
                &mut config.integrations.overview.enabled,
            );
            if let Some(value) = self.string(overview, "provider", "integrations.overview.provider")
            {
                match value.value.as_str() {
                    "quickshell-overview" => {
                        config.integrations.overview.provider = OverviewProvider::QuickshellOverview
                    }
                    _ => self.invalid_enum(
                        "integrations.overview.provider",
                        &value,
                        &["quickshell-overview"],
                    ),
                }
            }
            self.assign_bool(
                overview,
                "required",
                "integrations.overview.required",
                &mut config.integrations.overview.required,
            );
            self.assign_nonempty_string(
                overview,
                "instanceName",
                "integrations.overview.instanceName",
                &mut config.integrations.overview.instance_name,
            );
            self.assign_bool(
                overview,
                "themeSync",
                "integrations.overview.themeSync",
                &mut config.integrations.overview.theme_sync,
            );
            self.assign_bool(
                overview,
                "configSync",
                "integrations.overview.configSync",
                &mut config.integrations.overview.config_sync,
            );
        }
        if let Some(auto_cpu_freq) =
            self.optional_table(table, "autoCpuFreq", "integrations.autoCpuFreq")
        {
            self.warn_unknown_fields(
                auto_cpu_freq,
                &["enabled", "required"],
                "integrations.autoCpuFreq",
            );
            self.assign_bool(
                auto_cpu_freq,
                "enabled",
                "integrations.autoCpuFreq.enabled",
                &mut config.integrations.auto_cpu_freq.enabled,
            );
            self.assign_bool(
                auto_cpu_freq,
                "required",
                "integrations.autoCpuFreq.required",
                &mut config.integrations.auto_cpu_freq.required,
            );
        }
    }

    fn parse_commands(&mut self, table: &DeTable<'_>) -> BTreeMap<String, CommandDefinition> {
        let mut commands = BTreeMap::new();
        for (key, value) in table {
            let command_id = key.get_ref().as_ref();
            let path = format!("commands.{command_id}");
            if command_id.is_empty() {
                self.error(
                    "CONFIG_INVALID_STABLE_ID",
                    "command IDs must not be empty",
                    Some(&path),
                    Some(key.span()),
                    None,
                );
                continue;
            }
            let Some(definition) = value.get_ref().as_table() else {
                self.type_error(&path, "table with executable and arguments", value);
                continue;
            };
            self.warn_unknown_fields(
                definition,
                &[
                    "executable",
                    "arguments",
                    "detached",
                    "timeoutMs",
                    "environment",
                    "workingDirectory",
                ],
                &path,
            );
            if let Some(value) = definition.get("workingDirectory") {
                let field_path = format!("{path}.workingDirectory");
                self.remember(&field_path, value.span());
                self.error(
                    "CONFIG_COMMAND_WORKING_DIRECTORY_UNSUPPORTED",
                    "command workingDirectory is not supported by the Phase 1 command runtime",
                    Some(&field_path),
                    Some(value.span()),
                    Some("Remove workingDirectory from this command definition."),
                );
            }
            let executable = self.required_nonempty_string(
                definition,
                "executable",
                &format!("{path}.executable"),
            );
            let arguments =
                self.required_string_array(definition, "arguments", &format!("{path}.arguments"));
            let mut detached = false;
            self.assign_bool(
                definition,
                "detached",
                &format!("{path}.detached"),
                &mut detached,
            );
            let mut timeout_ms = 5000;
            self.assign_positive_u32(
                definition,
                "timeoutMs",
                &format!("{path}.timeoutMs"),
                &mut timeout_ms,
            );
            let environment =
                self.parse_environment(definition, "environment", &format!("{path}.environment"));

            if let (Some(executable), Some(arguments)) = (executable, arguments) {
                commands.insert(
                    command_id.to_owned(),
                    CommandDefinition {
                        executable,
                        arguments,
                        detached,
                        timeout_ms,
                        environment,
                    },
                );
            }
        }
        commands
    }

    fn parse_environment(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
    ) -> BTreeMap<String, String> {
        let Some(value) = table.get(key) else {
            return BTreeMap::new();
        };
        self.remember(path, value.span());
        let Some(environment) = value.get_ref().as_table() else {
            self.type_error(path, "table of string values", value);
            return BTreeMap::new();
        };
        let mut normalized = BTreeMap::new();
        for (name, value) in environment {
            let name = name.get_ref().as_ref();
            let entry_path = format!("{path}.{name}");
            if name.is_empty() {
                self.error(
                    "CONFIG_INVALID_STABLE_ID",
                    "environment variable names must not be empty",
                    Some(&entry_path),
                    Some(value.span()),
                    None,
                );
                continue;
            }
            if let Some(value) = value.get_ref().as_str() {
                normalized.insert(name.to_owned(), value.to_owned());
            } else {
                self.type_error(&entry_path, "string", value);
            }
        }
        normalized
    }

    fn semantic_validation(&mut self, config: &Configuration) {
        let expected_bar_start = ["workspacePager", "specialWorkspaces"];
        let expected_bar_context = ["contextStatus", "tray"];
        let expected_bar_end = [
            "networkSpeed",
            "audio",
            "resources",
            "battery",
            "dateTime",
            "vicinae",
        ];
        if config.bar.layout.start != expected_bar_start
            || config.bar.layout.context != expected_bar_context
            || config.bar.layout.end != expected_bar_end
        {
            self.error(
                "CONFIG_BAR_LAYOUT_UNSUPPORTED",
                "bar.layout must preserve the documented Phase 1 hierarchy",
                Some("bar.layout"),
                self.location("bar.layout"),
                Some("Use the built-in start, context, and end component order."),
            );
        }

        self.validate_string_options(
            &config.control_center.quick_controls,
            "controlCenter.quickControls",
            &[
                "wifi",
                "bluetooth",
                "doNotDisturb",
                "nightLight",
                "idleInhibitor",
            ],
        );
        self.validate_string_options(
            &config.control_center.sliders,
            "controlCenter.sliders",
            &["volume", "brightness"],
        );
        self.validate_string_options(
            &config.control_center.tabs,
            "controlCenter.tabs",
            &["notifications", "volumeMixer"],
        );

        if config.workspaces.numbered.minimum > config.workspaces.numbered.maximum {
            self.error(
                "CONFIG_WORKSPACE_RANGE_INVALID",
                "workspaces.numbered.minimum must be less than or equal to maximum",
                Some("workspaces.numbered.minimum"),
                self.location("workspaces.numbered.minimum"),
                Some("Lower minimum or raise maximum."),
            );
        }
        if config.bar.workspace_pager.group_size != config.workspaces.numbered.group_size {
            self.error(
                "CONFIG_WORKSPACE_GROUP_MISMATCH",
                "bar.workspacePager.groupSize must match workspaces.numbered.groupSize",
                Some("bar.workspacePager.groupSize"),
                self.location("bar.workspacePager.groupSize"),
                Some("Use one shared group size for the pager and numbered workspace model."),
            );
        }
        if config.workspaces.numbered.group_size
            > config
                .workspaces
                .numbered
                .maximum
                .saturating_sub(config.workspaces.numbered.minimum)
                .saturating_add(1)
        {
            self.error(
                "CONFIG_WORKSPACE_GROUP_INVALID",
                "workspaces.numbered.groupSize cannot exceed the configured workspace range",
                Some("workspaces.numbered.groupSize"),
                self.location("workspaces.numbered.groupSize"),
                Some("Reduce groupSize or expand the numbered workspace range."),
            );
        }
        for workspace in config.workspaces.numbered.semantic_labels.keys() {
            if *workspace < config.workspaces.numbered.minimum
                || *workspace > config.workspaces.numbered.maximum
            {
                let path = format!("workspaces.numbered.semanticLabels.{workspace}");
                self.error(
                    "CONFIG_WORKSPACE_REFERENCE_INVALID",
                    format!(
                        "semantic label workspace {workspace} is outside the configured numbered range"
                    ),
                    Some(&path),
                    self.location(&path),
                    Some("Use a workspace number between minimum and maximum."),
                );
            }
        }

        let mut ids = BTreeSet::new();
        let mut hyprland_names = BTreeSet::new();
        for (index, workspace) in config.workspaces.special.iter().enumerate() {
            if !ids.insert(workspace.id.as_str()) {
                let path = format!("workspaces.special[{index}].id");
                self.error(
                    "CONFIG_DUPLICATE_STABLE_ID",
                    format!("special workspace ID {:?} is duplicated", workspace.id),
                    Some(&path),
                    self.location(&path),
                    Some("Give every special workspace a unique stable id."),
                );
            }
            if !hyprland_names.insert(workspace.hyprland_name.as_str()) {
                let path = format!("workspaces.special[{index}].hyprlandName");
                self.error(
                    "CONFIG_DUPLICATE_HYPRLAND_NAME",
                    format!(
                        "special workspace Hyprland name {:?} is duplicated",
                        workspace.hyprland_name
                    ),
                    Some(&path),
                    self.location(&path),
                    Some("Give every special workspace a unique hyprlandName."),
                );
            }
        }

        if !config
            .control_center
            .tabs
            .contains(&config.control_center.default_page)
        {
            self.error(
                "CONFIG_REFERENCE_NOT_FOUND",
                format!(
                    "controlCenter.defaultPage {:?} is not present in controlCenter.tabs",
                    config.control_center.default_page
                ),
                Some("controlCenter.defaultPage"),
                self.location("controlCenter.defaultPage"),
                Some("Add the default page to controlCenter.tabs or choose an existing tab."),
            );
        }

        for (index, command_id) in config.integrations.vicinae.shortcut_menu.iter().enumerate() {
            if !config.commands.contains_key(command_id) {
                let path = format!("integrations.vicinae.shortcutMenu[{index}]");
                self.error(
                    "CONFIG_COMMAND_REFERENCE_NOT_FOUND",
                    format!("referenced command ID {command_id:?} is not defined"),
                    Some(&path),
                    self.location("integrations.vicinae.shortcutMenu"),
                    Some("Define the command under [commands.\"id\"] or remove the reference."),
                );
            }
        }

        for (command_id, command) in &config.commands {
            if command.detached {
                let path = format!("commands.{command_id}.detached");
                self.error(
                    "CONFIG_COMMAND_DETACHED_UNSUPPORTED",
                    "detached command execution is not supported by the tracked Phase 1 runtime",
                    Some(&path),
                    self.location(&path),
                    Some("Set detached = false or omit the field."),
                );
            }
            if !command.environment.is_empty() {
                let path = format!("commands.{command_id}.environment");
                self.error(
                    "CONFIG_COMMAND_ENVIRONMENT_UNSUPPORTED",
                    "per-command environment overrides are not supported by the Phase 1 runtime",
                    Some(&path),
                    self.location(&path),
                    Some("Remove the command environment table."),
                );
            }
            if contains_disallowed_executable_syntax(&command.executable) {
                let path = format!("commands.{command_id}.executable");
                self.error(
                    "CONFIG_COMMAND_EXECUTABLE_UNSAFE",
                    "command executable must be one program path or name, not shell composition",
                    Some(&path),
                    self.location(&path),
                    Some("Place each argument in arguments = [ ... ] and do not use pipelines or shell operators."),
                );
            }
        }
    }

    fn validate_string_options(&mut self, values: &[String], path: &str, allowed: &[&str]) {
        let mut seen = BTreeSet::new();
        for (index, value) in values.iter().enumerate() {
            let element_path = format!("{path}[{index}]");
            if !allowed.contains(&value.as_str()) {
                self.error(
                    "CONFIG_INVALID_ENUM",
                    format!(
                        "{element_path} has unsupported value {value:?}; allowed values are {}",
                        allowed
                            .iter()
                            .map(|value| format!("{value:?}"))
                            .collect::<Vec<_>>()
                            .join(", ")
                    ),
                    Some(&element_path),
                    self.location(&element_path).or_else(|| self.location(path)),
                    None,
                );
            }
            if !seen.insert(value.as_str()) {
                self.error(
                    "CONFIG_DUPLICATE_ENTRY",
                    format!("{element_path} duplicates {value:?}"),
                    Some(&element_path),
                    self.location(&element_path).or_else(|| self.location(path)),
                    Some("List each supported entry at most once."),
                );
            }
        }
    }

    fn optional_table<'b>(
        &mut self,
        table: &'b DeTable<'_>,
        key: &str,
        path: &str,
    ) -> Option<&'b DeTable<'b>> {
        let value = table.get(key)?;
        self.remember(path, value.span());
        match value.get_ref().as_table() {
            Some(table) => Some(table),
            None => {
                self.type_error(path, "table", value);
                None
            }
        }
    }

    fn string(&mut self, table: &DeTable<'_>, key: &str, path: &str) -> Option<Located<String>> {
        let value = table.get(key)?;
        self.remember(path, value.span());
        match value.get_ref().as_str() {
            Some(string) => Some(Located {
                value: string.to_owned(),
                span: value.span(),
            }),
            None => {
                self.type_error(path, "string", value);
                None
            }
        }
    }

    fn bool(&mut self, table: &DeTable<'_>, key: &str, path: &str) -> Option<Located<bool>> {
        let value = table.get(key)?;
        self.remember(path, value.span());
        match value.get_ref().as_bool() {
            Some(boolean) => Some(Located {
                value: boolean,
                span: value.span(),
            }),
            None => {
                self.type_error(path, "boolean", value);
                None
            }
        }
    }

    fn u32(&mut self, table: &DeTable<'_>, key: &str, path: &str) -> Option<Located<u32>> {
        let value = table.get(key)?;
        self.remember(path, value.span());
        let Some(integer) = value.get_ref().as_integer() else {
            self.type_error(path, "integer", value);
            return None;
        };
        match integer_to_u32(integer) {
            Some(integer) => Some(Located {
                value: integer,
                span: value.span(),
            }),
            None => {
                self.error(
                    "CONFIG_VALUE_OUT_OF_RANGE",
                    format!("{path} must be a non-negative 32-bit integer"),
                    Some(path),
                    Some(value.span()),
                    None,
                );
                None
            }
        }
    }

    fn f64(&mut self, table: &DeTable<'_>, key: &str, path: &str) -> Option<Located<f64>> {
        let value = table.get(key)?;
        self.remember(path, value.span());
        let parsed = match value.get_ref() {
            DeValue::Integer(integer) => integer_to_i64(integer).map(|value| value as f64),
            DeValue::Float(float) => float.as_str().parse::<f64>().ok(),
            _ => None,
        };
        match parsed.filter(|value| value.is_finite()) {
            Some(number) => Some(Located {
                value: number,
                span: value.span(),
            }),
            None => {
                self.type_error(path, "finite number", value);
                None
            }
        }
    }

    fn string_array(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
    ) -> Option<Vec<Located<String>>> {
        let value = table.get(key)?;
        self.remember(path, value.span());
        let Some(array) = value.get_ref().as_array() else {
            self.type_error(path, "array of strings", value);
            return None;
        };
        let mut strings = Vec::with_capacity(array.len());
        for (index, value) in array.iter().enumerate() {
            let element_path = format!("{path}[{index}]");
            self.remember(&element_path, value.span());
            match value.get_ref().as_str() {
                Some(string) if !string.is_empty() => strings.push(Located {
                    value: string.to_owned(),
                    span: value.span(),
                }),
                Some(_) => self.error(
                    "CONFIG_VALUE_REQUIRED",
                    "array entries must not be empty",
                    Some(&element_path),
                    Some(value.span()),
                    None,
                ),
                None => self.type_error(&element_path, "string", value),
            }
        }
        Some(strings)
    }

    fn required_string_array(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
    ) -> Option<Vec<String>> {
        if table.get(key).is_none() {
            self.required_field_missing(path, "array of strings");
            return None;
        }
        self.string_array(table, key, path)
            .map(|values| values.into_iter().map(|value| value.value).collect())
    }

    fn required_nonempty_string(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
    ) -> Option<String> {
        if table.get(key).is_none() {
            self.required_field_missing(path, "non-empty string");
            return None;
        }
        self.optional_nonempty_string(table, key, path)
    }

    fn optional_nonempty_string(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
    ) -> Option<String> {
        self.string(table, key, path).and_then(|value| {
            if value.value.is_empty() {
                self.error(
                    "CONFIG_VALUE_REQUIRED",
                    format!("{path} must not be empty"),
                    Some(path),
                    Some(value.span),
                    None,
                );
                None
            } else {
                Some(value.value)
            }
        })
    }

    fn auto_or_positive_pixels(
        &mut self,
        value: &Spanned<DeValue<'_>>,
        path: &str,
    ) -> Option<AutoOrPixels> {
        if let Some(string) = value.get_ref().as_str() {
            if string == "auto" {
                return Some(AutoOrPixels::Auto(crate::schema::AutoValue::Auto));
            }
            self.error(
                "CONFIG_INVALID_ENUM",
                format!("{path} must be \"auto\" or a positive logical-pixel number"),
                Some(path),
                Some(value.span()),
                Some("Use \"auto\" or a number greater than zero."),
            );
            return None;
        }
        let number = match value.get_ref() {
            DeValue::Integer(integer) => integer_to_i64(integer).map(|value| value as f64),
            DeValue::Float(float) => float.as_str().parse::<f64>().ok(),
            _ => None,
        };
        match number.filter(|number| number.is_finite() && *number > 0.0) {
            Some(number) => Some(AutoOrPixels::Pixels(number)),
            None => {
                self.error(
                    "CONFIG_VALUE_OUT_OF_RANGE",
                    format!("{path} must be \"auto\" or a positive logical-pixel number"),
                    Some(path),
                    Some(value.span()),
                    Some("Use \"auto\" or a number greater than zero."),
                );
                None
            }
        }
    }

    fn assign_bool(&mut self, table: &DeTable<'_>, key: &str, path: &str, target: &mut bool) {
        if let Some(value) = self.bool(table, key, path) {
            *target = value.value;
        }
    }

    fn assign_u32(&mut self, table: &DeTable<'_>, key: &str, path: &str, target: &mut u32) {
        if let Some(value) = self.u32(table, key, path) {
            *target = value.value;
        }
    }

    fn assign_positive_u32(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
        target: &mut u32,
    ) {
        if let Some(value) = self.u32(table, key, path) {
            if value.value == 0 {
                self.error(
                    "CONFIG_VALUE_OUT_OF_RANGE",
                    format!("{path} must be greater than zero"),
                    Some(path),
                    Some(value.span),
                    None,
                );
            } else {
                *target = value.value;
            }
        }
    }

    fn assign_bounded_u32(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
        minimum: u32,
        maximum: u32,
        target: &mut u32,
    ) {
        if let Some(value) = self.u32(table, key, path) {
            if (minimum..=maximum).contains(&value.value) {
                *target = value.value;
            } else {
                self.error(
                    "CONFIG_VALUE_OUT_OF_RANGE",
                    format!("{path} must be between {minimum} and {maximum}"),
                    Some(path),
                    Some(value.span),
                    None,
                );
            }
        }
    }

    fn assign_positive_f64(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
        target: &mut f64,
    ) {
        if let Some(value) = self.f64(table, key, path) {
            if value.value > 0.0 {
                *target = value.value;
            } else {
                self.error(
                    "CONFIG_VALUE_OUT_OF_RANGE",
                    format!("{path} must be greater than zero"),
                    Some(path),
                    Some(value.span),
                    None,
                );
            }
        }
    }

    fn assign_bounded_f64(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
        minimum: f64,
        maximum: f64,
        target: &mut f64,
    ) {
        if let Some(value) = self.f64(table, key, path) {
            if (minimum..=maximum).contains(&value.value) {
                *target = value.value;
            } else {
                self.error(
                    "CONFIG_VALUE_OUT_OF_RANGE",
                    format!("{path} must be between {minimum} and {maximum}"),
                    Some(path),
                    Some(value.span),
                    None,
                );
            }
        }
    }

    fn assign_nonempty_string(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
        target: &mut String,
    ) {
        if let Some(value) = self.optional_nonempty_string(table, key, path) {
            *target = value;
        }
    }

    fn assign_string_array(
        &mut self,
        table: &DeTable<'_>,
        key: &str,
        path: &str,
        target: &mut Vec<String>,
    ) {
        if let Some(values) = self.string_array(table, key, path) {
            *target = values.into_iter().map(|value| value.value).collect();
        }
    }

    fn warn_unknown_fields(&mut self, table: &DeTable<'_>, allowed: &[&str], parent: &str) {
        for (key, _) in table {
            let key_text = key.get_ref().as_ref();
            if allowed.contains(&key_text) {
                continue;
            }
            let path = if parent.is_empty() {
                key_text.to_owned()
            } else {
                format!("{parent}.{key_text}")
            };
            self.warning(
                "CONFIG_UNKNOWN_FIELD",
                format!("unknown or unsupported field {path:?} was ignored"),
                Some(&path),
                Some(key.span()),
                Some("Remove the field if it is a typo; otherwise it remains untouched in the source."),
            );
        }
    }

    fn type_error(&mut self, path: &str, expected: &str, value: &Spanned<DeValue<'_>>) {
        self.error(
            "CONFIG_WRONG_TYPE",
            format!(
                "{path} must be {expected}, not {}",
                value.get_ref().type_str()
            ),
            Some(path),
            Some(value.span()),
            None,
        );
    }

    fn invalid_enum(&mut self, path: &str, value: &Located<String>, allowed: &[&str]) {
        self.error(
            "CONFIG_INVALID_ENUM",
            format!(
                "{path} has unsupported value {:?}; allowed values are {}",
                value.value,
                allowed
                    .iter()
                    .map(|value| format!("{value:?}"))
                    .collect::<Vec<_>>()
                    .join(", ")
            ),
            Some(path),
            Some(value.span.clone()),
            None,
        );
    }

    fn required_field_missing(&mut self, path: &str, expected: &str) {
        self.error(
            "CONFIG_REQUIRED_FIELD_MISSING",
            format!("required field {path} is missing; expected {expected}"),
            Some(path),
            None,
            None,
        );
    }

    fn remember(&mut self, path: &str, span: Range<usize>) {
        self.locations.insert(path.to_owned(), span);
    }

    fn location(&self, path: &str) -> Option<Range<usize>> {
        self.locations.get(path).cloned()
    }

    fn error(
        &mut self,
        code: impl Into<String>,
        message: impl Into<String>,
        path: Option<&str>,
        span: Option<Range<usize>>,
        hint: Option<&str>,
    ) {
        self.errors.push(Diagnostic::from_span(
            Severity::Error,
            code,
            message,
            path,
            SourceSpan {
                identifier: self.source_id,
                text: self.source_text,
                span,
            },
            hint,
        ));
    }

    fn warning(
        &mut self,
        code: impl Into<String>,
        message: impl Into<String>,
        path: Option<&str>,
        span: Option<Range<usize>>,
        hint: Option<&str>,
    ) {
        self.warnings.push(Diagnostic::from_span(
            Severity::Warning,
            code,
            message,
            path,
            SourceSpan {
                identifier: self.source_id,
                text: self.source_text,
                span,
            },
            hint,
        ));
    }
}

fn integer_to_u32(integer: &DeInteger<'_>) -> Option<u32> {
    integer_to_i128(integer).and_then(|value| u32::try_from(value).ok())
}

fn integer_to_i64(integer: &DeInteger<'_>) -> Option<i64> {
    integer_to_i128(integer).and_then(|value| i64::try_from(value).ok())
}

fn integer_to_i128(integer: &DeInteger<'_>) -> Option<i128> {
    let raw = integer.as_str();
    let (negative, digits) = raw
        .strip_prefix('-')
        .map_or((false, raw), |digits| (true, digits));
    let digits = digits.strip_prefix('+').unwrap_or(digits);
    let magnitude = i128::from_str_radix(digits, integer.radix()).ok()?;
    Some(if negative { -magnitude } else { magnitude })
}

fn contains_disallowed_executable_syntax(executable: &str) -> bool {
    executable.contains(['\n', '\r', '|', '&', ';', '<', '>', '`'])
        || executable.contains("$(")
        || executable.contains("${")
        || executable.chars().any(char::is_whitespace)
}

#[cfg(test)]
mod tests {
    use super::{contains_disallowed_executable_syntax, integer_to_i128};
    use toml::de::DeValue;

    #[test]
    fn parses_toml_integer_representations() {
        for (source, expected) in [("12", 12), ("-5", -5), ("0x10", 16)] {
            let value = DeValue::parse(source).expect("integer should parse");
            let integer = value.get_ref().as_integer().expect("integer");
            assert_eq!(integer_to_i128(integer), Some(expected));
        }
    }

    #[test]
    fn detects_shell_composition_without_rejecting_arguments() {
        assert!(contains_disallowed_executable_syntax(
            "sh -c 'echo x | cat'"
        ));
        assert!(contains_disallowed_executable_syntax("program;other"));
        assert!(!contains_disallowed_executable_syntax("/usr/bin/program"));
    }
}
