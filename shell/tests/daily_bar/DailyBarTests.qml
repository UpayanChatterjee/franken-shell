import "../../features/bar" as Bar
import "../../features/calendar" as Calendar
import "../../features/power" as Power
import "../../features/telemetry" as Telemetry
import "../../integrations/vicinae" as Vicinae
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL daily-bar:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function indicator(id: string, priority: int): var {
        return Object.freeze({
            "id": id,
            "category": id,
            "severity": id === "critical" ? "critical" : "info",
            "icon": "•",
            "accessibleName": id,
            "tooltip": id,
            "priority": priority,
            "destination": "contextSummary"
        });
    }
    function run() {
        root.check(content.endItems.map(item => item.id).join(",") === "tray,networkSpeed,audio,resources,battery,dateTime", "live composition preserves the settled end order");
        root.check(content.absoluteEndItems.length === 1 && content.absoluteEndItems[0].id === "vicinae", "Vicinae remains the absolute-end item");

        network.connectivity = "internet";
        root.check(context.indicators.length === 0, "normal connectivity remains silent");
        network.connectivity = "offline";
        root.check(context.indicators.length === 1 && context.indicators[0].category === "connectivity", "offline connectivity becomes one contextual exception");
        network.connectivity = "captive";
        root.check(context.indicators[0].severity === "critical", "captive connectivity has explicit non-normal severity");
        network.available = false;
        network.lastError = "NETWORK_RUNTIME_FAILED";
        root.check(context.indicators.length === 1 && context.indicators[0].accessibleName.length > 0, "failed network state remains local and textual");
        network.lastError = "";
        root.check(context.indicators.length === 0, "an absent optional network backend does not create permanent noise without a failure");
        network.available = true;
        network.connectivity = "internet";
        context.fixtureIndicators = Object.freeze([root.indicator("critical", 100), root.indicator("privacy", 90), root.indicator("activity", 10), root.indicator("device", 5)]);
        const boundedContext = context.visibleForCapacity(3);
        root.check(boundedContext.length === 3 && boundedContext[2].id === "overflow", "context capacity remains fixed and overflow is summarized");
        context.fixtureIndicators = Object.freeze([]);

        root.check(dateTime.timeText === "23:58" && dateTime.dateText.length > 0, "date/time formatting is controller-owned and stable");
        calendar.showNextMonth();
        root.check(calendar.visibleYear === 2027 && calendar.visibleMonth === 0 && calendar.monthCells.length === 42, "local calendar crosses the year boundary with a fixed grid");
        calendar.showToday();
        root.check(calendar.selectedDate.getFullYear() === 2026 && calendar.selectedDate.getMonth() === 11 && calendar.selectedDate.getDate() === 31, "Today restores the local selected date without a provider");
        calendar.selectDate(new Date(2028, 1, 29, 12, 0, 0));
        root.check(calendar.monthCells.some(cell => cell.inVisibleMonth && cell.day === 29), "leap-day month data remains local and deterministic");

        root.check(!vicinae.rootInvocationAvailable, "Vicinae is unavailable without a validated configured command");
        let result = vicinae.toggleRoot({
            "origin": "keyboard",
            "explicitMonitorId": "fixture-monitor"
        });
        root.check(!result.accepted && feedback.failureCount === 1 && commandRegistry.executeCount === 0, "unavailable Vicinae remains local and never guesses a command");
        commandRegistry.availableIds = ["vicinae.root", "vicinae.clipboard", "systemMonitor.open"];
        result = vicinae.toggleRoot({
            "origin": "pointer",
            "explicitMonitorId": "fixture-monitor"
        });
        root.check(result.accepted && commandRegistry.executeCount === 1 && surfaceCoordinator.closeCount === 1, "configured Vicinae invocation closes ordinary transients and routes through CommandRegistry");
        root.check(vicinae.directEntries.length === 1 && vicinae.directEntries[0].id === "vicinae.clipboard" && vicinae.directEntries[0].available, "only explicitly configured direct entries are exposed");
        result = vicinae.invokeEntry("vicinae.clipboard", {
            "origin": "keyboard"
        });
        root.check(result.accepted && commandRegistry.executeCount === 2 && surfaceCoordinator.closeCount === 2, "direct entries use the same configured registry and handoff boundary");

        root.check(!battery.visible && !battery.available, "battery absence omits the persistent cell without affecting composition");
        batteryAdapter.available = true;
        batteryAdapter.batteryAvailability = "available";
        batteryAdapter.percentage = 47;
        root.check(battery.visible && battery.label === "47" && battery.stateDescription.length > 0, "available battery state is presentation-ready");
        root.check(!resources.available && resources.memoryDescription.length > 0, "resource unavailability remains an explained local state");
        resourceAdapter.available = true;
        root.check(resources.available && resources.externalMonitorAvailable && resources.memoryPercent === 52, "resource summary composes live telemetry and configured external action availability");
        result = resources.openExternalMonitor({
            "origin": "pointer"
        });
        root.check(result.accepted && commandRegistry.executeCount === 3, "external monitor action uses its configured registry entry");

        for (let index = 0; index < 1000; index += 1) {
            network.connectivity = index % 2 === 0 ? "offline" : "internet";
            root.check(content.endItems.map(item => item.id).join(",") === "tray,networkSpeed,audio,resources,battery,dateTime", "rapid adapter changes preserve protected end ordering");
        }

        console.info("PASS daily-bar: live order, adapter fallbacks, contextual capacity, local calendar, configured-only commands, and rapid-change stability");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    QtObject {
        id: network

        property bool available: true
        property string connectivity: "internet"
        property string lastError: ""
        property string status: "connected"
    }
    Bar.ContextStatusController {
        id: context

        networkController: network
    }
    QtObject {
        id: clock

        property date now: new Date(2026, 11, 31, 23, 58, 0)
    }
    Calendar.DateTimeController {
        id: dateTime

        clockService: clock
        showDate: true
    }
    Calendar.CalendarController {
        id: calendar

        clockService: clock
        firstDayOfWeek: 1
    }
    QtObject {
        id: commandRegistry

        property var availableIds: Object.freeze([])
        property int executeCount: 0

        function commandAvailable(commandId: string): bool {
            return commandRegistry.availableIds.indexOf(commandId) >= 0;
        }
        function execute(commandId: string): var {
            commandRegistry.executeCount += 1;
            return Object.freeze({
                "commandId": commandId,
                "failureCategory": "",
                "requestId": "fixture-vicinae",
                "state": "queued"
            });
        }
    }
    QtObject {
        id: feedback

        property int failureCount: 0

        function showToast(record, context): var {
            void record;
            void context;
            feedback.failureCount += 1;
            return Object.freeze({
                "accepted": true,
                "errorCode": ""
            });
        }
    }
    QtObject {
        id: surfaceCoordinator

        property int closeCount: 0

        function closeAll(reason: string): var {
            void reason;
            surfaceCoordinator.closeCount += 1;
            return Object.freeze({
                "accepted": true,
                "changed": true,
                "errorCode": ""
            });
        }
    }
    Vicinae.VicinaeAdapter {
        id: vicinae

        commandRegistry: commandRegistry
        directEntryIds: Object.freeze(["vicinae.root", "vicinae.clipboard"])
        enabled: true
        feedbackController: feedback
        surfaceCoordinator: surfaceCoordinator
    }
    Bar.BarContentModel {
        id: content

        contextController: context
        dateTimeController: dateTime
        vicinaeAdapter: vicinae
    }
    QtObject {
        id: batteryAdapter

        property bool available: false
        property string batteryAvailability: "absent"
        property bool charging: false
        property string chargingState: "unknown"
        property real percentage: -1
        property string powerSource: "unknown"
        property bool stale: false
    }
    Power.BatteryController {
        id: battery

        adapter: batteryAdapter
    }
    QtObject {
        id: resourceAdapter

        property bool available: false
        property real cpuPercent: 18
        property bool detailVisible: false
        property var memory: Object.freeze({
            "used": 52,
            "total": 100
        })
        property real memoryPercent: 52
        property bool stale: false
        property var storage: Object.freeze({
            "used": 25,
            "total": 100
        })

        function setDetailVisible(value: bool) {
            resourceAdapter.detailVisible = value;
        }
    }
    Telemetry.ResourceSummaryController {
        id: resources

        adapter: resourceAdapter
        commandRegistry: commandRegistry
        feedbackController: feedback
    }
}
