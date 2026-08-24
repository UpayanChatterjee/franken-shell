import "../features/feedback" as FeedbackFeatures
import QtQuick
import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    required property var monitor
    required property var screenInfo
    required property var service
    required property var theme

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.margins.bottom: 124
    WlrLayershell.margins.right: root.theme.spacing.space5
    WlrLayershell.namespace: "franken-shell-system-toasts"
    aboveWindows: true
    anchors.bottom: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: true
    implicitHeight: host.implicitHeight
    implicitWidth: host.implicitWidth
    reloadableId: "toast-host-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    visible: host.visible

    FeedbackFeatures.ToastHost {
        id: host

        anchors.fill: parent
        maximumHeight: Math.max(1, Number(root.screenInfo?.height ?? 720) - 180)
        ownerMonitorId: String(root.monitor?.runtimeId ?? "")
        service: root.service
        theme: root.theme
    }
}
