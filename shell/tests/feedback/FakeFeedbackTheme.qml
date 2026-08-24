import QtQuick

QtObject {
    readonly property QtObject colors: QtObject {
        readonly property color accentContainer: "#263d60"
        readonly property color accentOnContainer: "#f0f5ff"
        readonly property color accentPrimary: "#8ab4f8"
        readonly property color critical: "#ff8a80"
        readonly property color outlineFocus: "#afcbff"
        readonly property color outlineStrong: "#7a8391"
        readonly property color outlineSubtle: "#3b404b"
        readonly property color success: "#74d69c"
        readonly property color surfaceBase: "#16181d"
        readonly property color surfaceOverlay: "#2b2f38"
        readonly property color surfacePopup: "#30343d"
        readonly property color textPrimary: "#f7f8fa"
        readonly property color textSecondary: "#b8bec9"
        readonly property color warning: "#f4c56a"
    }
    readonly property QtObject metrics: QtObject {
        readonly property real focusRingWidth: 2
        readonly property real outlineWidth: 1
    }
    readonly property QtObject opacity: QtObject {
        readonly property real popover: 0.98
    }
    readonly property QtObject radius: QtObject {
        readonly property real radiusFull: 999
        readonly property real radiusLarge: 16
        readonly property real radiusMedium: 10
        readonly property real radiusSmall: 6
    }
    readonly property QtObject spacing: QtObject {
        readonly property real space1: 4
        readonly property real space2: 8
        readonly property real space3: 12
    }
    readonly property QtObject typography: QtObject {
        readonly property string fontFamily: "Sans Serif"
        readonly property real fontSizeBody: 16
        readonly property real fontSizeLabel: 14
        readonly property real fontSizeMetric: 14
        readonly property real fontSizeSection: 18
        readonly property int fontWeightMedium: 500
        readonly property int fontWeightSemibold: 600
    }
}
