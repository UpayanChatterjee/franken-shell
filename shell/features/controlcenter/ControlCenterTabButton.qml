import QtQuick

FocusScope {
    id: root

    required property string activeTab
    readonly property string focusId: "tab." + root.tabId
    required property string label
    readonly property bool selected: root.activeTab === root.tabId
    required property string tabId
    required property var theme

    signal selectedRequested(string source)

    Accessible.checkable: true
    Accessible.checked: root.selected
    Accessible.name: root.label
    Accessible.role: Accessible.PageTab
    activeFocusOnTab: true
    implicitHeight: 40

    Keys.onEnterPressed: event => {
        root.selectedRequested("keyboard");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.selectedRequested("keyboard");
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.selectedRequested("keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.selected ? root.theme.colors.accentPrimary : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: root.selected ? root.theme.colors.accentContainer : pointerHover.hovered ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
        radius: root.theme.radius.radiusFull

        Text {
            anchors.centerIn: parent
            color: root.selected ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeLabel
            font.weight: root.selected ? root.theme.typography.fontWeightSemibold : root.theme.typography.fontWeightMedium
            text: root.label
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.selectedRequested("pointer")
        }
        HoverHandler {
            id: pointerHover
        }
    }
}
