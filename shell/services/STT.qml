pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool recording: sttProc.running

    function toggle(): void {
        sttProc.running = !sttProc.running;
    }

    Process {
        id: sttProc

        command: [`${Quickshell.env("HOME")}/user_scripts/tts_stt/stt_record.sh`]
    }
}
