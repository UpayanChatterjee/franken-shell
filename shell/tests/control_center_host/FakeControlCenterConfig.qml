import QtQuick

QtObject {
    readonly property QtObject edgeDrag: QtObject {
        property real activationWidth: 2
        property bool allowInFullscreen: false
        property bool enabled: true
        property real horizontalIntentRatio: 1.5
        property real minimumDistance: 24
        property real openThreshold: 0.35
        property real velocityThreshold: 900
    }
    property bool enabled: true
    readonly property QtObject scrim: QtObject {
        property bool dismissOnClick: true
        property bool enabled: true
    }
    property var width: "auto"
}
