pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool running: shazamProc.running

    function toggle(): void {
        shazamProc.running = !shazamProc.running;
    }

    Process {
        id: shazamProc

        command: ["/home/tony/user_scripts/music/music_recognition.sh"]
    }
}
