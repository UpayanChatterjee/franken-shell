pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications as NotificationNative

Scope {
    id: root

    // The pinned API exposes no bus-name registration result. This runtime is
    // loaded only in an isolated ownership test and reports the attempt honestly.
    readonly property bool connected: true
    readonly property string connectionState: "activeUnverified"
    readonly property bool ownershipAttempted: true
    readonly property bool ownershipConfirmed: false
    readonly property string ownershipState: "attemptedUnverified"

    signal actionFailed(string errorCode)
    signal connectionChanged(bool connected)
    signal notificationClosed(string sourceId, string reason)
    signal notificationReceived(var record)

    function actionRecord(action): var {
        return Object.freeze({
            "id": String(action?.identifier ?? ""),
            "label": String(action?.text ?? "")
        });
    }
    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (value?.values !== undefined)
            return value.values;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function closeReason(value): string {
        switch (value) {
        case NotificationNative.NotificationCloseReason.Expired:
            return "expired";
        case NotificationNative.NotificationCloseReason.CloseRequested:
            return "closeRequested";
        default:
            return "dismissed";
        }
    }
    function dismiss(sourceId: string): var {
        const notification = root.findNotification(sourceId);
        if (notification === null)
            return root.result(false, "NOTIFICATION_UNAVAILABLE");
        try {
            notification.dismiss();
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "NOTIFICATION_DISMISS_FAILED");
        }
    }
    function findNotification(sourceId: string): var {
        const entry = state.notifications.find(candidate => candidate.sourceId === sourceId);
        return entry?.notification ?? null;
    }
    function flush() {
        const dirty = state.dirty;
        state.dirty = [];
        for (const notification of dirty) {
            if (notification !== null && notification !== undefined && notification.tracked === true)
                root.notificationReceived(root.notificationRecord(notification));
        }
    }
    function invokeAction(sourceId: string, actionId: string): var {
        const notification = root.findNotification(sourceId);
        if (notification === null)
            return root.result(false, "NOTIFICATION_UNAVAILABLE");
        const action = root.asArray(notification.actions).find(candidate => String(candidate.identifier ?? "") === actionId);
        if (action === undefined)
            return root.result(false, "NOTIFICATION_ACTION_UNAVAILABLE");
        try {
            action.invoke();
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "NOTIFICATION_ACTION_FAILED");
        }
    }
    function notificationRecord(notification): var {
        const hints = notification.hints ?? {};
        const progressValue = Number(hints.value);
        const progressMaximum = Number(hints["value-max"] ?? 100);
        return Object.freeze({
            "sourceId": root.sourceId(notification),
            "protocolId": Number(notification.id ?? -1),
            "appName": String(notification.appName ?? ""),
            "appIcon": String(notification.appIcon ?? ""),
            "desktopEntry": String(notification.desktopEntry ?? ""),
            "title": String(notification.summary ?? ""),
            "body": String(notification.body ?? ""),
            "urgency": root.urgency(notification.urgency),
            "category": String(hints.category ?? ""),
            "actions": Object.freeze(root.asArray(notification.actions).map(root.actionRecord)),
            "image": String(notification.image ?? ""),
            "progress": Object.freeze({
                "active": Number.isFinite(progressValue) && progressValue >= 0,
                "indeterminate": false,
                "value": progressValue,
                "maximum": progressMaximum
            }),
            "resident": notification.resident === true,
            "transient": notification.transient === true,
            "trustedSource": false,
            "expireTimeoutMs": Number(notification.expireTimeout ?? -1),
            "receivedAtMs": Date.now()
        });
    }
    function registerNotification(notification) {
        notification.tracked = true;
        if (state.notifications.find(candidate => candidate.notification === notification) === undefined) {
            const next = Array.from(state.notifications);
            next.push(Object.freeze({
                "notification": notification,
                "sourceId": "notification-native-" + String(notification.id ?? "unknown")
            }));
            state.notifications = next;
        }
        root.schedule(notification);
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function schedule(notification) {
        if (state.dirty.indexOf(notification) < 0) {
            const next = Array.from(state.dirty);
            next.push(notification);
            state.dirty = next;
        }
        publishTimer.restart();
    }
    function sourceId(notification): string {
        const entry = state.notifications.find(candidate => candidate.notification === notification);
        return entry?.sourceId ?? "notification-native-" + String(notification?.id ?? "unknown");
    }
    function unregisterNotification(notification) {
        state.notifications = state.notifications.filter(candidate => candidate.notification !== notification);
        state.dirty = state.dirty.filter(candidate => candidate !== notification);
    }
    function urgency(value): string {
        switch (value) {
        case NotificationNative.NotificationUrgency.Low:
            return "low";
        case NotificationNative.NotificationUrgency.Critical:
            return "critical";
        default:
            return "normal";
        }
    }

    Component.onCompleted: root.connectionChanged(true)

    QtObject {
        id: state

        property var dirty: []
        property var notifications: []
    }
    Timer {
        id: publishTimer

        interval: 0

        onTriggered: root.flush()
    }
    NotificationNative.NotificationServer {
        id: server

        actionIconsSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        bodyMarkupSupported: false
        bodySupported: true
        imageSupported: true
        inlineReplySupported: false
        keepOnReload: true
        persistenceSupported: false

        onNotification: notification => root.registerNotification(notification)
    }
    Instantiator {
        model: server.trackedNotifications

        delegate: Scope {
            id: observer

            required property var modelData

            Component.onCompleted: root.registerNotification(observer.modelData)

            Connections {
                function onActionsChanged() {
                    root.schedule(observer.modelData);
                }
                function onAppIconChanged() {
                    root.schedule(observer.modelData);
                }
                function onAppNameChanged() {
                    root.schedule(observer.modelData);
                }
                function onBodyChanged() {
                    root.schedule(observer.modelData);
                }
                function onClosed(reason) {
                    const sourceId = root.sourceId(observer.modelData);
                    root.unregisterNotification(observer.modelData);
                    root.notificationClosed(sourceId, root.closeReason(reason));
                }
                function onDesktopEntryChanged() {
                    root.schedule(observer.modelData);
                }
                function onExpireTimeoutChanged() {
                    root.schedule(observer.modelData);
                }
                function onHintsChanged() {
                    root.schedule(observer.modelData);
                }
                function onImageChanged() {
                    root.schedule(observer.modelData);
                }
                function onResidentChanged() {
                    root.schedule(observer.modelData);
                }
                function onSummaryChanged() {
                    root.schedule(observer.modelData);
                }
                function onTransientChanged() {
                    root.schedule(observer.modelData);
                }
                function onUrgencyChanged() {
                    root.schedule(observer.modelData);
                }

                target: observer.modelData
            }
        }
    }
}
