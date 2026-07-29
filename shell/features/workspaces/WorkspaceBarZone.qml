pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property real cellExtent
    readonly property real mainAxisExtent: pagerMainExtent + (root.specialWorkspaceController.definitionsCount > 0 ? root.spacing + root.cellExtent : 0)
    readonly property real pagerMainExtent: root.workspaceController.visibleNumbers.length * root.cellExtent + Math.max(0, root.workspaceController.visibleNumbers.length - 1) * root.spacing
    required property real spacing
    required property var specialWorkspaceController
    required property var surfaceCoordinator
    required property var theme
    required property bool vertical
    required property var workspaceController

    // qmllint disable missing-property
    function anchorItem(anchorId: string): var {
        const content = contentLoader.item;
        if (content === null)
            return null;
        for (const item of content["children"]) {
            if (item["anchorId"] === anchorId)
                return item;
        }
        return null;
    }

    // qmllint enable missing-property

    implicitHeight: root.vertical ? root.mainAxisExtent : root.theme.metrics.barThickness
    implicitWidth: root.vertical ? root.theme.metrics.barThickness : root.mainAxisExtent

    Loader {
        id: contentLoader

        anchors.fill: parent
        sourceComponent: root.vertical ? verticalContent : horizontalContent
    }
    Component {
        id: verticalContent

        Column {
            spacing: root.spacing
            width: parent.width

            NumberedWorkspacePager {
                id: verticalPager

                controller: root.workspaceController
                height: implicitHeight
                spacing: root.spacing
                theme: root.theme
                vertical: true
                width: parent.width

                onEscapeRequested: root.workspaceController.escapeRequested()
            }
            SpecialWorkspaceButton {
                id: verticalSpecialButton

                controller: root.specialWorkspaceController
                height: root.cellExtent
                surfaceCoordinator: root.surfaceCoordinator
                theme: root.theme
                vertical: true
                width: parent.width
            }
        }
    }
    Component {
        id: horizontalContent

        Row {
            height: parent.height
            spacing: root.spacing

            NumberedWorkspacePager {
                id: horizontalPager

                controller: root.workspaceController
                height: parent.height
                spacing: root.spacing
                theme: root.theme
                vertical: false
                width: implicitWidth

                onEscapeRequested: root.workspaceController.escapeRequested()
            }
            SpecialWorkspaceButton {
                id: horizontalSpecialButton

                controller: root.specialWorkspaceController
                height: parent.height
                surfaceCoordinator: root.surfaceCoordinator
                theme: root.theme
                vertical: false
                width: root.cellExtent
            }
        }
    }
}
