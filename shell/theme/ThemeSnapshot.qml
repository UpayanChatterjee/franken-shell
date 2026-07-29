import QtQuick

QtObject {
    id: root

    required property var _source
    readonly property QtObject colors: QtObject {
        readonly property color accentContainer: root._source.colors.accentContainer
        readonly property color accentOnContainer: root._source.colors.accentOnContainer
        readonly property color accentPrimary: root._source.colors.accentPrimary
        readonly property color critical: root._source.colors.critical
        readonly property color outlineFocus: root._source.colors.outlineFocus
        readonly property color outlineStrong: root._source.colors.outlineStrong
        readonly property color outlineSubtle: root._source.colors.outlineSubtle
        readonly property color privacy: root._source.colors.privacy
        readonly property color success: root._source.colors.success
        readonly property color surfaceBase: root._source.colors.surfaceBase
        readonly property color surfaceOverlay: root._source.colors.surfaceOverlay
        readonly property color surfacePopup: root._source.colors.surfacePopup
        readonly property color surfaceRaised: root._source.colors.surfaceRaised
        readonly property color surfaceScrim: root._source.colors.surfaceScrim
        readonly property color textDisabled: root._source.colors.textDisabled
        readonly property color textOnAccent: root._source.colors.textOnAccent
        readonly property color textPrimary: root._source.colors.textPrimary
        readonly property color textSecondary: root._source.colors.textSecondary
        readonly property color warning: root._source.colors.warning
    }
    readonly property bool highContrast: root._source.highContrast
    readonly property QtObject metrics: QtObject {
        readonly property real barItemExtent: root._source.metrics.barItemExtent
        readonly property real barThickness: root._source.metrics.barThickness
        readonly property real controlCenterWidth: root._source.metrics.controlCenterWidth
        readonly property real focusRingWidth: root._source.metrics.focusRingWidth
        readonly property real iconLarge: root._source.metrics.iconLarge
        readonly property real iconMedium: root._source.metrics.iconMedium
        readonly property real iconSmall: root._source.metrics.iconSmall
        readonly property real notificationWidth: root._source.metrics.notificationWidth
        readonly property real outlineWidth: root._source.metrics.outlineWidth
        readonly property real popoverMaxWidth: root._source.metrics.popoverMaxWidth
    }
    readonly property string mode: root._source.mode
    readonly property QtObject motion: QtObject {
        readonly property int durationFast: root._source.motion.durationFast
        readonly property int durationInstant: root._source.motion.durationInstant
        readonly property int durationSlow: root._source.motion.durationSlow
        readonly property int durationStandard: root._source.motion.durationStandard
        readonly property int easingAccelerate: root.easingType(root._source.motion.easingAccelerate)
        readonly property int easingDecelerate: root.easingType(root._source.motion.easingDecelerate)
        readonly property int easingEmphasized: root.easingType(root._source.motion.easingEmphasized)
        readonly property int easingStandard: root.easingType(root._source.motion.easingStandard)
    }
    readonly property QtObject opacity: QtObject {
        readonly property real bar: root._source.opacity.bar
        readonly property real controlCenter: root._source.opacity.controlCenter
        readonly property real notification: root._source.opacity.notification
        readonly property real popover: root._source.opacity.popover
    }
    readonly property QtObject radius: QtObject {
        readonly property real radiusFull: root._source.radius.radiusFull
        readonly property real radiusLarge: root._source.radius.radiusLarge
        readonly property real radiusMedium: root._source.radius.radiusMedium
        readonly property real radiusSmall: root._source.radius.radiusSmall
    }
    readonly property bool reducedMotion: root._source.reducedMotion
    readonly property QtObject spacing: QtObject {
        readonly property real space1: root._source.spacing.space1
        readonly property real space2: root._source.spacing.space2
        readonly property real space3: root._source.spacing.space3
        readonly property real space4: root._source.spacing.space4
        readonly property real space5: root._source.spacing.space5
        readonly property real space6: root._source.spacing.space6
        readonly property real space8: root._source.spacing.space8
    }
    readonly property string themeId: root._source.id
    readonly property QtObject typography: QtObject {
        readonly property string fontFamily: root._source.typography.fontFamily
        readonly property real fontSizeBody: root._source.typography.fontSizeBody
        readonly property real fontSizeLabel: root._source.typography.fontSizeLabel
        readonly property real fontSizeMetric: root._source.typography.fontSizeMetric
        readonly property real fontSizeMetricSmall: root._source.typography.fontSizeMetricSmall
        readonly property real fontSizeSection: root._source.typography.fontSizeSection
        readonly property real fontSizeTitle: root._source.typography.fontSizeTitle
        readonly property int fontWeightMedium: root._source.typography.fontWeightMedium
        readonly property int fontWeightRegular: root._source.typography.fontWeightRegular
        readonly property int fontWeightSemibold: root._source.typography.fontWeightSemibold
    }

    function easingType(name: string): int {
        switch (name) {
        case "InOutCubic":
            return Easing.InOutCubic;
        case "OutBack":
            return Easing.OutBack;
        case "OutCubic":
            return Easing.OutCubic;
        case "InCubic":
            return Easing.InCubic;
        default:
            return Easing.Linear;
        }
    }
}
