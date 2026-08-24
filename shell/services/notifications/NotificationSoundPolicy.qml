import QtQuick

QtObject {
    id: root

    function eventFor(record): string {
        if (record?.soundEligible !== true)
            return "";
        switch (String(record?.criticalBypassReason ?? "")) {
        case "incomingCall":
            return "call";
        case "alarm":
            return "alarm";
        case "timer":
            return "timer";
        case "criticalBattery":
        case "criticalStorage":
        case "criticalTemperature":
        case "recordingFailure":
            return "critical";
        default:
            return "";
        }
    }
}
