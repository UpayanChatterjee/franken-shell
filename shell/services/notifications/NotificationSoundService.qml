import QtQuick
import Quickshell

Scope {
    id: root

    property bool enabled: true
    readonly property int failedCount: state.failedCount
    readonly property string lastError: state.lastError
    readonly property string lastEvent: state.lastEvent
    required property var notificationService
    readonly property int playedCount: state.playedCount
    required property var policy
    required property var runtime

    function handleRequested(record) {
        if (!root.enabled)
            return;
        const eventId = root.policy.eventFor(record);
        if (eventId.length === 0)
            return;
        const response = root.runtime.play(eventId);
        state.lastEvent = eventId;
        if (response?.accepted === true) {
            state.playedCount += 1;
            state.lastError = "";
        } else {
            state.failedCount += 1;
            state.lastError = String(response?.errorCode ?? "NOTIFICATION_SOUND_PLAYBACK_REJECTED");
        }
    }

    QtObject {
        id: state

        property int failedCount: 0
        property string lastError: ""
        property string lastEvent: ""
        property int playedCount: 0
    }
    Connections {
        function onSoundRequested(record) {
            root.handleRequested(record);
        }

        target: root.notificationService
    }
}
