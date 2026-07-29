pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var controller
    property int focusedIndex: -1
    property var invocationContextFactory: source => ({
                "source": source,
                "origin": source === "keyboard" ? "keyboard" : "pointer",
                "monitorId": root.controller.monitorId
            })
    required property var theme

    signal dismissed(string reason)

    function activateFocused(source: string): var {
        if (root.focusedIndex < 0 || root.focusedIndex >= root.controller.rows.length)
            return null;
        return root.controller.toggle(root.controller.rows[root.focusedIndex].id, root.invocationContextFactory(source));
    }
    function dismiss(reason: string) {
        root.dismissed(reason);
    }
    function moveFocus(delta: int) {
        if (root.controller.rows.length === 0) {
            root.focusedIndex = -1;
            return;
        }
        root.focusedIndex = Math.max(0, Math.min(root.controller.rows.length - 1, root.focusedIndex + delta));
    }
    function resetFocus() {
        root.focusedIndex = root.controller.initialFocusIndex();
    }

    activeFocusOnTab: true
    implicitHeight: selectorColumn.implicitHeight + 2 * root.theme.spacing.space2
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 280)

    Component.onCompleted: root.resetFocus()
    Keys.onDownPressed: event => {
        root.moveFocus(1);
        event.accepted = true;
    }
    Keys.onEnterPressed: event => {
        root.activateFocused("keyboard");
        event.accepted = true;
    }
    Keys.onEscapePressed: event => {
        root.dismiss("escape");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.activateFocused("keyboard");
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.activateFocused("keyboard");
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        root.moveFocus(-1);
        event.accepted = true;
    }
    onVisibleChanged: {
        if (root.visible)
            root.resetFocus();
    }

    Connections {
        function onRowsChanged() {
            root.resetFocus();
        }
        function onToggleSucceeded(id) {
            void id;
            root.dismiss("success");
        }

        target: root.controller
    }
    Rectangle {
        anchors.fill: parent
        border.color: root.theme.colors.outlineSubtle
        border.width: root.theme.metrics.outlineWidth
        color: Qt.alpha(root.theme.colors.surfacePopup, root.theme.opacity.popover)
        radius: root.theme.radius.radiusMedium
    }
    Column {
        id: selectorColumn

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space2
        spacing: root.theme.spacing.space1

        Repeater {
            model: root.controller.rows

            delegate: SpecialWorkspaceDelegate {
                required property int index
                required property var modelData

                datum: modelData
                keyboardFocused: root.activeFocus && root.focusedIndex === index
                theme: root.theme
                width: selectorColumn.width

                onActivated: {
                    root.focusedIndex = index;
                    root.controller.toggle(modelData.id, root.invocationContextFactory("pointer"));
                }
            }
        }
        Text {
            color: root.theme.colors.critical
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeMetricSmall
            text: root.controller.lastError
            visible: text.length > 0
            width: parent.width
            wrapMode: Text.Wrap
        }
    }
}
