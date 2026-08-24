import "../features/feedback" as FeedbackFeatures
import QtQuick
import Quickshell

FloatingWindow {
    id: root

    required property var monitor
    required property var screenInfo
    required property var service
    required property var theme

    color: "transparent"
    implicitHeight: host.implicitHeight
    implicitWidth: host.implicitWidth
    reloadableId: "toast-fixture-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    title: qsTr("Franken Shell toast fixture")
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
