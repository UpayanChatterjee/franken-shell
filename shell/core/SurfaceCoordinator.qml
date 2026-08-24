import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var activeMajor: controller.publicRecord(state.snapshot.major, state.revision)
    readonly property string activeMajorId: activeMajor?.surfaceId ?? ""
    readonly property var activePopover: controller.publicRecord(state.snapshot.popover, state.revision)
    readonly property string activePopoverId: activePopover?.surfaceId ?? ""
    readonly property string lastTransition: state.lastTransition
    required property var monitorRegistry
    readonly property int rejectedRequestCount: state.rejectedRequestCount
    readonly property int restorationRequestCount: state.restorationRequestCount
    readonly property int revision: state.revision

    signal focusAcquisitionRequested(var context)
    signal focusRestorationRequested(var context)
    signal focusTransferRequested(var context)
    signal requestRejected(string operation, string errorCode)
    signal surfaceClosed(string kind, string surfaceId, string reason)
    signal surfaceOpened(string kind, string surfaceId, string ownerMonitorId)

    function closeAll(reason: string): var {
        if (state.snapshot.major === null && state.snapshot.popover === null)
            return controller.result(true, false, "");

        const safeReason = controller.safeReason(reason);
        const closed = [];
        if (state.snapshot.popover !== null)
            closed.push(controller.closure(state.snapshot.popover, safeReason, true, false));
        if (state.snapshot.major !== null)
            closed.push(controller.closure(state.snapshot.major, safeReason, true, false));
        controller.commit(null, null, "allClosed", closed, null);
        return controller.result(true, true, "");
    }
    function closeMajor(reason: string): var {
        const current = state.snapshot.major;
        if (current === null)
            return controller.result(true, false, "");
        const safeReason = controller.safeReason(reason);
        controller.commit(null, state.snapshot.popover, "majorClosed", [controller.closure(current, safeReason, true, false)], null);
        return controller.result(true, true, "");
    }
    function closePopover(reason: string): var {
        const current = state.snapshot.popover;
        if (current === null)
            return controller.result(true, false, "");
        const safeReason = controller.safeReason(reason);
        controller.commit(state.snapshot.major, null, "popoverClosed", [controller.closure(current, safeReason, true, false)], null);
        return controller.result(true, true, "");
    }
    function handleEscape(): var {
        if (state.snapshot.popover !== null)
            return root.closePopover("escape");
        if (state.snapshot.major !== null)
            return root.closeMajor("escape");
        return controller.result(true, false, "");
    }
    function openMajor(surfaceId: string, context): var {
        const normalized = controller.normalize("major", surfaceId, "", context);
        if (!normalized.accepted)
            return controller.reject("openMajor", normalized.errorCode);

        const current = state.snapshot.major;
        if (controller.sameIdentity(current, normalized.record))
            return controller.result(true, false, "");

        const closed = [];
        if (state.snapshot.popover !== null)
            closed.push(controller.closure(state.snapshot.popover, "majorOpened", false, true));
        if (current !== null)
            closed.push(controller.closure(current, "replacement", false, true));
        controller.commit(normalized.record, null, "majorOpened", closed, normalized.record);
        return controller.result(true, true, "");
    }
    function openPopover(surfaceId: string, anchorId: string, context): var {
        const normalized = controller.normalize("popover", surfaceId, anchorId, context);
        if (!normalized.accepted)
            return controller.reject("openPopover", normalized.errorCode);
        if (state.snapshot.major !== null)
            return controller.reject("openPopover", "SURFACE_MAJOR_ACTIVE");

        const current = state.snapshot.popover;
        if (controller.sameIdentity(current, normalized.record))
            return controller.result(true, false, "");

        const closed = current === null ? [] : [controller.closure(current, "replacement", false, true)];
        controller.commit(null, normalized.record, "popoverOpened", closed, normalized.record);
        return controller.result(true, true, "");
    }
    function originDisappeared(originControlId: string): var {
        if (!controller.validToken(originControlId))
            return controller.reject("originDisappeared", "SURFACE_ORIGIN_INVALID");

        const popover = state.snapshot.popover;
        if (popover !== null && (popover.originControlId === originControlId || popover.anchorId === originControlId)) {
            controller.commit(state.snapshot.major, null, "originDisappeared", [controller.closure(controller.invalidateOrigin(popover), "originUnavailable", true, false)], null);
            return controller.result(true, true, "");
        }

        const major = state.snapshot.major;
        if (major !== null && major.originControlId === originControlId && major._originAvailable) {
            controller.commit(controller.invalidateOrigin(major), state.snapshot.popover, "originInvalidated", [], null);
            return controller.result(true, true, "");
        }
        return controller.result(true, false, "");
    }
    function resolveTransientMonitor(context): var {
        if (context === null || typeof context !== "object" || Array.isArray(context))
            return Object.freeze({
                "accepted": false,
                "monitorId": "",
                "reason": "",
                "errorCode": "SURFACE_CONTEXT_INVALID"
            });
        let resolved = controller.resolvedMonitor(context.explicitMonitorId, "explicit");
        if (resolved !== null)
            return resolved;
        resolved = controller.resolvedMonitor(context.pointerMonitorId, "pointer");
        if (resolved !== null)
            return resolved;
        resolved = controller.resolvedMonitor(context.sourceSurfaceMonitorId, "sourceSurface");
        if (resolved !== null)
            return resolved;
        resolved = controller.resolvedMonitor(root.monitorRegistry.focusedWindowMonitor?.runtimeId, "focusedWindow");
        if (resolved !== null)
            return resolved;
        resolved = controller.resolvedMonitor(root.monitorRegistry.focusedMonitor?.runtimeId, "focused");
        if (resolved !== null)
            return resolved;
        resolved = controller.resolvedMonitor(root.monitorRegistry.fallbackMonitor?.runtimeId, "fallback");
        if (resolved !== null)
            return resolved;
        return Object.freeze({
            "accepted": false,
            "monitorId": "",
            "reason": "",
            "errorCode": "SURFACE_MONITOR_UNAVAILABLE"
        });
    }
    function summary(): var {
        return Object.freeze({
            "activeMajorId": root.activeMajorId,
            "activeMajorMonitorId": root.activeMajor?.ownerMonitorId ?? null,
            "activePopoverId": root.activePopoverId,
            "activePopoverMonitorId": root.activePopover?.ownerMonitorId ?? null,
            "activeSurfaceCount": (root.activeMajor === null ? 0 : 1) + (root.activePopover === null ? 0 : 1),
            "revision": root.revision,
            "lastTransition": root.lastTransition,
            "restorationRequestCount": root.restorationRequestCount,
            "rejectedRequestCount": root.rejectedRequestCount
        });
    }
    function toggleMajor(surfaceId: string, context): var {
        const current = state.snapshot.major;
        if (current !== null && current.surfaceId === surfaceId)
            return root.closeMajor("toggle");
        return root.openMajor(surfaceId, context);
    }
    function togglePopover(surfaceId: string, anchorId: string, context): var {
        const current = state.snapshot.popover;
        if (current !== null && current.surfaceId === surfaceId && current.anchorId === anchorId)
            return root.closePopover("toggle");
        return root.openPopover(surfaceId, anchorId, context);
    }

    Connections {
        function onRemoved(runtimeId) {
            controller.handleMonitorRemoved(runtimeId);
        }

        target: root.monitorRegistry
    }
    QtObject {
        id: state

        property string lastTransition: "idle"
        property int rejectedRequestCount: 0
        property int restorationRequestCount: 0
        property int revision: 0
        property var snapshot: Object.freeze({
            "major": null,
            "popover": null
        })
    }
    QtObject {
        id: controller

        readonly property var origins: Object.freeze(["pointer", "keyboard", "ipc", "system", "backend"])
        readonly property var reasons: Object.freeze(["requested", "escape", "outsideClick", "replacement", "majorOpened", "originUnavailable", "ownerMonitorRemoved", "ipc", "reload", "toggle"])

        function acquisitionContext(record): var {
            return Object.freeze({
                "kind": record.kind,
                "surfaceId": record.surfaceId,
                "ownerMonitorId": record.ownerMonitorId,
                "origin": record.origin,
                "originControlId": record.originControlId,
                "topologyRevision": record.topologyRevision
            });
        }
        function closure(record, reason: string, restoreFocus: bool, transferFocus: bool): var {
            return {
                "record": record,
                "reason": reason,
                "restoreFocus": restoreFocus,
                "transferFocus": transferFocus
            };
        }
        function commit(major, popover, transition: string, closures, opened) {
            state.snapshot = Object.freeze({
                "major": major,
                "popover": popover
            });
            state.revision += 1;
            state.lastTransition = transition;

            for (const entry of closures)
                root.surfaceClosed(entry.record.kind, entry.record.surfaceId, entry.reason);
            if (opened !== null)
                root.surfaceOpened(opened.kind, opened.surfaceId, opened.ownerMonitorId);

            const transfer = closures.find(entry => entry.transferFocus && entry.record._takesFocus);
            if (transfer !== undefined && opened !== null) {
                root.focusTransferRequested(Object.freeze({
                    "fromKind": transfer.record.kind,
                    "fromSurfaceId": transfer.record.surfaceId,
                    "toKind": opened.kind,
                    "toSurfaceId": opened.surfaceId,
                    "ownerMonitorId": opened.ownerMonitorId
                }));
            } else if (opened !== null && opened._takesFocus) {
                root.focusAcquisitionRequested(controller.acquisitionContext(opened));
            } else {
                const restore = closures.find(entry => entry.restoreFocus && entry.record._takesFocus);
                if (restore !== undefined) {
                    state.restorationRequestCount += 1;
                    root.focusRestorationRequested(controller.restorationContext(restore.record, restore.reason));
                }
            }
        }
        function handleMonitorRemoved(runtimeId: string) {
            const closed = [];
            let major = state.snapshot.major;
            let popover = state.snapshot.popover;
            if (popover !== null && popover.ownerMonitorId === runtimeId) {
                popover = controller.invalidateMonitor(controller.invalidateOrigin(popover));
                closed.push(controller.closure(popover, "ownerMonitorRemoved", true, false));
                popover = null;
            }
            if (major !== null && major.ownerMonitorId === runtimeId) {
                major = controller.invalidateMonitor(controller.invalidateOrigin(major));
                closed.push(controller.closure(major, "ownerMonitorRemoved", true, false));
                major = null;
            }
            if (closed.length > 0)
                controller.commit(major, popover, "ownerMonitorRemoved", closed, null);
        }
        function invalidateMonitor(record): var {
            return controller.replacePrivate(record, {
                "_ownerMonitorAvailable": false
            });
        }
        function invalidateOrigin(record): var {
            return controller.replacePrivate(record, {
                "_originAvailable": false
            });
        }
        function monitorAvailable(runtimeId: string): bool {
            const monitor = root.monitorRegistry.monitorByRuntimeId(runtimeId);
            return monitor !== null && monitor.connected !== false;
        }
        function normalize(kind: string, surfaceId: string, anchorId: string, context): var {
            if (!controller.validToken(surfaceId))
                return controller.rejection("SURFACE_ID_INVALID");
            if (kind === "popover" && !controller.validToken(anchorId))
                return controller.rejection("SURFACE_ANCHOR_INVALID");
            if (context === null || typeof context !== "object" || Array.isArray(context))
                return controller.rejection("SURFACE_CONTEXT_INVALID");
            if (controller.origins.indexOf(context.origin) < 0 || typeof context.takesFocus !== "boolean")
                return controller.rejection("SURFACE_CONTEXT_INVALID");
            if (!controller.validToken(context.monitorId) || !controller.monitorAvailable(context.monitorId))
                return controller.rejection("SURFACE_MONITOR_UNAVAILABLE");

            const originControlId = context.originControlId ?? "";
            const previousFocusToken = context.previousFocusToken ?? "";
            if ((originControlId.length > 0 && !controller.validToken(originControlId)) || (previousFocusToken.length > 0 && !controller.validToken(previousFocusToken)))
                return controller.rejection("SURFACE_CONTEXT_INVALID");

            return {
                "accepted": true,
                "errorCode": "",
                "record": Object.freeze({
                    "kind": kind,
                    "surfaceId": surfaceId,
                    "anchorId": kind === "popover" ? anchorId : "",
                    "ownerMonitorId": context.monitorId,
                    "origin": context.origin,
                    "originControlId": originControlId,
                    "topologyRevision": Number(root.monitorRegistry.revision ?? 0),
                    "_previousFocusToken": previousFocusToken,
                    "_takesFocus": context.takesFocus,
                    "_originAvailable": originControlId.length > 0,
                    "_ownerMonitorAvailable": true
                })
            };
        }
        function publicRecord(record, revision): var {
            void revision;
            if (record === null)
                return null;
            return Object.freeze({
                "kind": record.kind,
                "surfaceId": record.surfaceId,
                "anchorId": record.anchorId,
                "ownerMonitorId": record.ownerMonitorId,
                "origin": record.origin,
                "originControlId": record.originControlId,
                "topologyRevision": record.topologyRevision
            });
        }
        function reject(operation: string, errorCode: string): var {
            state.rejectedRequestCount += 1;
            root.requestRejected(operation, errorCode);
            return controller.result(false, false, errorCode);
        }
        function rejection(errorCode: string): var {
            return {
                "accepted": false,
                "errorCode": errorCode,
                "record": null
            };
        }
        function replacePrivate(record, changes): var {
            return Object.freeze(Object.assign({}, record, changes));
        }
        function resolvedMonitor(value, reason: string): var {
            const monitorId = String(value ?? "");
            if (!controller.validToken(monitorId) || !controller.monitorAvailable(monitorId))
                return null;
            return Object.freeze({
                "accepted": true,
                "monitorId": monitorId,
                "reason": reason,
                "errorCode": ""
            });
        }
        function restorationContext(record, reason: string): var {
            return Object.freeze({
                "kind": record.kind,
                "surfaceId": record.surfaceId,
                "ownerMonitorId": record.ownerMonitorId,
                "originControlId": record._originAvailable ? record.originControlId : "",
                "previousFocusToken": record._previousFocusToken,
                "originAvailable": record._originAvailable,
                "ownerMonitorAvailable": record._ownerMonitorAvailable,
                "topologyRevision": record.topologyRevision,
                "reason": reason
            });
        }
        function result(accepted: bool, changed: bool, errorCode: string): var {
            return Object.freeze({
                "accepted": accepted,
                "changed": changed,
                "errorCode": errorCode,
                "revision": root.revision
            });
        }
        function safeReason(reason): string {
            return typeof reason === "string" && controller.reasons.indexOf(reason) >= 0 ? reason : "requested";
        }
        function sameIdentity(left, right): bool {
            return left !== null && right !== null && left.kind === right.kind && left.surfaceId === right.surfaceId && left.anchorId === right.anchorId && left.ownerMonitorId === right.ownerMonitorId && left.origin === right.origin && left.originControlId === right.originControlId && left._previousFocusToken === right._previousFocusToken && left._takesFocus === right._takesFocus;
        }
        function validToken(value): bool {
            return typeof value === "string" && /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(value);
        }
    }
}
