import QtQuick

QtObject {
    id: root

    readonly property real barItemExtent: 40
    readonly property real barThickness: 48
    readonly property QtObject colors: QtObject {
        readonly property color accentContainer: "#263d60"
        readonly property color accentOnContainer: "#f0f5ff"
        readonly property color critical: "#ffb4ab"
        readonly property color outlineFocus: "#a8c7fa"
        readonly property color outlineSubtle: "#3b404b"
        readonly property color surfacePopup: root.fixtureSurfacePopup
        readonly property color surfaceRaised: "#292d35"
        readonly property color textDisabled: "#8a909a"
        readonly property color textPrimary: "#f7f8fa"
        readonly property color textSecondary: "#c5c9d0"
    }
    readonly property color fixtureSurfacePopup: "#202329"
    readonly property QtObject metrics: QtObject {
        readonly property real barItemExtent: root.barItemExtent
        readonly property real barThickness: root.barThickness
        readonly property real focusRingWidth: 2
        readonly property real iconMedium: 20
        readonly property real outlineWidth: 1
        readonly property real popoverMaxWidth: 320
    }
    readonly property QtObject opacity: QtObject {
        readonly property real popover: 0.98
    }
    readonly property QtObject radius: QtObject {
        readonly property real radiusFull: 999
        readonly property real radiusMedium: 12
        readonly property real radiusSmall: 6
    }
    readonly property real space1: 4
    readonly property real space2: 8
    readonly property QtObject spacing: QtObject {
        readonly property real space1: root.space1
        readonly property real space2: root.space2
    }
    readonly property QtObject typography: QtObject {
        readonly property string fontFamily: "Sans Serif"
        readonly property real fontSizeLabel: 14
        readonly property real fontSizeMetricSmall: 12
        readonly property int fontWeightMedium: 500
        readonly property int fontWeightSemibold: 600
    }
}
