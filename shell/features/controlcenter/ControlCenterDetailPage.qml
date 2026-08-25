pragma ComponentBehavior: Bound

import QtQuick

import "../bluetooth" as BluetoothFeatures
import "../network" as NetworkFeatures

FocusScope {
    id: root

    readonly property bool canDismiss: root.pageItem?.canDismiss !== false
    required property var contentModel
    readonly property string focusedControlId: backAction.activeFocus ? "detail.back" : ""
    required property string pageId
    readonly property var pageItem: pageLoader.status === Loader.Ready ? pageLoader.item : null
    readonly property bool protectedOperation: root.pageItem?.protectedOperation === true
    required property var theme

    signal backRequested(string source)

    function clearTransient() {
        if (typeof root.pageItem?.clearTransient === "function")
            root.pageItem.clearTransient();
    }
    function focusInitial() {
        backAction.forceActiveFocus();
    }
    function handleEscape(): bool {
        return typeof root.pageItem?.handleEscape === "function" && root.pageItem.handleEscape() === true;
    }
    function requestBack(source: string): bool {
        if (!root.canDismiss)
            return root.handleEscape();
        root.backRequested(source);
        return true;
    }

    Accessible.name: root.pageId === "network" ? qsTr("Network details") : qsTr("Bluetooth details")
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
            root.requestBack("keyboard");
            event.accepted = true;
        }
        Keys.onReturnPressed: event => {
            root.requestBack("keyboard");
            event.accepted = true;
        }
        Keys.onSpacePressed: event => {
            root.requestBack("keyboard");
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

                onTapped: root.requestBack("pointer")
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
    Loader {
        id: pageLoader

        active: root.pageId === "network" || root.pageId === "bluetooth"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: backAction.bottom
        anchors.topMargin: root.theme.spacing.space4
        sourceComponent: root.pageId === "network" ? networkPage : bluetoothPage
    }
    Component {
        id: networkPage

        NetworkFeatures.NetworkControlCenterPage {
            controller: root.contentModel?.networkController ?? null
            theme: root.theme
        }
    }
    Component {
        id: bluetoothPage

        BluetoothFeatures.BluetoothControlCenterPage {
            controller: root.contentModel?.bluetoothController ?? null
            theme: root.theme
        }
    }
}
