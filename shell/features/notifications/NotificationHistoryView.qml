pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    readonly property real contentY: historyList.contentY
    required property var controller
    readonly property int currentIndex: historyList.currentIndex
    readonly property string currentRowId: historyList.currentIndex >= 0 && historyList.currentIndex < root.controller.historyRows.length ? root.controller.historyRows[historyList.currentIndex].rowId : ""
    property string focusedRowId: ""
    readonly property int itemCount: historyList.count
    property real preservedOffset: 0
    property string preservedRowId: ""
    readonly property bool scrollOverflow: historyList.contentHeight > historyList.height
    required property var theme

    signal focused(string rowId)

    function captureScrollAnchor() {
        const index = historyList.indexAt(1, Math.max(1, historyList.contentY + 1));
        if (index < 0 || index >= root.controller.historyRows.length) {
            root.preservedRowId = "";
            root.preservedOffset = 0;
            return;
        }
        root.preservedRowId = root.controller.historyRows[index].rowId;
        const item = historyList.itemAtIndex(index);
        root.preservedOffset = item === null ? 0 : item.y - historyList.contentY;
    }
    function firstVisibleRowId(): string {
        const index = historyList.indexAt(1, Math.max(1, historyList.contentY + 1));
        return index >= 0 && index < root.controller.historyRows.length ? root.controller.historyRows[index].rowId : "";
    }
    function focusInitial() {
        root.focusRow(0);
    }
    function focusRow(index: int) {
        if (historyList.count === 0)
            return;
        historyList.currentIndex = Math.max(0, Math.min(index, historyList.count - 1));
        const target = historyList.itemAtIndex(historyList.currentIndex);
        if (target !== null)
            target.forceActiveFocus();
    }
    function positionRow(index: int) {
        historyList.positionViewAtIndex(index, ListView.Beginning);
    }
    function restoreScrollAnchor() {
        if (root.preservedRowId.length === 0)
            return;
        const index = root.controller.historyRows.findIndex(row => row.rowId === root.preservedRowId);
        if (index < 0)
            return;
        historyList.positionViewAtIndex(index, ListView.Beginning);
        historyList.contentY = Math.max(historyList.originY, historyList.contentY - root.preservedOffset);
    }

    Connections {
        function onHistoryRowsAboutToChange() {
            root.captureScrollAnchor();
        }

        target: root.controller
    }
    Column {
        anchors.fill: parent
        spacing: root.theme.spacing.space2

        Row {
            spacing: root.theme.spacing.space2
            width: parent.width

            Text {
                color: root.theme.colors.textPrimary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeSection
                font.weight: root.theme.typography.fontWeightMedium
                text: qsTr("Notification history")
                width: Math.max(0, parent.width - clearAll.width - parent.spacing)
            }
            NotificationActionButton {
                id: clearAll

                enabled: root.controller.service.records.some(record => record.dismissible)
                label: qsTr("Clear all")
                theme: root.theme

                onTriggered: source => {
                    void source;
                    root.controller.clearHistory();
                }
            }
        }
        Item {
            height: Math.max(0, parent.height - parent.spacing - clearAll.height)
            width: parent.width

            ListView {
                id: historyList

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                keyNavigationEnabled: true
                model: root.controller.historyRows
                reuseItems: true
                spacing: root.theme.spacing.space2

                delegate: Loader {
                    id: rowLoader

                    required property int index
                    required property var modelData

                    sourceComponent: modelData.kind === "group" ? groupDelegate : recordDelegate
                    width: historyList.width

                    Component {
                        id: groupDelegate

                        NotificationGroupHeader {
                            controller: root.controller
                            group: rowLoader.modelData
                            theme: root.theme
                            width: rowLoader.width

                            onFocused: rowId => {
                                root.focusedRowId = rowId;
                                historyList.currentIndex = rowLoader.index;
                                root.focused(rowId);
                            }
                        }
                    }
                    Component {
                        id: recordDelegate

                        NotificationCard {
                            allowSwipe: true
                            compact: false
                            controller: root.controller
                            record: rowLoader.modelData.record
                            theme: root.theme
                            width: rowLoader.width

                            onDismissRequested: (internalId, source) => {
                                void source;
                                root.controller.dismissPopup(internalId);
                            }
                            onFocused: internalId => {
                                root.focusedRowId = "record:" + internalId;
                                historyList.currentIndex = rowLoader.index;
                                root.focused(root.focusedRowId);
                            }
                        }
                    }
                }

                onCountChanged: Qt.callLater(root.restoreScrollAnchor)
            }
            Column {
                anchors.centerIn: parent
                spacing: root.theme.spacing.space2
                visible: root.controller.historyRows.length === 0
                width: parent.width - 2 * root.theme.spacing.space4

                Text {
                    color: root.theme.colors.textPrimary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeSection
                    font.weight: root.theme.typography.fontWeightMedium
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("No notifications yet")
                    width: parent.width
                }
                Text {
                    color: root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeBody
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Application notifications will appear here for this session.")
                    width: parent.width
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
