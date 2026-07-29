pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    readonly property real cellExtent: root.theme.metrics.barItemExtent
    required property var controller
    property int focusedNumber: -1
    property var invocationContextFactory: source => ({
                "source": source,
                "origin": source === "keyboard" ? "keyboard" : "pointer",
                "monitorId": root.controller.monitorId
            })
    required property real spacing
    required property var theme
    required property bool vertical

    signal escapeRequested

    function activateFocused(source: string): var {
        if (root.focusedNumber < 0)
            return null;
        return root.controller.activateNumber(root.focusedNumber, root.invocationContextFactory(source));
    }
    function ensureValidFocus() {
        const numbers = root.controller.visibleNumbers;
        if (numbers.length === 0) {
            root.focusedNumber = -1;
            return;
        }
        if (numbers.indexOf(root.focusedNumber) >= 0)
            return;
        root.focusedNumber = numbers.indexOf(root.controller.activeNumber) >= 0 ? root.controller.activeNumber : numbers[0];
    }
    function focusActive() {
        const numbers = root.controller.visibleNumbers;
        root.focusedNumber = numbers.indexOf(root.controller.activeNumber) >= 0 ? root.controller.activeNumber : numbers.length > 0 ? numbers[0] : -1;
    }
    function moveFocus(delta: int) {
        const numbers = root.controller.visibleNumbers;
        if (numbers.length === 0)
            return;
        const current = Math.max(0, numbers.indexOf(root.focusedNumber));
        root.focusedNumber = numbers[Math.max(0, Math.min(numbers.length - 1, current + delta))];
    }

    activeFocusOnTab: true
    implicitHeight: root.vertical ? root.controller.visibleNumbers.length * root.cellExtent + Math.max(0, root.controller.visibleNumbers.length - 1) * root.spacing : root.theme.metrics.barThickness
    implicitWidth: root.vertical ? root.theme.metrics.barThickness : root.controller.visibleNumbers.length * root.cellExtent + Math.max(0, root.controller.visibleNumbers.length - 1) * root.spacing

    Component.onCompleted: root.ensureValidFocus()
    Keys.onDownPressed: event => {
        if (root.vertical) {
            root.moveFocus(1);
            event.accepted = true;
        }
    }
    Keys.onEnterPressed: event => {
        root.activateFocused("keyboard");
        event.accepted = true;
    }
    Keys.onEscapePressed: event => {
        root.escapeRequested();
        event.accepted = true;
    }
    Keys.onLeftPressed: event => {
        if (!root.vertical) {
            root.moveFocus(-1);
            event.accepted = true;
        }
    }
    Keys.onReturnPressed: event => {
        root.activateFocused("keyboard");
        event.accepted = true;
    }
    Keys.onRightPressed: event => {
        if (!root.vertical) {
            root.moveFocus(1);
            event.accepted = true;
        }
    }
    Keys.onSpacePressed: event => {
        root.activateFocused("keyboard");
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        if (root.vertical) {
            root.moveFocus(-1);
            event.accepted = true;
        }
    }
    onActiveFocusChanged: {
        if (root.activeFocus)
            root.focusActive();
    }

    Connections {
        function onVisibleNumbersChanged() {
            root.ensureValidFocus();
        }

        target: root.controller
    }
    Loader {
        anchors.fill: parent
        sourceComponent: root.vertical ? verticalContent : horizontalContent
    }
    Component {
        id: verticalContent

        Column {
            spacing: root.spacing
            width: parent.width

            Repeater {
                model: root.controller.visibleNumbers

                delegate: WorkspaceNumberDelegate {
                    required property int modelData

                    active: root.controller.activeNumberInConfiguredRange && modelData === root.controller.activeNumber
                    extent: root.cellExtent
                    keyboardFocused: root.activeFocus && root.focusedNumber === modelData
                    number: modelData
                    semanticLabel: root.controller.semanticLabel(modelData)
                    stateAvailable: root.controller.stateAvailable
                    theme: root.theme
                    vertical: true

                    onActivated: source => {
                        root.focusedNumber = modelData;
                        root.controller.activateNumber(modelData, root.invocationContextFactory(source));
                    }
                }
            }
        }
    }
    Component {
        id: horizontalContent

        Row {
            height: parent.height
            spacing: root.spacing

            Repeater {
                model: root.controller.visibleNumbers

                delegate: WorkspaceNumberDelegate {
                    required property int modelData

                    active: root.controller.activeNumberInConfiguredRange && modelData === root.controller.activeNumber
                    extent: root.cellExtent
                    keyboardFocused: root.activeFocus && root.focusedNumber === modelData
                    number: modelData
                    semanticLabel: root.controller.semanticLabel(modelData)
                    stateAvailable: root.controller.stateAvailable
                    theme: root.theme
                    vertical: false

                    onActivated: source => {
                        root.focusedNumber = modelData;
                        root.controller.activateNumber(modelData, root.invocationContextFactory(source));
                    }
                }
            }
        }
    }
    WheelHandler {
        enabled: root.controller.scrollEnabled && root.controller.stateAvailable

        onWheel: event => {
            root.controller.queueScroll(event.angleDelta.y, root.invocationContextFactory("pointer"));
            event.accepted = true;
        }
    }
}
