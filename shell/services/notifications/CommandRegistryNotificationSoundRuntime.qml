import QtQuick
import Quickshell

Scope {
    id: root

    required property var commandRegistry

    function play(eventId: string): var {
        const commandId = "notification.sound." + eventId;
        if (["call", "alarm", "timer", "critical"].indexOf(eventId) < 0)
            return root.result(false, "NOTIFICATION_SOUND_EVENT_UNSUPPORTED");
        if (root.commandRegistry?.commandAvailable(commandId) !== true)
            return root.result(false, "NOTIFICATION_SOUND_BACKEND_UNAVAILABLE");
        const response = root.commandRegistry.execute(commandId);
        return root.result(response?.accepted === true, response?.accepted === true ? "" : "NOTIFICATION_SOUND_PLAYBACK_REJECTED");
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
}
