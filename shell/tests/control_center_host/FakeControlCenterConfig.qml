import QtQuick

QtObject {
    property bool enabled: true
    readonly property QtObject scrim: QtObject {
        property bool dismissOnClick: true
        property bool enabled: true
    }
    property var width: "auto"
}
