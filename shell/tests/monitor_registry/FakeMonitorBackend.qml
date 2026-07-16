import QtQuick

QtObject {
    property var currentSnapshot: ({
        screens: [],
        hyprlandMonitors: [],
        backendAvailability: "fixture"
    })
    readonly property string backendAvailability: "fixture"
    property int refreshRequestCount: 0
    signal stateChanged

    function snapshot() {
        return currentSnapshot;
    }

    function requestRefresh() {
        refreshRequestCount += 1;
        stateChanged();
    }

    function publish(snapshotValue) {
        currentSnapshot = snapshotValue;
        stateChanged();
    }
}
