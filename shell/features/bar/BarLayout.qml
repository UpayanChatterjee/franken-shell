import QtQuick
import QtQuick.Layouts
import "../workspaces" as Workspaces

Item {
    id: root

    readonly property real absoluteEndPosition: root.vertical ? absoluteEndZone.y : absoluteEndZone.x
    property var audioController: null
    property var batteryController: null
    readonly property real cellExtent: root.theme.metrics.barItemExtent
    required property int contextCapacity
    readonly property real contextPosition: root.vertical ? contextZone.y : contextZone.x
    property var dateTimeController: null
    readonly property real endPosition: root.vertical ? endZone.y : endZone.x
    required property var fixtureModel
    readonly property bool layoutOverflow: root.mainAxisLength + 0.5 < root.minimumMainAxisExtent
    readonly property real mainAxisLength: root.vertical ? root.height : root.width
    readonly property real minimumMainAxisExtent: startZone.mainAxisExtent + contextZone.mainAxisExtent + endZone.mainAxisExtent + absoluteEndZone.mainAxisExtent + 4 * root.zoneSpacing
    required property string monitorId
    property var resourceController: null
    required property var specialWorkspaceController
    readonly property real startPosition: root.vertical ? startZone.y : startZone.x
    required property var surfaceCoordinator
    required property var theme
    property var throughputController: null
    property var trayController: null
    required property bool vertical
    property var vicinaeAdapter: null
    required property var workspaceController
    readonly property real zoneSpacing: root.theme.spacing.space2

    function anchorItem(anchorId: string): var {
        return startZone.anchorItem(anchorId) ?? contextZone.anchorItem(anchorId) ?? endZone.anchorItem(anchorId) ?? absoluteEndZone.anchorItem(anchorId);
    }
    function focusInitial(): bool {
        return startZone.focusInitial();
    }
    function snapshot(): var {
        return Object.freeze({
            "vertical": root.vertical,
            "mainAxisLength": root.mainAxisLength,
            "minimumMainAxisExtent": root.minimumMainAxisExtent,
            "layoutOverflow": root.layoutOverflow,
            "startPosition": root.startPosition,
            "contextPosition": root.contextPosition,
            "endPosition": root.endPosition,
            "absoluteEndPosition": root.absoluteEndPosition,
            "contextCapacity": root.contextCapacity
        });
    }

    GridLayout {
        id: axisLayout

        anchors.fill: parent
        columnSpacing: root.vertical ? 0 : root.zoneSpacing
        columns: root.vertical ? 1 : 5
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: root.vertical ? root.zoneSpacing : 0
        rows: root.vertical ? 5 : 1

        Workspaces.WorkspaceBarZone {
            id: startZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            cellExtent: root.cellExtent
            spacing: root.theme.spacing.space1
            specialWorkspaceController: root.specialWorkspaceController
            surfaceCoordinator: root.surfaceCoordinator
            theme: root.theme
            vertical: root.vertical
            workspaceController: root.workspaceController
        }
        Item {
            Layout.fillHeight: root.vertical
            Layout.fillWidth: !root.vertical
            Layout.minimumHeight: 0
            Layout.minimumWidth: 0
        }
        BarZone {
            id: contextZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            audioController: root.audioController
            batteryController: root.batteryController
            cellExtent: root.cellExtent
            dateTimeController: root.dateTimeController
            items: root.fixtureModel.contextItems
            monitorId: root.monitorId
            reservedSlots: root.contextCapacity
            resourceController: root.resourceController
            spacing: root.theme.spacing.space1
            surfaceCoordinator: root.surfaceCoordinator
            theme: root.theme
            throughputController: root.throughputController
            trayController: root.trayController
            vertical: root.vertical
            vicinaeAdapter: root.vicinaeAdapter
        }
        BarZone {
            id: endZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            audioController: root.audioController
            batteryController: root.batteryController
            cellExtent: root.cellExtent
            dateTimeController: root.dateTimeController
            items: root.fixtureModel.endItems
            monitorId: root.monitorId
            resourceController: root.resourceController
            spacing: root.theme.spacing.space1
            surfaceCoordinator: root.surfaceCoordinator
            theme: root.theme
            throughputController: root.throughputController
            trayController: root.trayController
            vertical: root.vertical
            vicinaeAdapter: root.vicinaeAdapter
        }
        BarZone {
            id: absoluteEndZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            cellExtent: root.cellExtent
            dateTimeController: root.dateTimeController
            items: root.fixtureModel.absoluteEndItems
            monitorId: root.monitorId
            resourceController: root.resourceController
            spacing: root.theme.spacing.space1
            surfaceCoordinator: root.surfaceCoordinator
            theme: root.theme
            throughputController: root.throughputController
            trayController: root.trayController
            vertical: root.vertical
            vicinaeAdapter: root.vicinaeAdapter
        }
    }
}
