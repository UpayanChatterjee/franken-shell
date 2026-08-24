pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var controller
    readonly property int currentIndex: trayList.currentIndex
    readonly property string currentItemId: trayList.currentIndex >= 0 && trayList.currentIndex < root.controller.items.length ? root.controller.items[trayList.currentIndex].stableId : ""
    property string focusedItemId: ""
    readonly property int itemCount: trayList.count
    property int itemsRevision: 0
    required property bool keyboardOpened
    property int lastFocusedIndex: 0
    readonly property int maximumVisibleItems: 7
    property bool reconcilingFocus: false
    readonly property bool scrollOverflow: root.itemCount > root.maximumVisibleItems
    required property var theme

    signal dismissed(string reason)

    function dismissEscape() {
        if (root.controller.menuState.active)
            root.controller.closeMenu();
        else
            root.dismissed("escape");
    }
    function focusIndex(index: int) {
        if (trayList.count === 0)
            return;
        trayList.currentIndex = Math.max(0, Math.min(index, trayList.count - 1));
        root.focusedItemId = root.controller.items[trayList.currentIndex].stableId;
        root.lastFocusedIndex = trayList.currentIndex;
        const target = trayList.itemAtIndex(trayList.currentIndex);
        if (target !== null)
            target.forceActiveFocus();
    }
    function focusInitial() {
        if (trayList.count === 0) {
            root.dismissed("empty");
            return;
        }
        root.focusIndex(trayList.currentIndex);
    }
    function reconcileFocus() {
        if (trayList.count === 0) {
            root.focusedItemId = "";
            root.reconcilingFocus = false;
            root.dismissed("empty");
            return;
        }
        const retainedIndex = root.controller.items.findIndex(item => item.stableId === root.focusedItemId);
        if (retainedIndex >= 0) {
            trayList.currentIndex = retainedIndex;
            root.lastFocusedIndex = retainedIndex;
            root.reconcilingFocus = false;
            return;
        }
        trayList.currentIndex = Math.max(0, Math.min(root.lastFocusedIndex, trayList.count - 1));
        root.focusedItemId = root.controller.items[trayList.currentIndex].stableId;
        root.lastFocusedIndex = trayList.currentIndex;
        if (root.activeFocus) {
            Qt.callLater(() => {
                root.reconcilingFocus = false;
                root.focusInitial();
            });
        } else {
            root.reconcilingFocus = false;
        }
    }

    implicitHeight: Math.min(root.itemCount, root.maximumVisibleItems) * root.theme.metrics.barItemExtent + Math.max(0, Math.min(root.itemCount, root.maximumVisibleItems) - 1) * root.theme.spacing.space1 + 2 * root.theme.spacing.space2
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 284)

    Component.onCompleted: {
        if (root.keyboardOpened)
            Qt.callLater(root.focusInitial);
    }

    Connections {
        function onItemsChanged() {
            root.itemsRevision += 1;
            root.reconcilingFocus = true;
            Qt.callLater(root.reconcileFocus);
        }

        target: root.controller
    }
    ListView {
        id: trayList

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space2
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        currentIndex: 0
        highlightFollowsCurrentItem: true
        keyNavigationEnabled: true
        model: root.controller.items
        spacing: root.theme.spacing.space1

        delegate: TrayItemDelegate {
            required property int index
            required property var modelData

            controller: root.controller
            datum: modelData
            itemIndex: index
            theme: root.theme
            width: trayList.width

            onDismissRequested: reason => root.dismissed(reason)
            onFocused: (itemId, itemIndex) => {
                if (root.reconcilingFocus)
                    return;
                const revision = root.itemsRevision;
                Qt.callLater(() => {
                    if (revision !== root.itemsRevision || root.reconcilingFocus)
                        return;
                    root.focusedItemId = itemId;
                    root.lastFocusedIndex = itemIndex;
                    trayList.currentIndex = itemIndex;
                });
            }
        }
    }
}
