pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool speaking: ttsProc.running

    function toggle(): void {
        ttsProc.running = !ttsProc.running;
    }

    Process {
        id: ttsProc

        command: [`${Quickshell.env("HOME")}/user_scripts/tts_stt/tts_speak.sh`]
    }
}
