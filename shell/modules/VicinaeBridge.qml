// Bridge added for the Vicinae "caelestia-control" extension.
// Exposes shell toggles that have no IpcHandler of their own (TTS, STT, Shazam,
// Mono) over Quickshell IPC. Instantiated eagerly from shell.qml so the targets
// are always registered, even before their utilities-drawer cards are loaded.
// The handler bodies route through the shared service singletons, so the
// drawer's toggle cards stay in sync with whatever Vicinae does.
//
// If a caelestia update overwrites shell.qml, re-add `VicinaeBridge {}` to the
// ShellRoot. Remove this file and that line to fully revert.

import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services

Scope {
    id: root

    // IdleInhibitor's "idleInhibitor" IPC handler lives inside its singleton, which
    // is otherwise only referenced by the lazy utilities-drawer card — so the target
    // would not register until that drawer is opened. This binding reads the
    // singleton at startup, forcing it (and its handler) to instantiate immediately.
    readonly property bool idleInhibitorLoaded: IdleInhibitor.enabled

    IpcHandler {
        function toggle(): void {
            TTS.toggle();
        }

        function isSpeaking(): bool {
            return TTS.speaking;
        }

        target: "tts"
    }

    IpcHandler {
        function toggle(): void {
            STT.toggle();
        }

        function isRecording(): bool {
            return STT.recording;
        }

        target: "stt"
    }

    IpcHandler {
        function toggle(): void {
            Shazam.toggle();
        }

        function isRunning(): bool {
            return Shazam.running;
        }

        target: "shazam"
    }

    IpcHandler {
        function toggle(): void {
            Mono.toggle();
        }

        function isActive(): bool {
            return Mono.active;
        }

        target: "mono"
    }

    // Bar status-icon visibility (mirrors the settings app's "Status icons"
    // page). CPU/RAM/upload/download live in BarConfig (bar-extras.json); the
    // rest in Config.bar.status (shell.json), written via GlobalConfig.
    IpcHandler {
        function isExtra(icon: string): bool {
            return ["showCpu", "showRam", "showUpload", "showDownload"].includes(icon);
        }

        function toggle(icon: string): void {
            if (isExtra(icon))
                BarConfig[icon] = !BarConfig[icon];
            else
                GlobalConfig.bar.status[icon] = !Config.bar.status[icon];
        }

        function get(icon: string): bool {
            if (isExtra(icon))
                return BarConfig[icon] ?? false;
            return Config.bar.status[icon] ?? false;
        }

        target: "barIcons"
    }
}
