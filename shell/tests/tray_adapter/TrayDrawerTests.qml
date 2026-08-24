import "../../features/tray" as TrayFeatures
import "../../services/tray" as TrayServices
import "../bar_host" as BarTests
import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property string artifactDirectory: String(Quickshell.env("FRANKEN_TRAY_ARTIFACT_DIR") ?? "")
    property int dismissedCount: 0
    property var fixtureMany: []

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL tray-drawer:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function finishEmptyCheck() {
        root.check(drawer.itemCount === 0 && root.dismissedCount >= 2, "an open drawer requests closure when the tray becomes empty");
        console.info("PASS tray-drawer: bounded large state, keyboard reachability, focus replacement, nested menu Escape, and empty dismissal");
        Qt.exit(0);
    }
    function item(index: int, status = "active", hasMenu = true): var {
        return Object.freeze({
            "runtimeId": "drawer-native-" + index,
            "serviceId": "org.example.Drawer" + index,
            "id": "org.example.Drawer" + index,
            "title": "Drawer item " + index,
            "status": status,
            "category": "applicationStatus",
            "icon": "",
            "tooltipTitle": "Drawer item " + index,
            "tooltipDescription": "Drawer fixture",
            "hasMenu": hasMenu,
            "onlyMenu": false
        });
    }
    function publish(items) {
        runtime.items = items;
        runtime.sequence += 1;
        runtime.stateChanged();
    }
    function run() {
        runtime.setConnected(true);
        const many = [];
        for (let index = 0; index < 20; index += 1)
            many.push(root.item(index, index === 4 ? "needsAttention" : "active"));
        root.fixtureMany = many;
        root.publish(many);
        if (root.artifactDirectory.length === 0) {
            Qt.callLater(root.runAfterCapture);
            return;
        }
        Qt.callLater(() => Qt.callLater(root.saveCaptureAndContinue));
    }
    function runAfterCapture() {
        drawer.keyboardOpened = true;
        drawer.focusIndex(10);
        root.check(drawer.itemCount === 20 && drawer.scrollOverflow, "large populations remain inside one bounded scrollable drawer");
        root.check(drawer.currentItemId === "tray:org.example.Drawer10", "keyboard focus can reach a deterministic drawer item");

        root.publish(root.fixtureMany.filter(candidate => candidate.id !== "org.example.Drawer10"));
        Qt.callLater(() => Qt.callLater(root.runAfterRemoval));
    }
    function runAfterRemoval() {
        root.check(drawer.itemCount === 19 && drawer.currentItemId !== "tray:org.example.Drawer10" && drawer.currentIndex === 10, "focused item disappearance moves to the next valid row without reordering survivors (count %1, index %2, id %3)".arg(drawer.itemCount).arg(drawer.currentIndex).arg(drawer.currentItemId));

        const menuItemId = drawer.currentItemId;
        let response = controller.openMenu(menuItemId, drawer);
        root.check(response.accepted && controller.menuState.active, "drawer context-menu request reaches the adapter");
        const dismissalsBeforeMenuEscape = root.dismissedCount;
        drawer.dismissEscape();
        root.check(!controller.menuState.active && root.dismissedCount === dismissalsBeforeMenuEscape, "first Escape closes only the nested application menu");
        drawer.dismissEscape();
        root.check(root.dismissedCount === dismissalsBeforeMenuEscape + 1, "next Escape requests drawer dismissal");

        root.publish([]);
        Qt.callLater(root.finishEmptyCheck);
    }
    function saveCaptureAndContinue() {
        drawerFrame.grabToImage(result => {
            root.check(result.saveToFile(root.artifactDirectory + "/drawer-large.png"), "tray drawer fixture screenshot is saved");
            root.runAfterCapture();
        });
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeTrayRuntime {
        id: runtime
    }
    TrayServices.TrayAdapter {
        id: adapter

        runtime: runtime
    }
    TrayFeatures.TrayController {
        id: controller

        adapter: adapter
    }
    BarTests.FakeBarTheme {
        id: theme
    }
    FloatingWindow {
        implicitHeight: drawerFrame.implicitHeight
        implicitWidth: drawerFrame.implicitWidth
        visible: true

        // qmllint disable missing-property
        Rectangle {
            id: drawerFrame

            color: theme.colors.surfacePopup
            height: implicitHeight
            implicitHeight: drawer.implicitHeight
            implicitWidth: drawer.implicitWidth
            radius: theme.radius.radiusMedium
            width: implicitWidth

            TrayFeatures.TrayPopover {
                id: drawer

                anchors.fill: parent
                controller: controller
                keyboardOpened: false
                theme: theme

                onDismissed: reason => {
                    void reason;
                    root.dismissedCount += 1;
                }
            }
        }
        // qmllint enable missing-property
    }
}
