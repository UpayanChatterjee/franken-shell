import QtQuick
import Quickshell
import "../calendar" as CalendarFeatures
import "../../integrations/vicinae" as VicinaeIntegrations
import "../../services/calendar" as CalendarServices

Scope {
    id: root

    required property var activeBarConfig
    required property var activeIntegrationsConfig
    required property var activeShellConfig
    readonly property alias calendarController: calendar
    required property var commandRegistry
    readonly property alias contextController: contextStatus
    readonly property alias dateTimeController: dateTime
    required property var feedbackController
    required property var networkController
    required property var surfaceCoordinator
    readonly property alias vicinaeAdapter: vicinae

    function configuredFirstDay(): int {
        const configured = String(root.activeShellConfig?.firstDayOfWeek ?? "system");
        if (configured === "monday")
            return 1;
        if (configured === "sunday")
            return 0;
        return Number(Qt.locale().firstDayOfWeek) % 7;
    }

    CalendarServices.ClockService {
        id: clock
    }
    CalendarFeatures.DateTimeController {
        id: dateTime

        clockService: clock
        monthFormat: root.activeBarConfig?.dateTime?.monthFormat ?? "shortText"
        showDate: root.activeBarConfig?.dateTime?.showDate !== false
        timeFormat: root.activeShellConfig?.clockFormat ?? "24h"
    }
    CalendarFeatures.CalendarController {
        id: calendar

        clockService: clock
        firstDayOfWeek: root.configuredFirstDay()
    }
    ContextStatusController {
        id: contextStatus

        networkController: root.networkController
    }
    VicinaeIntegrations.VicinaeAdapter {
        id: vicinae

        commandRegistry: root.commandRegistry
        directEntryIds: root.activeIntegrationsConfig?.vicinae?.shortcutMenu?.toArray?.() ?? Object.freeze([])
        enabled: root.activeIntegrationsConfig?.vicinae?.enabled === true
        feedbackController: root.feedbackController
        surfaceCoordinator: root.surfaceCoordinator
    }
}
