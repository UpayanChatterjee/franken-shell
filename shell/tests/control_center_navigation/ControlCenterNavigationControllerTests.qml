import "../../features/controlcenter" as ControlCenter
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL control-center-navigation:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function run() {
        root.check(controller.activePage === "main" && controller.activeTab === "notifications" && controller.stackDepth === 0, "navigation starts on main Notifications");
        root.check(controller.selectTab("volumeMixer") && controller.activeTab === "volumeMixer", "valid main tab selection commits");
        root.check(!controller.selectTab("unknown") && controller.activeTab === "volumeMixer", "unknown tab selection is rejected");
        root.check(controller.pushPage("network", "quick.wifi") && controller.activePage === "network" && controller.stackDepth === 1, "Network detail replaces main and records its invoker");
        root.check(!controller.selectTab("notifications") && controller.activeTab === "volumeMixer", "tabs cannot change behind a nested page");

        let result = controller.handleEscape();
        root.check(result.handled && !result.closeRequested && result.restoreFocusId === "quick.wifi", "nested Escape pops exactly one level and requests invoker focus");
        root.check(controller.activePage === "main" && controller.activeTab === "notifications" && controller.stackDepth === 0, "returning from detail restores main Notifications");

        root.check(controller.pushPage("bluetooth", "quick.bluetooth"), "Bluetooth detail can be opened independently");
        controller.resetSession();
        root.check(controller.activePage === "main" && controller.activeTab === "notifications" && controller.stackDepth === 0 && controller.lastRestoreFocusId === "", "session reset drops nested and focus restoration state");

        result = controller.handleEscape();
        root.check(!result.handled && result.closeRequested, "main-page Escape delegates drawer closure to the surface owner");
        root.check(!controller.pushPage("unknown", "quick.wifi") && controller.activePage === "main", "unknown pages are rejected");
        console.info("PASS control-center-navigation: tabs, nested pages, focus restoration, Escape unwinding, and safe reset");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    ControlCenter.ControlCenterNavigationController {
        id: controller
    }
}
