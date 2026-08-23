import QtQuick

FocusScope {
    id: root

    required property var contentModel
    readonly property string focusedControlId: backAction.activeFocus ? "detail.back" : ""
    required property string pageId
    required property var theme

    signal backRequested(string source)

    function focusInitial() {
        backAction.forceActiveFocus();
    }
    function networkDetails(): string {
        const model = root.contentModel?.networkPage;
        if (model === null || model === undefined || model.status === "unavailable")
            return qsTr("NetworkManager is unavailable. The drawer remains usable.");
        return qsTr("%1 visible · %2 saved · %3 Ethernet").arg(model.visibleNetworkCount).arg(model.savedNetworkCount).arg(model.ethernetDeviceCount);
    }
    function networkHeadline(): string {
        const model = root.contentModel?.networkPage;
        if (model?.activeConnection !== null && model?.activeConnection !== undefined)
            return qsTr("Connected to %1").arg(model.activeConnection.name);
        if (model?.status === "scanning")
            return qsTr("Scanning for networks…");
        if (model?.status === "captive")
            return qsTr("Network login required");
        if (model?.status === "limited")
            return qsTr("Limited connectivity");
        return qsTr("Network status: %1").arg(model?.status ?? "unavailable");
    }

    Accessible.name: root.pageId === "network" ? qsTr("Network detail placeholder") : qsTr("Bluetooth detail placeholder")
    Accessible.role: Accessible.Pane

    FocusScope {
        id: backAction

        Accessible.name: qsTr("Back to control centre")
        Accessible.role: Accessible.Button
        activeFocusOnTab: true
        anchors.left: parent.left
        anchors.top: parent.top
        height: 40
        width: 92

        Keys.onEnterPressed: event => {
            root.backRequested("keyboard");
            event.accepted = true;
        }
        Keys.onReturnPressed: event => {
            root.backRequested("keyboard");
            event.accepted = true;
        }
        Keys.onSpacePressed: event => {
            root.backRequested("keyboard");
            event.accepted = true;
        }

        Rectangle {
            anchors.fill: parent
            border.color: backAction.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
            border.width: backAction.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
            color: backHover.hovered ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
            radius: root.theme.radius.radiusFull

            Text {
                anchors.centerIn: parent
                color: root.theme.colors.textPrimary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeLabel
                text: qsTr("‹ Back")
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton

                onTapped: root.backRequested("pointer")
            }
            HoverHandler {
                id: backHover
            }
        }
    }
    Text {
        anchors.left: backAction.right
        anchors.leftMargin: root.theme.spacing.space3
        anchors.right: parent.right
        anchors.verticalCenter: backAction.verticalCenter
        color: root.theme.colors.textPrimary
        elide: Text.ElideRight
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeTitle
        font.weight: root.theme.typography.fontWeightSemibold
        text: root.pageId === "network" ? qsTr("Network") : qsTr("Bluetooth")
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: backAction.bottom
        anchors.topMargin: root.theme.spacing.space4
        border.color: root.theme.colors.outlineSubtle
        border.width: root.theme.metrics.outlineWidth
        color: root.theme.colors.surfaceOverlay
        radius: root.theme.radius.radiusLarge

        Column {
            anchors.centerIn: parent
            spacing: root.theme.spacing.space2
            width: parent.width - root.theme.spacing.space6 * 2

            Text {
                color: root.theme.colors.textPrimary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeSection
                font.weight: root.theme.typography.fontWeightMedium
                horizontalAlignment: Text.AlignHCenter
                text: root.pageId === "network" ? root.networkHeadline() : qsTr("Bluetooth controls arrive with the adapter.")
                width: parent.width
                wrapMode: Text.Wrap
            }
            Text {
                color: root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeBody
                horizontalAlignment: Text.AlignHCenter
                text: root.pageId === "network" ? root.networkDetails() : qsTr("This page currently validates navigation, focus, and dismissal only.")
                width: parent.width
                wrapMode: Text.Wrap
            }
        }
    }
}
