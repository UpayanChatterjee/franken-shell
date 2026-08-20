import QtQuick

QtObject {
    readonly property var monitors: Object.freeze([Object.freeze({
            "runtimeId": "monitor-1",
            "connector": "eDP-1",
            "activeWorkspaceId": 2,
            "fullscreenActive": false
        }), Object.freeze({
            "runtimeId": "monitor-2",
            "connector": "DP-1",
            "activeWorkspaceId": 7,
            "fullscreenActive": false
        })])
}
