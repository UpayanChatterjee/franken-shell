import "ThemeDefaults.js" as ThemeDefaults
import QtQuick
import Quickshell

Scope {
    id: root

    readonly property ThemeSnapshot active: themeSnapshot
    readonly property string activeId: themeSnapshot.themeId
    readonly property string activeMode: themeSnapshot.mode
    readonly property string activeSource: state.activeSource
    required property var configService
    readonly property string health: state.health
    readonly property string lastError: state.lastError
    readonly property int revision: state.revision

    signal activated(string themeId, int revision)
    signal candidateRejected(string source, string errorCode)

    function applyCandidate(candidate, source: string): var {
        const normalized = controller.normalize(candidate, source);
        if (!normalized.accepted) {
            state.health = "degraded";
            state.lastError = normalized.errorCode;
            root.candidateRejected(controller.safeSource(source), normalized.errorCode);
            return controller.result(false, false, normalized.errorCode);
        }

        const serialized = JSON.stringify(normalized.theme);
        const changed = serialized !== state.serialized || source !== state.activeSource;
        if (changed) {
            state.activeData = controller.deepFreeze(normalized.theme);
            state.activeSource = source;
            state.serialized = serialized;
            state.revision += 1;
            root.activated(state.activeData.id, state.revision);
        }
        state.health = "healthy";
        state.lastError = "";
        return controller.result(true, changed, "");
    }
    function candidateFromConfig(): var {
        const appearance = root.configService.active.appearance;
        let mode = appearance.mode;
        if (mode === "dynamic")
            mode = appearance.fallbackMode;
        return ThemeDefaults.create({
            "mode": mode,
            "highContrast": appearance.highContrast,
            "reducedMotion": appearance.reducedMotion,
            "fontFamily": appearance.font.family === "system" ? "Sans Serif" : appearance.font.family,
            "fontScale": appearance.font.scale,
            "barOpacity": appearance.surfaceOpacity.bar,
            "controlCenterOpacity": appearance.surfaceOpacity.controlCenter,
            "popoverOpacity": appearance.surfaceOpacity.popover,
            "notificationOpacity": appearance.surfaceOpacity.notification
        });
    }
    function summary(): var {
        return Object.freeze({
            "activeId": root.activeId,
            "activeMode": root.activeMode,
            "activeSource": root.activeSource,
            "highContrast": root.active.highContrast,
            "reducedMotion": root.active.reducedMotion,
            "health": root.health,
            "lastError": root.lastError,
            "revision": root.revision
        });
    }

    Component.onCompleted: controller.scheduleConfigSync()

    Connections {
        function onActivated() {
            controller.scheduleConfigSync();
        }

        target: root.configService
    }
    ThemeSnapshot {
        id: themeSnapshot

        _source: state.activeData
    }
    Timer {
        id: configSyncTimer

        interval: 0

        onTriggered: {
            if (root.configService.active !== null)
                root.applyCandidate(root.candidateFromConfig(), "builtInFallback");
        }
    }
    QtObject {
        id: state

        property var activeData: controller.deepFreeze(ThemeDefaults.create({
            "mode": "dark",
            "highContrast": false,
            "reducedMotion": false,
            "fontFamily": "Sans Serif",
            "fontScale": 1.0
        }))
        property string activeSource: "builtInFallback"
        property string health: "healthy"
        property string lastError: ""
        property int revision: 0
        property string serialized: JSON.stringify(state.activeData)
    }
    QtObject {
        id: controller

        readonly property var colorKeys: Object.freeze(["surfaceBase", "surfaceRaised", "surfaceOverlay", "surfacePopup", "surfaceScrim", "textPrimary", "textSecondary", "textDisabled", "textOnAccent", "accentPrimary", "accentContainer", "accentOnContainer", "outlineSubtle", "outlineStrong", "outlineFocus", "success", "warning", "critical", "privacy"])
        readonly property var easingKeys: Object.freeze(["InOutCubic", "OutBack", "OutCubic", "InCubic"])
        readonly property var metricKeys: Object.freeze(["barThickness", "barItemExtent", "controlCenterWidth", "popoverMaxWidth", "notificationWidth", "iconSmall", "iconMedium", "iconLarge", "focusRingWidth", "outlineWidth"])
        readonly property var motionDurationKeys: Object.freeze(["durationInstant", "durationFast", "durationStandard", "durationSlow"])
        readonly property var motionEasingKeys: Object.freeze(["easingStandard", "easingEmphasized", "easingDecelerate", "easingAccelerate"])
        readonly property var opacityKeys: Object.freeze(["bar", "controlCenter", "popover", "notification"])
        readonly property var radiusKeys: Object.freeze(["radiusSmall", "radiusMedium", "radiusLarge", "radiusFull"])
        readonly property var spacingKeys: Object.freeze(["space1", "space2", "space3", "space4", "space5", "space6", "space8"])
        readonly property var typographyNumberKeys: Object.freeze(["fontSizeMetricSmall", "fontSizeMetric", "fontSizeLabel", "fontSizeBody", "fontSizeSection", "fontSizeTitle", "fontWeightRegular", "fontWeightMedium", "fontWeightSemibold"])

        function contrast(left: string, right: string): real {
            const leftLuminance = controller.luminance(left);
            const rightLuminance = controller.luminance(right);
            return (Math.max(leftLuminance, rightLuminance) + 0.05) / (Math.min(leftLuminance, rightLuminance) + 0.05);
        }
        function deepFreeze(value): var {
            if (value === null || typeof value !== "object" || Object.isFrozen(value))
                return value;
            for (const key of Object.keys(value))
                controller.deepFreeze(value[key]);
            return Object.freeze(value);
        }
        function isColor(value, alphaAllowed: bool): bool {
            if (typeof value !== "string")
                return false;
            return alphaAllowed ? /^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/.test(value) : /^#[0-9A-Fa-f]{6}$/.test(value);
        }
        function isNumber(value, minimum: real, maximum: real): bool {
            return typeof value === "number" && Number.isFinite(value) && value >= minimum && value <= maximum;
        }
        function luminance(color: string): real {
            const offset = color.length === 9 ? 3 : 1;
            const red = parseInt(color.slice(offset, offset + 2), 16) / 255;
            const green = parseInt(color.slice(offset + 2, offset + 4), 16) / 255;
            const blue = parseInt(color.slice(offset + 4, offset + 6), 16) / 255;
            const linear = channel => channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue);
        }
        function normalize(candidate, source: string): var {
            if (candidate === null || typeof candidate !== "object" || Array.isArray(candidate))
                return controller.rejection("THEME_CANDIDATE_INVALID");
            if (typeof source !== "string" || !/^[a-z][A-Za-z0-9.-]*$/.test(source))
                return controller.rejection("THEME_SOURCE_INVALID");
            if (typeof candidate.id !== "string" || !/^[a-z][A-Za-z0-9.-]*$/.test(candidate.id) || (candidate.mode !== "dark" && candidate.mode !== "light") || typeof candidate.highContrast !== "boolean" || typeof candidate.reducedMotion !== "boolean")
                return controller.rejection("THEME_METADATA_INVALID");

            const groups = ["colors", "typography", "spacing", "radius", "motion", "opacity", "metrics"];
            for (const group of groups) {
                if (candidate[group] === null || typeof candidate[group] !== "object" || Array.isArray(candidate[group]))
                    return controller.rejection("THEME_GROUP_MISSING");
            }
            for (const key of controller.colorKeys) {
                if (!controller.isColor(candidate.colors[key], key === "surfaceScrim"))
                    return controller.rejection("THEME_COLOR_INVALID");
            }
            if (typeof candidate.typography.fontFamily !== "string" || candidate.typography.fontFamily.length === 0 || candidate.typography.fontFamily.length > 128)
                return controller.rejection("THEME_TYPOGRAPHY_INVALID");
            for (const key of controller.typographyNumberKeys) {
                const weight = key.startsWith("fontWeight");
                if (!controller.isNumber(candidate.typography[key], weight ? 100 : 8, weight ? 900 : 96))
                    return controller.rejection("THEME_TYPOGRAPHY_INVALID");
            }
            for (const key of controller.spacingKeys) {
                if (!controller.isNumber(candidate.spacing[key], 0, 64))
                    return controller.rejection("THEME_SPACING_INVALID");
            }
            for (const key of controller.radiusKeys) {
                if (!controller.isNumber(candidate.radius[key], 0, 999))
                    return controller.rejection("THEME_RADIUS_INVALID");
            }
            for (const key of controller.motionDurationKeys) {
                if (!controller.isNumber(candidate.motion[key], 0, 500))
                    return controller.rejection("THEME_MOTION_INVALID");
            }
            for (const key of controller.motionEasingKeys) {
                if (controller.easingKeys.indexOf(candidate.motion[key]) < 0)
                    return controller.rejection("THEME_MOTION_INVALID");
            }
            if (candidate.reducedMotion && (candidate.motion.durationFast > 80 || candidate.motion.durationStandard > 80 || candidate.motion.durationSlow > 80))
                return controller.rejection("THEME_MOTION_INVALID");
            for (const key of controller.opacityKeys) {
                if (!controller.isNumber(candidate.opacity[key], 0.75, 1.0))
                    return controller.rejection("THEME_OPACITY_INVALID");
            }
            for (const key of controller.metricKeys) {
                if (!controller.isNumber(candidate.metrics[key], 1, 1000))
                    return controller.rejection("THEME_METRICS_INVALID");
            }
            if (!controller.validContrast(candidate.colors, candidate.highContrast))
                return controller.rejection("THEME_CONTRAST_INVALID");

            const theme = {
                "id": candidate.id,
                "mode": candidate.mode,
                "highContrast": candidate.highContrast,
                "reducedMotion": candidate.reducedMotion,
                "colors": controller.pick(candidate.colors, controller.colorKeys),
                "typography": Object.assign({
                    "fontFamily": candidate.typography.fontFamily
                }, controller.pick(candidate.typography, controller.typographyNumberKeys)),
                "spacing": controller.pick(candidate.spacing, controller.spacingKeys),
                "radius": controller.pick(candidate.radius, controller.radiusKeys),
                "motion": Object.assign(controller.pick(candidate.motion, controller.motionDurationKeys), controller.pick(candidate.motion, controller.motionEasingKeys)),
                "opacity": controller.pick(candidate.opacity, controller.opacityKeys),
                "metrics": controller.pick(candidate.metrics, controller.metricKeys)
            };
            return {
                "accepted": true,
                "errorCode": "",
                "theme": theme
            };
        }
        function pick(source, keys): var {
            const result = {};
            for (const key of keys)
                result[key] = source[key];
            return result;
        }
        function rejection(errorCode: string): var {
            return {
                "accepted": false,
                "errorCode": errorCode,
                "theme": null
            };
        }
        function result(accepted: bool, changed: bool, errorCode: string): var {
            return Object.freeze({
                "accepted": accepted,
                "changed": changed,
                "errorCode": errorCode,
                "revision": root.revision
            });
        }
        function safeSource(source): string {
            return typeof source === "string" && /^[a-z][A-Za-z0-9.-]*$/.test(source) ? source : "invalid";
        }
        function scheduleConfigSync() {
            configSyncTimer.restart();
        }
        function validContrast(colors, highContrast: bool): bool {
            const textMinimum = highContrast ? 7.0 : 4.5;
            const uiMinimum = highContrast ? 4.5 : 3.0;
            return controller.contrast(colors.textPrimary, colors.surfaceBase) >= textMinimum && controller.contrast(colors.textSecondary, colors.surfaceBase) >= textMinimum && controller.contrast(colors.textPrimary, colors.surfaceRaised) >= textMinimum && controller.contrast(colors.textSecondary, colors.surfaceRaised) >= textMinimum && controller.contrast(colors.textDisabled, colors.surfaceBase) >= uiMinimum && controller.contrast(colors.textOnAccent, colors.accentPrimary) >= textMinimum && controller.contrast(colors.accentOnContainer, colors.accentContainer) >= textMinimum && controller.contrast(colors.outlineStrong, colors.surfaceBase) >= uiMinimum && controller.contrast(colors.outlineFocus, colors.surfaceBase) >= uiMinimum && controller.contrast(colors.success, colors.surfaceBase) >= uiMinimum && controller.contrast(colors.warning, colors.surfaceBase) >= uiMinimum && controller.contrast(colors.critical, colors.surfaceBase) >= uiMinimum && controller.contrast(colors.privacy, colors.surfaceBase) >= uiMinimum;
        }
    }
}
