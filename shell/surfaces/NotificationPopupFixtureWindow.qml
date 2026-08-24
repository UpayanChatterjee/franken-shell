import "../features/notifications" as NotificationFeatures
import QtQuick
import Quickshell

FloatingWindow {
    id: root

    required property var controller
    required property var monitor
    required property var screenInfo
    required property var theme

    color: "transparent"
    implicitHeight: popupHost.implicitHeight
    implicitWidth: popupHost.implicitWidth
    reloadableId: "notification-popup-fixture-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    title: qsTr("Franken Shell notification popup fixture")
    visible: popupHost.visible

    NotificationFeatures.NotificationPopupHost {
        id: popupHost

        anchors.fill: parent
        controller: root.controller
        maximumHeight: Math.max(1, Number(root.screenInfo?.height ?? 720) - root.theme.spacing.space8 * 2)
        ownerMonitorId: String(root.monitor?.runtimeId ?? "")
        theme: root.theme
    }
}
