use std::collections::BTreeMap;

use serde::Serialize;

pub const CURRENT_SCHEMA_VERSION: u32 = 1;

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Configuration {
    pub schema_version: u32,
    pub shell: ShellConfig,
    pub appearance: AppearanceConfig,
    pub bar: BarConfig,
    pub control_center: ControlCenterConfig,
    pub workspaces: WorkspacesConfig,
    pub integrations: IntegrationsConfig,
    pub commands: BTreeMap<String, CommandDefinition>,
}

impl Default for Configuration {
    fn default() -> Self {
        Self {
            schema_version: CURRENT_SCHEMA_VERSION,
            shell: ShellConfig::default(),
            appearance: AppearanceConfig::default(),
            bar: BarConfig::default(),
            control_center: ControlCenterConfig::default(),
            workspaces: WorkspacesConfig::default(),
            integrations: IntegrationsConfig::default(),
            commands: BTreeMap::new(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ShellConfig {
    pub language: String,
    pub time_format: TimeFormat,
    pub first_day_of_week: FirstDayOfWeek,
    pub startup: StartupConfig,
    pub reload: ReloadConfig,
}

impl Default for ShellConfig {
    fn default() -> Self {
        Self {
            language: "system".to_owned(),
            time_format: TimeFormat::TwentyFourHour,
            first_day_of_week: FirstDayOfWeek::System,
            startup: StartupConfig::default(),
            reload: ReloadConfig::default(),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub enum TimeFormat {
    #[serde(rename = "24h")]
    TwentyFourHour,
    #[serde(rename = "12h")]
    TwelveHour,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum FirstDayOfWeek {
    System,
    Monday,
    Sunday,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StartupConfig {
    pub show_readiness_toast: bool,
    pub restore_session_state: bool,
}

impl Default for StartupConfig {
    fn default() -> Self {
        Self {
            show_readiness_toast: false,
            restore_session_state: true,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ReloadConfig {
    pub watch_config: bool,
    pub debounce_ms: u32,
}

impl Default for ReloadConfig {
    fn default() -> Self {
        Self {
            watch_config: true,
            debounce_ms: 300,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppearanceConfig {
    pub mode: AppearanceMode,
    pub fallback_mode: FallbackMode,
    pub icon_theme: String,
    pub reduced_motion: bool,
    pub high_contrast: bool,
    pub dynamic_colors: DynamicColorsConfig,
    pub surface_opacity: SurfaceOpacityConfig,
    pub blur: BlurConfig,
    pub font: FontConfig,
}

impl Default for AppearanceConfig {
    fn default() -> Self {
        Self {
            mode: AppearanceMode::Dynamic,
            fallback_mode: FallbackMode::Dark,
            icon_theme: "system".to_owned(),
            reduced_motion: false,
            high_contrast: false,
            dynamic_colors: DynamicColorsConfig::default(),
            surface_opacity: SurfaceOpacityConfig::default(),
            blur: BlurConfig::default(),
            font: FontConfig::default(),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum AppearanceMode {
    Dynamic,
    Dark,
    Light,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum FallbackMode {
    Dark,
    Light,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DynamicColorsConfig {
    pub enabled: bool,
    pub source: DynamicColorSource,
    pub transition: bool,
}

impl Default for DynamicColorsConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            source: DynamicColorSource::Caelestia,
            transition: true,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DynamicColorSource {
    Caelestia,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SurfaceOpacityConfig {
    pub bar: f64,
    pub control_center: f64,
    pub popover: f64,
    pub notification: f64,
}

impl Default for SurfaceOpacityConfig {
    fn default() -> Self {
        Self {
            bar: 0.96,
            control_center: 0.98,
            popover: 0.98,
            notification: 0.98,
        }
    }
}

#[derive(Clone, Debug, Default, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BlurConfig {
    pub enabled: bool,
    pub popovers: bool,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FontConfig {
    pub family: String,
    pub scale: f64,
}

impl Default for FontConfig {
    fn default() -> Self {
        Self {
            family: "system".to_owned(),
            scale: 1.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BarConfig {
    pub enabled: bool,
    pub edge: Edge,
    pub thickness: AutoOrPixels,
    pub visible_on: String,
    pub hide_in_fullscreen: bool,
    pub autohide: BarAutohideConfig,
    pub layout: BarLayoutConfig,
    pub workspace_pager: WorkspacePagerConfig,
    pub context_region: ContextRegionConfig,
    pub network_speed: NetworkSpeedConfig,
    pub battery: BarBatteryConfig,
    pub date_time: DateTimeConfig,
    pub vicinae: BarVicinaeConfig,
}

impl Default for BarConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            edge: Edge::Left,
            thickness: AutoOrPixels::Auto(AutoValue::Auto),
            visible_on: "configuredMonitors".to_owned(),
            hide_in_fullscreen: true,
            autohide: BarAutohideConfig::default(),
            layout: BarLayoutConfig::default(),
            workspace_pager: WorkspacePagerConfig::default(),
            context_region: ContextRegionConfig::default(),
            network_speed: NetworkSpeedConfig::default(),
            battery: BarBatteryConfig::default(),
            date_time: DateTimeConfig::default(),
            vicinae: BarVicinaeConfig::default(),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum Edge {
    Left,
    Right,
    Top,
    Bottom,
}

#[derive(Clone, Copy, Debug, PartialEq, Serialize)]
#[serde(untagged)]
pub enum AutoOrPixels {
    Auto(AutoValue),
    Pixels(f64),
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub enum AutoValue {
    #[serde(rename = "auto")]
    Auto,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BarAutohideConfig {
    pub enabled: bool,
    pub reveal_delay_ms: u32,
    pub hide_delay_ms: u32,
    pub activation_width: f64,
    pub reveal_over_fullscreen: bool,
}

impl Default for BarAutohideConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            reveal_delay_ms: 0,
            hide_delay_ms: 350,
            activation_width: 2.0,
            reveal_over_fullscreen: false,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BarLayoutConfig {
    pub start: Vec<String>,
    pub context: Vec<String>,
    pub end: Vec<String>,
}

impl Default for BarLayoutConfig {
    fn default() -> Self {
        Self {
            start: vec!["workspacePager".to_owned(), "specialWorkspaces".to_owned()],
            context: vec!["contextStatus".to_owned(), "tray".to_owned()],
            end: vec![
                "networkSpeed".to_owned(),
                "audio".to_owned(),
                "resources".to_owned(),
                "battery".to_owned(),
                "dateTime".to_owned(),
                "vicinae".to_owned(),
            ],
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspacePagerConfig {
    pub group_size: u32,
    pub show_occupancy: bool,
    pub show_application_icons: bool,
    pub scroll_enabled: bool,
    pub scroll_direction: ScrollDirection,
}

impl Default for WorkspacePagerConfig {
    fn default() -> Self {
        Self {
            group_size: 5,
            show_occupancy: false,
            show_application_icons: false,
            scroll_enabled: true,
            scroll_direction: ScrollDirection::Natural,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ScrollDirection {
    Natural,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ContextRegionConfig {
    pub slots: u32,
    pub overflow: ContextOverflow,
    pub priority: Vec<ContextPriority>,
}

impl Default for ContextRegionConfig {
    fn default() -> Self {
        Self {
            slots: 3,
            overflow: ContextOverflow::Stack,
            priority: vec![
                ContextPriority::Critical,
                ContextPriority::Privacy,
                ContextPriority::Recording,
                ContextPriority::Connectivity,
                ContextPriority::Devices,
                ContextPriority::Activity,
            ],
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ContextOverflow {
    Stack,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ContextPriority {
    Critical,
    Privacy,
    Recording,
    Connectivity,
    Devices,
    Activity,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct NetworkSpeedConfig {
    pub enabled: bool,
    pub show: NetworkSpeedShow,
    pub unit: NetworkSpeedUnit,
    pub base: u32,
    pub decimals: u32,
    pub update_interval_ms: u32,
    pub smoothing_window: u32,
    pub zero_format: String,
}

impl Default for NetworkSpeedConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            show: NetworkSpeedShow::Download,
            unit: NetworkSpeedUnit::Bytes,
            base: 1000,
            decimals: 0,
            update_interval_ms: 1000,
            smoothing_window: 3,
            zero_format: "0K".to_owned(),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum NetworkSpeedShow {
    Download,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum NetworkSpeedUnit {
    Bytes,
    Bits,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BarBatteryConfig {
    pub show_percent_sign: bool,
    pub charging_animation: bool,
}

impl Default for BarBatteryConfig {
    fn default() -> Self {
        Self {
            show_percent_sign: false,
            charging_animation: true,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DateTimeConfig {
    pub show_date: bool,
    pub month_format: MonthFormat,
    pub vertical_layout: VerticalDateTimeLayout,
}

impl Default for DateTimeConfig {
    fn default() -> Self {
        Self {
            show_date: true,
            month_format: MonthFormat::ShortText,
            vertical_layout: VerticalDateTimeLayout::Stacked,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MonthFormat {
    ShortText,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum VerticalDateTimeLayout {
    Stacked,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BarVicinaeConfig {
    pub show: bool,
    pub position: VicinaePosition,
}

impl Default for BarVicinaeConfig {
    fn default() -> Self {
        Self {
            show: true,
            position: VicinaePosition::AbsoluteEnd,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum VicinaePosition {
    AbsoluteEnd,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ControlCenterConfig {
    pub enabled: bool,
    pub edge: ControlCenterEdge,
    pub width: AutoOrPixels,
    pub default_page: String,
    pub restore_last_page_for_ms: u32,
    pub quick_controls: Vec<String>,
    pub sliders: Vec<String>,
    pub tabs: Vec<String>,
    pub edge_drag: EdgeDragConfig,
    pub scrim: ScrimConfig,
}

impl Default for ControlCenterConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            edge: ControlCenterEdge::Right,
            width: AutoOrPixels::Auto(AutoValue::Auto),
            default_page: "notifications".to_owned(),
            restore_last_page_for_ms: 15_000,
            quick_controls: vec![
                "wifi".to_owned(),
                "bluetooth".to_owned(),
                "doNotDisturb".to_owned(),
                "nightLight".to_owned(),
                "idleInhibitor".to_owned(),
            ],
            sliders: vec!["volume".to_owned(), "brightness".to_owned()],
            tabs: vec!["notifications".to_owned(), "volumeMixer".to_owned()],
            edge_drag: EdgeDragConfig::default(),
            scrim: ScrimConfig::default(),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ControlCenterEdge {
    Right,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EdgeDragConfig {
    pub enabled: bool,
    pub activation_width: f64,
    pub minimum_distance: f64,
    pub open_threshold: f64,
    pub velocity_threshold: f64,
    pub horizontal_intent_ratio: f64,
    pub allow_in_fullscreen: bool,
}

impl Default for EdgeDragConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            activation_width: 2.0,
            minimum_distance: 24.0,
            open_threshold: 0.35,
            velocity_threshold: 900.0,
            horizontal_intent_ratio: 1.5,
            allow_in_fullscreen: false,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ScrimConfig {
    pub enabled: bool,
    pub dismiss_on_click: bool,
}

impl Default for ScrimConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            dismiss_on_click: true,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspacesConfig {
    pub special: Vec<SpecialWorkspace>,
    pub numbered: NumberedWorkspacesConfig,
    pub overview: WorkspaceOverviewConfig,
    pub focused_window_actions: FocusedWindowActionsConfig,
}

impl Default for WorkspacesConfig {
    fn default() -> Self {
        Self {
            special: vec![
                SpecialWorkspace::new(
                    "music",
                    "music",
                    "Music",
                    "music",
                    Some("Super+M"),
                    Some("cider"),
                ),
                SpecialWorkspace::new(
                    "movies",
                    "movies",
                    "Movies",
                    "movie",
                    Some("Super+A"),
                    Some("stremio"),
                ),
                SpecialWorkspace::new(
                    "books",
                    "books",
                    "Books",
                    "book",
                    Some("Super+B"),
                    Some("readest"),
                ),
                SpecialWorkspace::new(
                    "discord",
                    "discord",
                    "Discord",
                    "discord",
                    Some("Super+D"),
                    Some("discord"),
                ),
                SpecialWorkspace::new(
                    "scratchpad",
                    "scratchpad",
                    "Scratchpad",
                    "terminal",
                    Some("Super+S"),
                    None,
                ),
                SpecialWorkspace::new(
                    "todo",
                    "todo",
                    "Todo",
                    "checklist",
                    Some("Super+T"),
                    Some("planify"),
                ),
            ],
            numbered: NumberedWorkspacesConfig::default(),
            overview: WorkspaceOverviewConfig::default(),
            focused_window_actions: FocusedWindowActionsConfig::default(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SpecialWorkspace {
    pub id: String,
    pub hyprland_name: String,
    pub label: String,
    pub icon: String,
    pub shortcut_hint: Option<String>,
    pub default_application: Option<String>,
}

impl SpecialWorkspace {
    fn new(
        id: &str,
        hyprland_name: &str,
        label: &str,
        icon: &str,
        shortcut_hint: Option<&str>,
        default_application: Option<&str>,
    ) -> Self {
        Self {
            id: id.to_owned(),
            hyprland_name: hyprland_name.to_owned(),
            label: label.to_owned(),
            icon: icon.to_owned(),
            shortcut_hint: shortcut_hint.map(str::to_owned),
            default_application: default_application.map(str::to_owned),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct NumberedWorkspacesConfig {
    pub minimum: u32,
    pub maximum: u32,
    pub group_size: u32,
    pub wrap: bool,
    pub semantic_labels: BTreeMap<u32, String>,
}

impl Default for NumberedWorkspacesConfig {
    fn default() -> Self {
        Self {
            minimum: 1,
            maximum: 10,
            group_size: 5,
            wrap: false,
            semantic_labels: BTreeMap::new(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceOverviewConfig {
    pub provider: OverviewProvider,
    pub open_on_active_workspace_click: bool,
    pub rows: u32,
    pub columns: u32,
    pub show_special_workspaces: bool,
    pub hide_empty_rows: bool,
}

impl Default for WorkspaceOverviewConfig {
    fn default() -> Self {
        Self {
            provider: OverviewProvider::QuickshellOverview,
            open_on_active_workspace_click: true,
            rows: 2,
            columns: 5,
            show_special_workspaces: true,
            hide_empty_rows: false,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub enum OverviewProvider {
    #[serde(rename = "quickshell-overview")]
    QuickshellOverview,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FocusedWindowActionsConfig {
    pub enabled: bool,
    pub actions: Vec<FocusedWindowAction>,
}

impl Default for FocusedWindowActionsConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            actions: vec![
                FocusedWindowAction::MoveToWorkspace,
                FocusedWindowAction::MoveToSpecialWorkspace,
                FocusedWindowAction::ToggleFloating,
                FocusedWindowAction::ToggleFullscreen,
                FocusedWindowAction::Close,
                FocusedWindowAction::Kill,
            ],
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum FocusedWindowAction {
    MoveToWorkspace,
    MoveToSpecialWorkspace,
    ToggleFloating,
    ToggleFullscreen,
    Close,
    Kill,
}

#[derive(Clone, Debug, Default, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct IntegrationsConfig {
    pub caelestia: CaelestiaIntegration,
    pub vicinae: VicinaeIntegration,
    pub overview: OverviewIntegration,
    pub auto_cpu_freq: OptionalIntegration,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CaelestiaIntegration {
    pub enabled: bool,
    pub dynamic_colors: bool,
    pub services: Vec<String>,
}

impl Default for CaelestiaIntegration {
    fn default() -> Self {
        Self {
            enabled: true,
            dynamic_colors: true,
            services: Vec::new(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct VicinaeIntegration {
    pub enabled: bool,
    pub required: bool,
    pub theme_sync: bool,
    pub extension_enabled: bool,
    pub shortcut_menu: Vec<String>,
}

impl Default for VicinaeIntegration {
    fn default() -> Self {
        Self {
            enabled: true,
            required: false,
            theme_sync: true,
            extension_enabled: true,
            shortcut_menu: Vec::new(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OverviewIntegration {
    pub enabled: bool,
    pub provider: OverviewProvider,
    pub required: bool,
    pub instance_name: String,
    pub theme_sync: bool,
    pub config_sync: bool,
}

impl Default for OverviewIntegration {
    fn default() -> Self {
        Self {
            enabled: true,
            provider: OverviewProvider::QuickshellOverview,
            required: false,
            instance_name: "overview".to_owned(),
            theme_sync: true,
            config_sync: true,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OptionalIntegration {
    pub enabled: bool,
    pub required: bool,
}

impl Default for OptionalIntegration {
    fn default() -> Self {
        Self {
            enabled: true,
            required: false,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CommandDefinition {
    pub executable: String,
    pub arguments: Vec<String>,
    pub detached: bool,
    pub timeout_ms: u32,
    pub environment: BTreeMap<String, String>,
}
