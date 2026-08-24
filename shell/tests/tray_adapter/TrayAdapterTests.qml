import "../../features/tray" as TrayFeatures
import "../../services/tray" as TrayServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL tray-adapter:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function item(runtimeId: string, id: string, title: string, status = "active", overrides = ({})): var {
        return Object.freeze(Object.assign({
            "runtimeId": runtimeId,
            "serviceId": id,
            "id": id,
            "title": title,
            "status": status,
            "category": "applicationStatus",
            "icon": "image://icon/" + id,
            "tooltipTitle": title,
            "tooltipDescription": "Fixture tooltip",
            "hasMenu": true,
            "onlyMenu": false
        }, overrides));
    }
    function publish(items) {
        runtime.items = items;
        runtime.sequence += 1;
        runtime.stateChanged();
    }
    // Fixture objects intentionally cross var boundaries to exercise stable
    // normalization and reload-safe reconstruction.
    // qmllint disable missing-property
    function run() {
        root.check(!adapter.available && !controller.visible && adapter.items.length === 0 && !adapter.ownershipClaimed, "non-owning absence is explicit and empty");

        runtime.setConnected(true);
        root.publish([]);
        root.check(adapter.available && !controller.visible && !adapter.stale, "an empty tray stays available without exposing a dead affordance");

        const alpha = root.item("native-a", "org.example.Alpha", "Alpha");
        root.publish([alpha]);
        root.check(controller.visible && adapter.items.length === 1 && adapter.items[0].stableId === "tray:org.example.Alpha", "one item creates one normalized drawer entry and aggregate affordance");
        let response = controller.activate(adapter.items[0].stableId, root);
        root.check(response.accepted && runtime.lastAction === "activate:native-a", "primary activation is forwarded through the adapter");
        response = controller.secondaryActivate(adapter.items[0].stableId);
        root.check(response.accepted && runtime.lastAction === "secondary:native-a", "application secondary activation is forwarded without reinterpretation");
        response = controller.scroll(adapter.items[0].stableId, -120, false);
        root.check(response.accepted && runtime.lastAction === "scroll--120-vertical:native-a", "tray-item scroll preserves delta and orientation");

        response = controller.openMenu(adapter.items[0].stableId, root);
        root.check(response.accepted && controller.menuState.active && controller.menuState.itemId === adapter.items[0].stableId, "application menu opening is adapter-owned and observable");
        response = controller.closeMenu();
        root.check(response.accepted && !controller.menuState.active, "nested menu dismissal clears only the menu layer");

        const menuOnly = root.item("native-menu", "org.example.MenuOnly", "Menu only", "active", {
            "onlyMenu": true
        });
        root.publish([alpha, menuOnly]);
        response = controller.activate("tray:org.example.MenuOnly", root);
        root.check(response.accepted && runtime.lastAction === "menu:native-menu" && controller.menuState.active, "menu-only primary activation delegates to the native menu facility");
        controller.closeMenu();

        const attention = root.item("native-attention", "org.example.Attention", "Attention", "needsAttention", {
            "category": "communications"
        });
        const many = [];
        for (let index = 0; index < 24; index += 1)
            many.push(root.item("native-many-" + index, "org.example.Many" + index, "Item " + index));
        root.publish([alpha, attention].concat(many));
        root.check(controller.hasAttention && controller.items.length === 26 && controller.accessibleName().indexOf("attention") >= 0, "attention and large populations remain one count-free aggregate state");

        const firstOrder = controller.items.map(candidate => candidate.stableId).join("|");
        root.publish(many.slice().reverse().concat([root.item("native-a", "org.example.Alpha", "Alpha renamed"), attention]));
        root.check(controller.items.map(candidate => candidate.stableId).join("|") === firstOrder, "non-ordering updates and backend reorder preserve session-visible order");

        const malformed = root.item("native-malformed", "", "Bad\u0000 title", "not-a-status", {
            "category": "not-a-category",
            "icon": "broken\nicon",
            "hasMenu": false,
            "tooltipDescription": "unsafe\u0007 text"
        });
        const duplicateA = root.item("native-dup-a", "org.example.Duplicate", "Duplicate A");
        const duplicateB = root.item("native-dup-b", "org.example.Duplicate", "Duplicate B");
        root.publish([malformed, duplicateA, duplicateB]);
        root.check(controller.items.length === 3 && controller.items[0].icon === "" && controller.items[0].status === "active" && controller.items[0].category === "applicationStatus", "malformed icon and enum data degrade locally without dropping the item");
        root.check(controller.items[1].stableId !== controller.items[2].stableId && controller.items[2].stableId.indexOf("#2") > 0, "duplicate identifiers receive distinct session-only fallback identities");

        response = controller.openMenu(controller.items[1].stableId, root);
        root.check(response.accepted && controller.menuState.active, "a duplicate-id item can still open its own native menu");
        root.publish([malformed, duplicateB]);
        root.check(!controller.menuState.active && !runtime.menuOpen, "item disappearance while its menu is open closes the nested menu safely");

        runtime.failNextError = "TRAY_ACTIVATE_FAILED";
        response = controller.activate(controller.items[0].stableId, root);
        root.check(!response.accepted && adapter.lastError === "TRAY_ACTIVATE_FAILED", "action failure remains structured and scoped");

        runtime.setConnected(false);
        root.check(!adapter.available && adapter.stale && adapter.connectionState === "reconnecting" && !controller.visible, "service loss retains stale diagnostics but disables interaction");
        runtime.items = [alpha];
        runtime.sequence += 1;
        runtime.setConnected(true);
        root.check(adapter.available && !adapter.stale && controller.items.length === 1, "service reconnect replaces stale tray state");

        const fresh = freshAdapter.createObject(root, {
            "runtime": runtime
        });
        root.check(fresh !== null && !fresh["menuState"].active && fresh["items"].length === 1, "reload reconstruction does not repeat a menu or duplicate ownership state");
        fresh.destroy();

        console.info("PASS tray-adapter: empty, one, attention, large, malformed, duplicate, activation, secondary, scroll, native-menu delegation, disappearance, reconnect, and reload safety");
        Qt.exit(0);
    }

    // qmllint enable missing-property

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
    Component {
        id: freshAdapter

        TrayServices.TrayAdapter {
        }
    }
}
