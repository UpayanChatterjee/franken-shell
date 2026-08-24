import QtQuick
import Quickshell

Scope {
    id: root

    property bool dnd: false
    property bool fullscreen: false
    required property var osdService
    required property var surfaceCoordinator
    required property var toastService

    function dismissOsd(key: string): var {
        return root.osdService.dismiss(key);
    }
    function dismissToast(key: string): var {
        return root.toastService.dismiss(key);
    }
    function invokeToastAction(key: string, actionId: string): var {
        return root.toastService.invokeAction(key, actionId);
    }
    function publishTrackChange(record = ({})): var {
        void record;
        return root.result(false, "FEEDBACK_TRACK_CHANGE_IGNORED");
    }
    function resolveOwner(context): var {
        return root.surfaceCoordinator.resolveTransientMonitor(context ?? {});
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function showBrightness(value: real, available: bool, context = ({})): var {
        if (!available)
            return root.result(false, "OSD_BRIGHTNESS_UNAVAILABLE");
        return root.showOsd("brightness", value, false, context);
    }
    function showOsd(kind: string, value: real, muted: bool, context = ({})): var {
        const owner = root.resolveOwner(context);
        if (!owner.accepted)
            return root.result(false, owner.errorCode);
        return root.osdService.show({
            "kind": kind,
            "value": value,
            "muted": muted,
            "ownerMonitorId": owner.monitorId,
            "ownerReason": owner.reason,
            "origin": String(context.origin ?? "user")
        });
    }
    function showToast(record, context = ({})): var {
        const severity = String(record?.severity ?? "info");
        if (record?.userTriggered !== true && severity !== "failure")
            return root.result(false, "TOAST_PASSIVE_EVENT_SUPPRESSED");
        const owner = root.resolveOwner(context);
        if (!owner.accepted)
            return root.result(false, owner.errorCode);
        return root.toastService.show(Object.assign({}, record, {
            "ownerMonitorId": owner.monitorId,
            "ownerReason": owner.reason,
            "origin": String(context.origin ?? "user")
        }));
    }
    function showVolume(value: real, muted: bool, context = ({})): var {
        return root.showOsd("volume", value, muted, context);
    }

    Connections {
        function onRemoved(runtimeId) {
            root.osdService.dismissMonitor(runtimeId);
            root.toastService.dismissMonitor(runtimeId);
        }

        target: root.surfaceCoordinator.monitorRegistry
    }
}
