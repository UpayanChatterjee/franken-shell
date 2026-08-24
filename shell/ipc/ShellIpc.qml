import QtQuick
import Quickshell
import Quickshell.Io
import "../core" as Core

Scope {
    id: root

    readonly property int apiVersion: Core.ProjectInfo.ipcVersion
    required property var barHostProvider
    required property var configService
    required property var controlCenterHostProvider
    required property var diagnosticsProvider
    required property var surfaceCoordinator

    function dispatch(requestText: string): var {
        const parsed = controller.parse(requestText);
        if (!parsed.accepted)
            return controller.errorResponse("", parsed.errorCode);

        const request = parsed.request;
        if (request.apiVersion !== root.apiVersion)
            return controller.errorResponse(request.requestId, "IPC_UNSUPPORTED_VERSION");
        if (controller.operations.indexOf(request.operation) < 0)
            return controller.errorResponse(request.requestId, "IPC_UNKNOWN_OPERATION");

        const payload = request.payload ?? {};
        if (payload === null || typeof payload !== "object" || Array.isArray(payload) || Object.keys(payload).length > 0)
            return controller.errorResponse(request.requestId, "IPC_UNEXPECTED_PAYLOAD");

        let result;
        switch (request.operation) {
        case "diagnostics":
            result = root.diagnosticsProvider.summaryObject();
            break;
        case "reloadConfig":
            root.configService.requestReload();
            result = Object.freeze({
                "state": "accepted"
            });
            break;
        case "closeTransients":
            {
                const closeResult = root.surfaceCoordinator.closeAll("ipc");
                result = Object.freeze({
                    "state": closeResult.changed ? "closed" : "alreadyClosed",
                    "revision": closeResult.revision
                });
                break;
            }
        case "toggleControlCenter":
            {
                const toggleResult = root.controlCenterHostProvider.requestKeyboardToggle();
                result = Object.freeze({
                    "accepted": toggleResult.accepted,
                    "errorCode": toggleResult.errorCode,
                    "revision": toggleResult.revision ?? root.surfaceCoordinator.revision ?? 0,
                    "state": toggleResult.accepted ? (root.controlCenterHostProvider.openHostCount > 0 ? "open" : "closed") : "rejected"
                });
                break;
            }
        case "focusBar":
            {
                const focusResult = root.barHostProvider.requestKeyboardFocus();
                result = Object.freeze({
                    "accepted": focusResult.accepted,
                    "errorCode": focusResult.errorCode,
                    "state": focusResult.accepted ? "focused" : "rejected"
                });
                break;
            }
        default:
            return controller.errorResponse(request.requestId, "IPC_UNKNOWN_OPERATION");
        }
        return controller.successResponse(request.requestId, request.operation, result);
    }
    function versionSummary(): var {
        return Object.freeze({
            "apiVersion": root.apiVersion,
            "project": Core.ProjectInfo.projectName,
            "projectVersion": Core.ProjectInfo.projectVersion
        });
    }

    IpcHandler {
        function request(requestText: string): string {
            return JSON.stringify(root.dispatch(requestText));
        }
        function version(): string {
            return JSON.stringify(root.versionSummary());
        }

        target: "shell"
    }
    QtObject {
        id: controller

        readonly property var operations: Object.freeze(["diagnostics", "reloadConfig", "closeTransients", "toggleControlCenter", "focusBar"])

        function errorResponse(requestId: string, errorCode: string): var {
            return Object.freeze({
                "apiVersion": root.apiVersion,
                "requestId": requestId,
                "ok": false,
                "error": Object.freeze({
                    "code": errorCode
                })
            });
        }
        function parse(requestText: string): var {
            if (typeof requestText !== "string" || requestText.length === 0 || requestText.length > 4096)
                return controller.rejection("IPC_MALFORMED_REQUEST");

            let request;
            try {
                request = JSON.parse(requestText);
            } catch (error) {
                return controller.rejection("IPC_MALFORMED_REQUEST");
            }
            if (request === null || typeof request !== "object" || Array.isArray(request))
                return controller.rejection("IPC_MALFORMED_REQUEST");
            const allowedKeys = ["apiVersion", "operation", "payload", "requestId"];
            if (Object.keys(request).some(key => allowedKeys.indexOf(key) < 0))
                return controller.rejection("IPC_MALFORMED_REQUEST");
            if (!Number.isInteger(request.apiVersion) || typeof request.operation !== "string" || !controller.validRequestId(request.requestId))
                return controller.rejection("IPC_MALFORMED_REQUEST");
            return {
                "accepted": true,
                "errorCode": "",
                "request": request
            };
        }
        function rejection(errorCode: string): var {
            return {
                "accepted": false,
                "errorCode": errorCode,
                "request": null
            };
        }
        function successResponse(requestId: string, operation: string, result): var {
            return Object.freeze({
                "apiVersion": root.apiVersion,
                "requestId": requestId,
                "ok": true,
                "operation": operation,
                "result": result
            });
        }
        function validRequestId(value): bool {
            return typeof value === "string" && /^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/.test(value);
        }
    }
}
