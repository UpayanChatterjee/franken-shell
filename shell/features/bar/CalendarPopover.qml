pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var controller
    readonly property var dayNames: root.orderedDayNames()
    required property bool keyboardOpened
    required property var theme

    function focusInitial() {
        const index = root.controller.monthCells.findIndex(cell => cell.today);
        const target = days.itemAt(index >= 0 ? index : 0);
        if (target !== null)
            target.forceActiveFocus();
    }
    function orderedDayNames(): var {
        const names = [qsTr("S"), qsTr("M"), qsTr("T"), qsTr("W"), qsTr("T"), qsTr("F"), qsTr("S")];
        const first = Math.max(0, Math.min(6, Number(root.controller?.firstDayOfWeek ?? 1)));
        return Object.freeze(names.slice(first).concat(names.slice(0, first)));
    }

    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 320)

    Component.onCompleted: {
        if (root.keyboardOpened)
            Qt.callLater(root.focusInitial);
    }

    Column {
        id: content

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space3
        spacing: root.theme.spacing.space2

        Row {
            spacing: root.theme.spacing.space1
            width: parent.width

            PopoverAction {
                label: qsTr("‹")
                theme: root.theme
                width: 42

                onTriggered: origin => {
                    void origin;
                    root.controller.showPreviousMonth();
                }
            }
            Text {
                color: root.theme.colors.textPrimary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.weight: root.theme.typography.fontWeightSemibold
                height: 42
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(root.controller.visibleYear, root.controller.visibleMonth, 1), "MMMM yyyy")
                verticalAlignment: Text.AlignVCenter
                width: parent.width - 92
            }
            PopoverAction {
                label: qsTr("›")
                theme: root.theme
                width: 42

                onTriggered: origin => {
                    void origin;
                    root.controller.showNextMonth();
                }
            }
        }
        Grid {
            columns: 7
            rows: 1
            width: parent.width

            Repeater {
                model: root.dayNames

                delegate: Text {
                    required property string modelData

                    color: root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeLabel
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    width: content.width / 7
                }
            }
        }
        Grid {
            columns: 7
            rows: 6
            width: parent.width

            Repeater {
                id: days

                model: root.controller.monthCells

                delegate: FocusScope {
                    id: day

                    required property int index
                    required property var modelData

                    Accessible.name: day.modelData.accessibleName
                    Accessible.role: Accessible.Button
                    activeFocusOnTab: true
                    height: 34
                    width: content.width / 7

                    Keys.onEnterPressed: event => {
                        root.controller.selectDate(day.modelData.date);
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: event => {
                        root.controller.selectDate(day.modelData.date);
                        event.accepted = true;
                    }
                    Keys.onSpacePressed: event => {
                        root.controller.selectDate(day.modelData.date);
                        event.accepted = true;
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        border.color: day.activeFocus ? root.theme.colors.outlineFocus : "transparent"
                        border.width: day.activeFocus ? root.theme.metrics.focusRingWidth : 0
                        color: day.modelData.selected ? root.theme.colors.accentContainer : "transparent"
                        height: 30
                        radius: root.theme.radius.radiusFull
                        width: 30
                    }
                    Text {
                        anchors.centerIn: parent
                        color: day.modelData.selected ? root.theme.colors.accentOnContainer : day.modelData.today ? root.theme.colors.accentPrimary : day.modelData.inVisibleMonth ? root.theme.colors.textPrimary : root.theme.colors.textDisabled
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        text: day.modelData.day
                    }
                    TapHandler {
                        onTapped: root.controller.selectDate(day.modelData.date)
                    }
                }
            }
        }
        PopoverAction {
            label: qsTr("Today")
            theme: root.theme
            width: parent.width

            onTriggered: origin => {
                void origin;
                root.controller.showToday();
            }
        }
    }
}
