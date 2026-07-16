pragma Singleton

import QtQuick
import Quickshell

QtObject {
    readonly property string projectName: "Franken Shell"
    readonly property string projectVersion: "0.0.0-phase0"
    readonly property int configSchemaVersion: 1
    readonly property int configHelperProtocolVersion: 1
    readonly property int ipcVersion: 1

    readonly property string quickshellVersion: "0.3.0"
    readonly property string quickshellCommit: "4df562dfb2475a9057f0f33a8db75808efad8670"
    readonly property string quickshellPackage: "quickshell-git 0.3.0.r15.g4df562d-1"
    readonly property string qtVersion: "6.11.1"
    readonly property string hyprlandVersion: "0.55.4"
    readonly property string hyprlandConfigMode: "Lua"

    readonly property string vicinaeBaseline: "not tested by Phase 0 bootstrap"
    readonly property string overviewBaseline: "not tested by Phase 0 bootstrap"
    readonly property string configPath: "built-in defaults; no user configuration loaded"
    readonly property string configHelperDevelopmentExecutable:
        "root://helpers/franken-config-helper/target/debug/franken-config-helper"
    readonly property string shellPath: Quickshell.shellDir
}
