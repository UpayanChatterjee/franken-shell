import QtQuick
import Quickshell
import Quickshell.Wayland
import "../features/notifications" as NotificationFeatures

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    required property var controller
    required property var monitor
    required property var screenInfo
    required property var theme

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.margins.right: root.theme.spacing.space3
    WlrLayershell.margins.top: root.theme.spacing.space6
    WlrLayershell.namespace: "franken-shell-notification-popups"
    aboveWindows: true
    anchors.right: true
    anchors.top: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: true
    implicitHeight: popupHost.implicitHeight
    implicitWidth: popupHost.implicitWidth
    reloadableId: "notification-popup-host-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
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
