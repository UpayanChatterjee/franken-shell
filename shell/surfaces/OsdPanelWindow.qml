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

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.margins.bottom: root.theme.spacing.space8
    WlrLayershell.margins.right: root.theme.spacing.space5
    WlrLayershell.namespace: "franken-shell-osd"
    aboveWindows: true
    anchors.bottom: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: false
    implicitHeight: host.implicitHeight
    implicitWidth: host.implicitWidth
    reloadableId: "osd-host-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    visible: host.visible

    mask: Region {
    }

    FeedbackFeatures.OsdHost {
        id: host

        anchors.fill: parent
        ownerMonitorId: String(root.monitor?.runtimeId ?? "")
        service: root.service
        theme: root.theme
    }
}
