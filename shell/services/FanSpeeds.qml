pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    property int refCount: 0
    property int cpuFanRpm: -1
    property int gpuFanRpm: -1

    property string _cpuFanPath: ""
    property string _gpuFanPath: ""
    property var _readTypes: []

    Component.onCompleted: {
        discoverProc.running = true;
    }

    Process {
        id: discoverProc

        command: ["sh", "-c", "for hwmon in /sys/class/hwmon/hwmon*; do for fan in \"$hwmon\"/fan*_input; do [ -f \"$fan\" ] || continue; label_file=\"${fan%_input}_label\"; if [ -f \"$label_file\" ]; then label=$(tr '[:upper:]' '[:lower:]' < \"$label_file\"); case \"$label\" in *cpu*) echo \"cpu:$fan\" ;; *gpu*) echo \"gpu:$fan\" ;; esac; fi; done; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                for (const line of lines) {
                    const colon = line.indexOf(":");
                    if (colon < 0)
                        continue;
                    const type = line.substring(0, colon);
                    const path = line.substring(colon + 1);
                    if (type === "cpu" && !root._cpuFanPath)
                        root._cpuFanPath = path;
                    if (type === "gpu" && !root._gpuFanPath)
                        root._gpuFanPath = path;
                }
            }
        }
    }

    Process {
        id: readProc

        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                for (var i = 0; i < root._readTypes.length && i < lines.length; i++) {
                    const val = parseInt(lines[i]) || -1;
                    if (root._readTypes[i] === "cpu")
                        root.cpuFanRpm = val;
                    if (root._readTypes[i] === "gpu")
                        root.gpuFanRpm = val;
                }
            }
        }
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            var cmd = ["cat"];
            root._readTypes = [];
            if (root._cpuFanPath) {
                cmd.push(root._cpuFanPath);
                root._readTypes.push("cpu");
            }
            if (root._gpuFanPath) {
                cmd.push(root._gpuFanPath);
                root._readTypes.push("gpu");
            }
            if (cmd.length > 1) {
                readProc.command = cmd;
                readProc.running = true;
            }
        }
    }
}
