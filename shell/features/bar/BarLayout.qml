import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property real absoluteEndPosition: root.vertical ? absoluteEndZone.y : absoluteEndZone.x
    readonly property real cellExtent: root.theme.metrics.barItemExtent
    required property int contextCapacity
    readonly property real contextPosition: root.vertical ? contextZone.y : contextZone.x
    readonly property real endPosition: root.vertical ? endZone.y : endZone.x
    required property var fixtureModel
    readonly property bool layoutOverflow: root.mainAxisLength + 0.5 < root.minimumMainAxisExtent
    readonly property real mainAxisLength: root.vertical ? root.height : root.width
    readonly property real minimumMainAxisExtent: startZone.mainAxisExtent + contextZone.mainAxisExtent + endZone.mainAxisExtent + absoluteEndZone.mainAxisExtent + 4 * root.zoneSpacing
    readonly property real startPosition: root.vertical ? startZone.y : startZone.x
    required property var theme
    required property bool vertical
    readonly property real zoneSpacing: root.theme.spacing.space2

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

        BarZone {
            id: startZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            cellExtent: root.cellExtent
            items: root.fixtureModel.startItems
            spacing: root.theme.spacing.space1
            theme: root.theme
            vertical: root.vertical
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
            cellExtent: root.cellExtent
            items: root.fixtureModel.contextItems
            reservedSlots: root.contextCapacity
            spacing: root.theme.spacing.space1
            theme: root.theme
            vertical: root.vertical
        }
        BarZone {
            id: endZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            cellExtent: root.cellExtent
            items: root.fixtureModel.endItems
            spacing: root.theme.spacing.space1
            theme: root.theme
            vertical: root.vertical
        }
        BarZone {
            id: absoluteEndZone

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth
            cellExtent: root.cellExtent
            items: root.fixtureModel.absoluteEndItems
            spacing: root.theme.spacing.space1
            theme: root.theme
            vertical: root.vertical
        }
    }
}
