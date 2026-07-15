pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    function toggle(): void {
        toggleProc.running = true;
    }

    FileView {
        id: stateFile

        path: `${Quickshell.env("HOME")}/.config/dusky/settings/mono_audio`
        printErrors: false
        onLoaded: root.active = text().trim() === "True"
    }

    Process {
        id: toggleProc

        command: ["python3", `${Quickshell.env("HOME")}/user_scripts/audio/mono_audio_pipewire.py`, "toggle"]
        onRunningChanged: if (!running) stateFile.reload()
    }
}
