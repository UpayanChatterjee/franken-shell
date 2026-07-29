import QtQuick

QtObject {
    readonly property QtObject contextRegion: QtObject {
        readonly property int slots: 3
    }
    property string edge: "left"
    property bool enabled: true
    property bool hideInFullscreen: true
    property var thickness: "auto"
}
