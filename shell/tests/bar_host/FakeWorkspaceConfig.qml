import QtQuick

QtObject {
    readonly property QtObject numbered: QtObject {
        readonly property int groupSize: 5
        readonly property int maximum: 10
        readonly property int minimum: 1
        readonly property var semanticLabels: ({})
        readonly property bool wrap: false
    }
    readonly property QtObject overview: QtObject {
        readonly property bool openOnActiveWorkspaceClick: true
    }
    readonly property var special: [
        {
            "id": "music",
            "hyprlandName": "music",
            "label": "Music",
            "icon": "music",
            "shortcutHint": "Super+M"
        },
        {
            "id": "scratchpad",
            "hyprlandName": "scratchpad",
            "label": "Scratchpad",
            "icon": "terminal",
            "shortcutHint": "Super+S"
        }
    ]
}
