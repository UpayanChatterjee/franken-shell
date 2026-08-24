import "../../ipc" as Ipc
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function envelope(requestId: string, operation: string, apiVersion: int): string {
        return JSON.stringify({
            "apiVersion": apiVersion,
            "requestId": requestId,
            "operation": operation,
            "payload": {}
        });
    }
    function fail(message: string) {
        console.error("FAIL shell-ipc:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function run() {
        const version = shellIpc.versionSummary();
        root.check(version.apiVersion === 1 && version.project === "Franken Shell", "version handshake is explicit");
        let response = shellIpc.dispatch(root.envelope("request.diagnostics", "diagnostics", 1));
        root.check(response.ok && response.operation === "diagnostics" && response.result.shellReady, "diagnostics request returns the sanitized provider summary");
        root.check(fakeDiagnostics.summaryCount === 1, "diagnostics request invokes one owner");
        response = shellIpc.dispatch(root.envelope("request.reload", "reloadConfig", 1));
        root.check(response.ok && response.result.state === "accepted" && fakeConfigService.reloadCount === 1, "config reload routes to ConfigService");
        response = shellIpc.dispatch(root.envelope("request.close.1", "closeTransients", 1));
        root.check(response.ok && response.result.state === "closed" && fakeSurfaceCoordinator.closeCount === 1, "close-transients routes to SurfaceCoordinator");
        response = shellIpc.dispatch(root.envelope("request.close.2", "closeTransients", 1));
        root.check(response.ok && response.result.state === "alreadyClosed" && fakeSurfaceCoordinator.closeCount === 2, "repeated close-transients is safe and observable");
        response = shellIpc.dispatch(root.envelope("request.control-center.open", "toggleControlCenter", 1));
        root.check(response.ok && response.result.accepted && response.result.state === "open" && fakeControlCenterHost.toggleCount === 1, "keyboard control-centre opening routes to the coordinator-owned host");
        response = shellIpc.dispatch(root.envelope("request.control-center.close", "toggleControlCenter", 1));
        root.check(response.ok && response.result.accepted && response.result.state === "closed" && fakeControlCenterHost.toggleCount === 2, "the same keyboard operation toggles the control centre closed");
        response = shellIpc.dispatch(root.envelope("request.bar.focus", "focusBar", 1));
        root.check(response.ok && response.result.accepted && response.result.state === "focused" && fakeBarHost.focusCount === 1, "bar focus routes to the focused-monitor host");
        response = shellIpc.dispatch("{");
        root.check(!response.ok && response.requestId === "" && response.error.code === "IPC_MALFORMED_REQUEST", "malformed JSON is rejected without echoing input");
        response = shellIpc.dispatch(JSON.stringify({
            "apiVersion": 1,
            "requestId": "request.extra",
            "operation": "diagnostics",
            "payload": {},
            "arbitraryCommand": "ignored"
        }));
        root.check(!response.ok && response.error.code === "IPC_MALFORMED_REQUEST", "unknown envelope fields are rejected");
        response = shellIpc.dispatch(root.envelope("request.unsupported", "diagnostics", 999));
        root.check(!response.ok && response.requestId === "request.unsupported" && response.error.code === "IPC_UNSUPPORTED_VERSION", "unsupported API version is structured");
        response = shellIpc.dispatch(root.envelope("request.unknown", "runCommand", 1));
        root.check(!response.ok && response.error.code === "IPC_UNKNOWN_OPERATION", "unrestricted and unknown operations are rejected");
        response = shellIpc.dispatch(JSON.stringify({
            "apiVersion": 1,
            "requestId": "request.payload",
            "operation": "reloadConfig",
            "payload": {
                "path": "/tmp/not-allowed"
            }
        }));
        root.check(!response.ok && response.error.code === "IPC_UNEXPECTED_PAYLOAD" && fakeConfigService.reloadCount === 1, "operation payload cannot expand the write boundary");
        console.info("PASS shell-ipc: versioning, routing, keyboard control-centre toggle, malformed input, safety, and repeated requests");
        Qt.quit();
    }

    Component.onCompleted: startTimer.start()

    FakeShellIpcConfigService {
        id: fakeConfigService
    }
    FakeShellIpcBarHostProvider {
        id: fakeBarHost
    }
    FakeShellIpcControlCenterHostProvider {
        id: fakeControlCenterHost
    }
    FakeShellIpcDiagnostics {
        id: fakeDiagnostics
    }
    FakeShellIpcSurfaceCoordinator {
        id: fakeSurfaceCoordinator
    }
    Ipc.ShellIpc {
        id: shellIpc

        barHostProvider: fakeBarHost
        configService: fakeConfigService
        controlCenterHostProvider: fakeControlCenterHost
        diagnosticsProvider: fakeDiagnostics
        surfaceCoordinator: fakeSurfaceCoordinator
    }
    Timer {
        id: startTimer

        interval: 0

        onTriggered: root.run()
    }
}
