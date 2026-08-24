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
    reloadableId: "osd-fixture-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    title: qsTr("Franken Shell OSD fixture")
    visible: host.visible

    FeedbackFeatures.OsdHost {
        id: host

        anchors.fill: parent
        ownerMonitorId: String(root.monitor?.runtimeId ?? "")
        service: root.service
        theme: root.theme
    }
}
