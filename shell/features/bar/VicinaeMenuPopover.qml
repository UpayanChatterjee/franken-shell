pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var adapter
    readonly property var entries: root.adapter?.directEntries ?? Object.freeze([])
    required property bool keyboardOpened
    required property var theme

    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 300)

    Component.onCompleted: {
        if (root.keyboardOpened && entriesRepeater.count > 0)
            Qt.callLater(() => entriesRepeater.itemAt(0)?.forceActiveFocus());
    }

    Column {
        id: content

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space3
        spacing: root.theme.spacing.space2

        Text {
            color: root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeTitle
            font.weight: root.theme.typography.fontWeightSemibold
            text: qsTr("Vicinae")
            width: parent.width
        }
        Text {
            color: root.theme.colors.warning
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: qsTr("No verified direct entries are available")
            visible: root.entries.length === 0
            width: parent.width
        }
        Repeater {
            id: entriesRepeater

            model: root.entries

            delegate: PopoverAction {
                required property var modelData

                detail: modelData.available ? "" : qsTr("Unavailable")
                enabled: modelData.available
                label: modelData.label
                theme: root.theme
                width: content.width

                onTriggered: origin => root.adapter.invokeEntry(modelData.id, {
                        "origin": origin
                    })
            }
        }
    }
}
