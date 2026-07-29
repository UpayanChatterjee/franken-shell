import "../../features/workspaces" as Workspaces
import "../../services/workspaces" as WorkspaceServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int dismissalCount: 0
    property int escapeCount: 0
    property string lastDismissReason: ""

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function equalNumbers(actual, expected, message: string) {
        root.check(JSON.stringify(actual) === JSON.stringify(expected), message + ": " + JSON.stringify(actual));
    }
    function fail(message: string) {
        console.error("FAIL workspaces:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function invocation(source: string): var {
        return {
            "source": source,
            "origin": source === "keyboard" ? "keyboard" : "pointer",
            "monitorId": fixtureMonitor.runtimeId
        };
    }
    function run() {
        root.equalNumbers(workspaceController.visibleNumbers, [1, 2, 3, 4, 5], "active 1 shows 1-5");
        root.check(workspaceController.semanticLabel(1) === "Browser" && workspaceController.semanticLabel(2) === "", "semantic labels remain optional secondary metadata");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 5);
        root.equalNumbers(workspaceController.visibleNumbers, [1, 2, 3, 4, 5], "active 5 stays in 1-5");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 6);
        root.equalNumbers(workspaceController.visibleNumbers, [6, 7, 8, 9, 10], "active 6 shows 6-10");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 7);
        root.equalNumbers(workspaceController.visibleNumbers, [6, 7, 8, 9, 10], "active 7 stays in 6-10");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 10);
        root.equalNumbers(workspaceController.visibleNumbers, [6, 7, 8, 9, 10], "active 10 stays in 6-10");

        numberedConfig.maximum = 15;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 11);
        root.equalNumbers(workspaceController.visibleNumbers, [11, 12, 13, 14, 15], "range 1-15 exposes the complete third group");
        numberedConfig.maximum = 12;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 11);
        root.equalNumbers(workspaceController.visibleNumbers, [11, 12], "partial final group truncates at maximum");
        numberedConfig.maximum = 15;
        numberedConfig.groupSize = 3;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 7);
        root.equalNumbers(workspaceController.visibleNumbers, [7, 8, 9], "alternate group size three");
        numberedConfig.groupSize = 10;
        root.equalNumbers(workspaceController.visibleNumbers, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "alternate group size ten");
        const semanticLabels = numberedConfig.semanticLabels;
        numberedConfig.semanticLabels = {};
        root.check(workspaceController.semanticLabel(1) === "", "configuration without semantic labels remains valid");
        numberedConfig.semanticLabels = semanticLabels;

        numberedConfig.maximum = 10;
        numberedConfig.groupSize = 5;
        numberedConfig.wrap = false;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 1);
        fixtureAdapter.resetActions();
        workspaceController.step(-1, root.invocation("keyboard"));
        root.check(fixtureAdapter.actionCount === 0, "no-wrap minimum does not dispatch or invoke active policy");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 10);
        workspaceController.step(1, root.invocation("keyboard"));
        root.check(fixtureAdapter.actionCount === 0, "no-wrap maximum does not dispatch");
        numberedConfig.wrap = true;
        workspaceController.step(1, root.invocation("keyboard"));
        root.check(fixtureAdapter.lastNumberTarget === 1, "wrap maximum targets minimum");
        workspaceController.step(-1, root.invocation("keyboard"));
        root.check(fixtureAdapter.lastNumberTarget === 10, "wrap minimum targets maximum");

        numberedConfig.wrap = false;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 1);
        fixtureAdapter.resetActions();
        for (let index = 0; index < 6; index += 1)
            workspaceController.queueScroll(-20, root.invocation("pointer"));
        workspaceController.flushPendingScroll();
        root.check(fixtureAdapter.actionCount === 1 && fixtureAdapter.lastNumberTarget === 2, "high-resolution deltas accumulate into one normalized step");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 1);
        fixtureAdapter.resetActions();
        for (let index = 0; index < 4; index += 1)
            workspaceController.queueScroll(-120, root.invocation("pointer"));
        workspaceController.flushPendingScroll();
        root.check(fixtureAdapter.actionCount === 1 && fixtureAdapter.lastNumberTarget === 5, "rapid scroll coalesces intermediate commands and preserves final target");

        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 5);
        fixtureAdapter.resetActions();
        fixtureAdapter.overviewAvailable = false;
        const unavailableOverview = workspaceController.activateNumber(5, root.invocation("pointer"));
        root.check(!unavailableOverview.accepted && workspaceController.lastError === "OVERVIEW_UNAVAILABLE", "active policy exposes overview unavailable");
        const directAfterOverviewFailure = workspaceController.activateNumber(4, root.invocation("pointer"));
        root.check(directAfterOverviewFailure.accepted && fixtureAdapter.lastNumberTarget === 4, "overview failure does not disable direct pager action");
        fixtureAdapter.overviewAvailable = true;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 4);
        workspaceController.activateNumber(4, root.invocation("keyboard"));
        root.check(fixtureAdapter.overviewRequestCount === 1, "active activation routes through the replaceable overview policy");
        fixtureAdapter.overviewBusy = true;
        const busyOverview = workspaceController.activateNumber(4, root.invocation("keyboard"));
        root.check(!busyOverview.accepted && busyOverview.errorCode === "OVERVIEW_BUSY", "busy overview suppresses duplicate invocation");
        fixtureAdapter.overviewBusy = false;
        fixtureAdapter.overviewFailure = true;
        const failedOverview = workspaceController.activateNumber(4, root.invocation("keyboard"));
        root.check(!failedOverview.accepted && failedOverview.errorCode === "OVERVIEW_FIXTURE_FAILURE", "overview failure remains structured and local");
        fixtureAdapter.overviewFailure = false;

        pager.forceActiveFocus();
        pager.focusActive();
        root.check(pager.focusedNumber === 4, "keyboard focus enters on active visible number");
        fixtureAdapter.resetActions();
        pager.focusedNumber = 3;
        pager.activateFocused("pointer");
        root.check(fixtureAdapter.lastNumberTarget === 3, "inactive pager delegate path invokes the injected controller");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 4);
        pager.focusActive();
        pager.moveFocus(1);
        root.check(pager.focusedNumber === 5, "vertical focus traversal follows pager geometry");
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 6);
        pager.ensureValidFocus();
        root.check(pager.focusedNumber === 6, "group change preserves a valid focus target");
        const stableExtent = pager.implicitHeight;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 7);
        root.check(pager.implicitHeight === stableExtent, "selected state never changes pager geometry");
        pager.escapeRequested();
        root.check(root.escapeCount === 1, "pager Escape routes to shared focus restoration hook");
        horizontalPager.focusActive();
        horizontalPager.moveFocus(1);
        root.check(horizontalPager.focusedNumber === 8 && horizontalPager.implicitWidth > horizontalPager.implicitHeight, "horizontal pager changes navigation geometry without rotating text");

        root.check(specialController.definitionsCount === 6 && specialController.persistentIcon === "stack", "six configured special workspaces share one neutral slot");
        fixtureAdapter.setVisibleSpecialIds(fixtureMonitor.runtimeId, ["music"]);
        root.check(specialController.persistentIcon === "music" && specialController.initialFocusIndex() === 0, "one visible special workspace drives the persistent icon and initial focus");
        fixtureAdapter.setVisibleSpecialIds(fixtureMonitor.runtimeId, ["scratchpad"]);
        selector.resetFocus();
        root.check(selector.focusedIndex === 4, "selector initially focuses the visible special workspace");
        selector.moveFocus(-1);
        root.check(selector.focusedIndex === 3, "selector arrow traversal follows visible row geometry");
        selector.resetFocus();
        specialButton.requestSelector("keyboard");
        root.check(surfaceCoordinator.activePopoverId === "workspace.special-selector" && surfaceCoordinator.lastContext.takesFocus, "selector opens through SurfaceCoordinator with keyboard focus intent");
        specialButton.requestSelector("keyboard");
        root.check(surfaceCoordinator.activePopoverId === "" && surfaceCoordinator.restorationCount === 1, "reinvocation dismisses and restores focus");
        specialButton.requestSelector("pointer");
        surfaceCoordinator.removeMonitor(fixtureMonitor.runtimeId);
        root.check(surfaceCoordinator.activePopoverId === "" && surfaceCoordinator.restorationCount === 2, "monitor removal closes the owned selector and requests focus restoration");

        fixtureAdapter.setVisibleSpecialIds(fixtureMonitor.runtimeId, []);
        selector.resetFocus();
        fixtureAdapter.resetActions();
        selector.activateFocused("keyboard");
        root.check(fixtureAdapter.lastSpecialTarget === "music" && root.lastDismissReason === "success", "selector toggles through injected controller and dismisses after success");
        const dismissalsAfterSuccess = root.dismissalCount;
        selector.resetFocus();
        fixtureAdapter.failNextError = "FIXTURE_TOGGLE_FAILED";
        const failedToggle = selector.activateFocused("keyboard");
        root.check(!failedToggle.accepted && root.dismissalCount === dismissalsAfterSuccess && specialController.lastError === "FIXTURE_TOGGLE_FAILED", "toggle failure remains visible and does not dismiss selector");
        fixtureAdapter.unavailableSpecialIds = ["books"];
        fixtureAdapter.stateChanged();
        root.check(!specialController.rows[2].available, "one unavailable special definition does not disable other rows");
        root.check(specialController.rows[1].label === "Movies / Anime / Long-form video" && specialController.rows[5].shortcutHint === "", "long labels and missing optional shortcut hints remain presentation data");
        fixtureAdapter.specialBusyId = "music";
        fixtureAdapter.stateChanged();
        root.check(specialController.rows[0].busy && specialController.rows[1].available, "one busy special operation remains locally contained");
        fixtureAdapter.specialBusyId = "";
        fixtureAdapter.stateChanged();
        fixtureAdapter.setVisibleSpecialIds(fixtureMonitor.runtimeId, ["music", "scratchpad"]);
        root.check(specialController.visibleIds.length === 2 && specialController.persistentIcon === "stack", "multiple visible IDs retain a neutral unresolved persistent policy");
        selector.dismiss("escape");
        root.check(root.lastDismissReason === "escape", "selector Escape emits deterministic dismissal");

        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 42);
        root.check(!workspaceController.activeNumberInConfiguredRange && workspaceController.activeNumber === 42, "out-of-range active state remains truthful rather than clamped");
        root.equalNumbers(workspaceController.visibleNumbers, [1, 2, 3, 4, 5], "out-of-range fallback shows a neutral configured group");
        root.check(!emptySpecialButton.visible, "empty special workspace configuration omits the persistent slot");
        root.check(fallbackSpecialController.rows[0].icon === "stack", "missing fixture icon uses the neutral display fallback without changing identity");
        root.check(!unavailableController.stateAvailable && unavailableController.activeNumber === -1, "unavailable backend does not fabricate active workspace state");
        fixtureAdapter.available = false;
        fixtureAdapter.stateChanged();
        root.check(!workspaceController.stateAvailable && workspaceController.activeNumber === -1, "fixture disconnection exposes unavailable state");
        fixtureAdapter.available = true;
        fixtureAdapter.setActiveNumber(fixtureMonitor.runtimeId, 2);
        root.check(workspaceController.stateAvailable && workspaceController.activeNumber === 2, "fixture reconnection restores authoritative state");
        fixtureAdapter.setActiveNumber(secondMonitor.runtimeId, 8);
        fixtureAdapter.setVisibleSpecialIds(secondMonitor.runtimeId, ["discord"]);
        root.check(secondWorkspaceController.activeNumber === 8 && workspaceController.activeNumber === 2, "two monitor controllers derive independent active groups from one backend");
        root.check(secondSpecialController.persistentIcon === "discord" && specialController.persistentIcon === "stack", "special visibility remains monitor-contextual without duplicating definitions");

        console.info("PASS workspaces: grouping, wrap, coalescing, policy, focus, special selector, failure, and unavailable states");
        Qt.quit();
    }

    Component.onCompleted: testTimer.start()

    WorkspaceServices.FixtureWorkspaceAdapter {
        id: fixtureAdapter
    }
    WorkspaceServices.UnavailableWorkspaceAdapter {
        id: unavailableAdapter
    }
    FakeWorkspaceMonitor {
        id: fixtureMonitor
    }
    FakeWorkspaceMonitor {
        id: secondMonitor

        runtimeId: "fixture-monitor-2"
    }
    FakeWorkspaceSurfaceCoordinator {
        id: surfaceCoordinator
    }
    FakeWorkspaceTheme {
        id: fixtureTheme
    }
    QtObject {
        id: numberedConfig

        property int groupSize: 5
        property int maximum: 10
        property int minimum: 1
        property var semanticLabels: ({
                "1": "Browser",
                "4": "Notes"
            })
        property bool wrap: false
    }
    QtObject {
        id: pagerConfig

        property int groupSize: 5
        property string scrollDirection: "natural"
        property bool scrollEnabled: true
    }
    QtObject {
        id: overviewConfig

        property bool openOnActiveWorkspaceClick: true
    }
    Workspaces.ActiveWorkspacePolicy {
        id: activePolicy

        adapter: fixtureAdapter
        enabled: overviewConfig.openOnActiveWorkspaceClick
    }
    Workspaces.WorkspaceController {
        id: workspaceController

        activeActivationPolicy: activePolicy
        adapter: fixtureAdapter
        monitor: fixtureMonitor
        numberedConfig: numberedConfig
        pagerConfig: pagerConfig

        onEscapeRequested: root.escapeCount += 1
    }
    Workspaces.ActiveWorkspacePolicy {
        id: unavailablePolicy

        adapter: unavailableAdapter
        enabled: true
    }
    Workspaces.WorkspaceController {
        id: unavailableController

        activeActivationPolicy: unavailablePolicy
        adapter: unavailableAdapter
        monitor: fixtureMonitor
        numberedConfig: numberedConfig
        pagerConfig: pagerConfig
    }
    Workspaces.SpecialWorkspaceController {
        id: specialController

        adapter: fixtureAdapter
        definitions: [
            {
                "id": "music",
                "hyprlandName": "music",
                "label": "Music",
                "icon": "music",
                "shortcutHint": "Super+M"
            },
            {
                "id": "movies",
                "hyprlandName": "movies",
                "label": "Movies / Anime / Long-form video",
                "icon": "movie",
                "shortcutHint": "Super+A"
            },
            {
                "id": "books",
                "hyprlandName": "books",
                "label": "Books",
                "icon": "book",
                "shortcutHint": "Super+B"
            },
            {
                "id": "discord",
                "hyprlandName": "discord",
                "label": "Discord",
                "icon": "discord",
                "shortcutHint": "Super+D"
            },
            {
                "id": "scratchpad",
                "hyprlandName": "scratchpad",
                "label": "Scratchpad",
                "icon": "terminal",
                "shortcutHint": "Super+S"
            },
            {
                "id": "todo",
                "hyprlandName": "todo",
                "label": "Todo",
                "icon": "checklist",
                "shortcutHint": ""
            }
        ]
        monitor: fixtureMonitor
    }
    Workspaces.SpecialWorkspaceController {
        id: emptySpecialController

        adapter: fixtureAdapter
        definitions: []
        monitor: fixtureMonitor
    }
    Workspaces.SpecialWorkspaceController {
        id: fallbackSpecialController

        adapter: fixtureAdapter
        definitions: [
            {
                "id": "fallback",
                "hyprlandName": "fallback",
                "label": "Fallback icon"
            }
        ]
        monitor: fixtureMonitor
    }
    Workspaces.WorkspaceController {
        id: secondWorkspaceController

        activeActivationPolicy: activePolicy
        adapter: fixtureAdapter
        monitor: secondMonitor
        numberedConfig: numberedConfig
        pagerConfig: pagerConfig
    }
    Workspaces.SpecialWorkspaceController {
        id: secondSpecialController

        adapter: fixtureAdapter
        definitions: specialController.definitions
        monitor: secondMonitor
    }
    FloatingWindow {
        id: fixtureWindow

        color: "transparent"
        implicitHeight: 420
        implicitWidth: 360
        visible: true

        Rectangle {
            anchors.fill: parent
            color: fixtureTheme.fixtureSurfacePopup

            Workspaces.NumberedWorkspacePager {
                id: pager

                anchors.left: parent.left
                anchors.top: parent.top
                controller: workspaceController
                height: implicitHeight
                spacing: fixtureTheme.space1
                theme: fixtureTheme
                vertical: true
                width: fixtureTheme.barThickness

                onEscapeRequested: workspaceController.escapeRequested()
            }
            Workspaces.SpecialWorkspaceButton {
                id: specialButton

                anchors.left: pager.right
                anchors.leftMargin: fixtureTheme.space2
                anchors.top: parent.top
                controller: specialController
                height: fixtureTheme.barItemExtent
                surfaceCoordinator: surfaceCoordinator
                theme: fixtureTheme
                vertical: true
                width: fixtureTheme.barThickness
            }
            Workspaces.SpecialWorkspaceButton {
                id: emptySpecialButton

                controller: emptySpecialController
                surfaceCoordinator: surfaceCoordinator
                theme: fixtureTheme
                vertical: true
            }
            Workspaces.SpecialWorkspaceSelector {
                id: selector

                anchors.left: specialButton.right
                anchors.leftMargin: fixtureTheme.space2
                anchors.top: parent.top
                controller: specialController
                height: implicitHeight
                theme: fixtureTheme
                visible: true
                width: implicitWidth

                onDismissed: reason => {
                    root.dismissalCount += 1;
                    root.lastDismissReason = reason;
                    surfaceCoordinator.closePopover(reason === "escape" ? "escape" : "requested");
                }
            }
            Workspaces.NumberedWorkspacePager {
                id: horizontalPager

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                controller: workspaceController
                height: fixtureTheme.barThickness
                spacing: fixtureTheme.space1
                theme: fixtureTheme
                vertical: false
                width: implicitWidth
            }
        }
    }
    Timer {
        id: testTimer

        interval: 75

        onTriggered: root.run()
    }
}
