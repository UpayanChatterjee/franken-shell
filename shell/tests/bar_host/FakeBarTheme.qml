import QtQuick

QtObject {
    id: root

    readonly property QtObject colors: QtObject {
        readonly property color accentContainer: "#263d60"
        readonly property color accentOnContainer: "#f0f5ff"
        readonly property color outlineSubtle: "#3b404b"
        readonly property color privacy: "#d7a7ff"
        readonly property color surfaceBase: "#16181d"
        readonly property color textPrimary: "#f7f8fa"
    }
    property real fontScale: 1
    readonly property QtObject metrics: QtObject {
        readonly property real barItemExtent: 40
        readonly property real barThickness: 48
        readonly property real outlineWidth: 1
    }
    readonly property QtObject opacity: QtObject {
        readonly property real bar: 0.96
    }
    readonly property QtObject radius: QtObject {
        readonly property real radiusFull: 999
        readonly property real radiusSmall: 6
    }
    readonly property QtObject spacing: QtObject {
        readonly property real space1: 4
        readonly property real space2: 8
    }
    readonly property QtObject typography: QtObject {
        readonly property string fontFamily: "Sans Serif"
        readonly property real fontSizeLabel: 14 * root.fontScale
        readonly property real fontSizeMetricSmall: 12 * root.fontScale
        readonly property int fontWeightMedium: 500
        readonly property int fontWeightSemibold: 600
    }
}
