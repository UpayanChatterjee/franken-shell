import QtQuick
import Quickshell

Scope {
    function play(eventId: string): var {
        void eventId;
        return Object.freeze({
            "accepted": false,
            "errorCode": "NOTIFICATION_SOUND_BACKEND_UNAVAILABLE"
        });
    }
}
