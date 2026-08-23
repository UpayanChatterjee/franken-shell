import "../../features/bar" as Bar
import "../../features/controlcenter" as ControlCenter
import "../../features/power" as PowerFeatures
import "../../services/power" as PowerServices
import "../bar_host" as BarFixtures
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function battery(percentage: real, chargingState: string, powerSource: string, estimateSeconds: real, estimateCredible: bool): var {
        return Object.freeze({
            "present": true,
            "percentage": percentage,
            "chargingState": chargingState,
            "powerSource": powerSource,
            "timeEstimateSeconds": estimateSeconds,
            "estimateCredible": estimateCredible
        });
    }
    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL power-adapters:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function run() {
        root.check(batteryAdapter.serviceAvailability === "unavailable" && batteryAdapter.batteryAvailability === "unknown", "missing UPower starts unknown without fabricating a battery");
        batteryRuntime.setConnected(true);
        root.check(batteryAdapter.serviceAvailability === "ready" && batteryAdapter.batteryAvailability === "absent" && !batteryController.visible, "desktop fixture omits the battery when UPower authoritatively reports none");

        batteryRuntime.batteryRecord = root.battery(64.4, "charging", "linePower", 3600, true);
        batteryRuntime.sequence += 1;
        batteryRuntime.stateChanged();
        root.check(batteryAdapter.available && batteryAdapter.percentage === 64.4 && batteryAdapter.charging, "charging battery state and percentage normalize without polling");
        root.check(batteryAdapter.timeEstimateState === "credible" && batteryAdapter.timeEstimateSeconds === 3600, "explicitly credible backend estimate is exposed");
        root.check(!batteryController.warning && !batteryController.critical && batteryController.label === "64", "charging battery uses whole-number presentation without resolving the percent-sign question");

        batteryRuntime.batteryRecord = root.battery(14.6, "discharging", "battery", -5, false);
        batteryRuntime.sequence += 1;
        batteryRuntime.stateChanged();
        root.check(batteryAdapter.timeEstimateState === "unavailable" && batteryAdapter.timeEstimateSeconds === -1, "invalid or non-credible estimate is never presented as time remaining");
        root.check(batteryController.warning && !batteryController.critical && batteryController.label === "15", "injectable warning policy uses rounded whole-number display independently of threshold comparison");
        root.check(batteryCell.effectiveLabel === "15" && batteryCell.effectiveVisible && batteryCell.effectiveEmphasis === "warning", "bar battery cell consumes normalized label, omission, and semantic severity");

        batteryRuntime.batteryRecord = root.battery(4.9, "discharging", "battery", 1800, true);
        batteryRuntime.sequence += 1;
        batteryRuntime.stateChanged();
        root.check(batteryController.critical && batteryController.severity === "critical", "critical threshold has a distinct semantic state");

        batteryRuntime.setConnected(false);
        root.check(batteryAdapter.serviceAvailability === "reconnecting" && batteryAdapter.stale && batteryController.visible, "service failure retains known battery state only as stale instead of causing layout churn");
        batteryRuntime.batteryRecord = root.battery(83, "fullyCharged", "linePower", 0, false);
        batteryRuntime.sequence += 1;
        batteryRuntime.setConnected(true);
        root.check(batteryAdapter.available && !batteryAdapter.stale && batteryAdapter.chargingState === "full", "UPower reconnect replaces stale state without shell restart");

        root.check(!brightnessAdapter.available && brightnessAdapter.targets.length === 0 && !brightnessController.visible, "no brightness backend omits the slider");
        brightnessRuntime.targetRecords = [root.target("panel-z", 200, 400), root.target("panel-a", 20, 100)];
        brightnessRuntime.setConnected(true);
        root.check(brightnessAdapter.available && brightnessAdapter.defaultTarget.id === "panel-a" && brightnessAdapter.value === 0.2, "multiple targets use deterministic selection without a hard-coded device path");
        root.check(controlCenterModel.brightnessAvailable, "control-centre brightness model consumes the shared normalized controller");

        brightnessController.consumerActive = true;
        root.check(brightnessRuntime.consumerActive, "visible detailed consumer explicitly enables runtime refresh activity");
        brightnessController.consumerActive = false;
        root.check(!brightnessRuntime.consumerActive, "hidden consumer disables periodic refresh activity");

        let result = brightnessController.setValue(2);
        root.check(result.accepted && brightnessAdapter.operationTask.state === "pending" && brightnessRuntime.lastTargetId === "panel-a" && brightnessRuntime.lastRawValue === 100, "brightness writes are bounded and remain pending until asynchronous completion");
        root.check(brightnessAdapter.value === 0.2, "pending writes do not optimistically replace authoritative state");
        brightnessRuntime.completeAction(false, "BRIGHTNESS_WRITE_FAILED");
        root.check(brightnessAdapter.operationTask.state === "failed" && brightnessAdapter.lastError === "BRIGHTNESS_WRITE_FAILED" && brightnessAdapter.value === 0.2, "write failure is truthful and retains the last authoritative value");

        result = brightnessController.adjustBySteps(1);
        root.check(result.accepted && brightnessRuntime.lastRawValue === 25, "controller applies the injected five-percent step to the selected target range");
        brightnessRuntime.completeAction(true, "");
        root.check(brightnessAdapter.operationTask.state === "completed" && brightnessAdapter.value === 0.2, "successful command completion remains distinct from delayed state observation");
        brightnessRuntime.targetRecords = [root.target("panel-a", 25, 100), root.target("panel-z", 200, 400)];
        brightnessRuntime.sequence += 1;
        brightnessRuntime.stateChanged();
        root.check(brightnessAdapter.value === 0.25, "delayed authoritative update confirms the completed write");

        brightnessRuntime.targetRecords = [root.target("panel-z", 100, 400)];
        brightnessRuntime.sequence += 1;
        brightnessRuntime.stateChanged();
        root.check(brightnessAdapter.defaultTarget.id === "panel-z" && brightnessAdapter.value === 0.25, "device disappearance atomically selects the next valid target");
        brightnessRuntime.setConnected(false);
        root.check(!brightnessAdapter.available && brightnessAdapter.stale, "brightness disconnect disables actions while retaining stale diagnostics");
        result = brightnessController.setValue(0.5);
        root.check(!result.accepted && result.errorCode === "BRIGHTNESS_DISCONNECTED", "stale brightness cannot authorize writes");
        brightnessRuntime.targetRecords = [];
        brightnessRuntime.sequence += 1;
        brightnessRuntime.setConnected(true);
        root.check(!brightnessAdapter.available && !brightnessAdapter.stale && !brightnessController.visible, "reconnect to no target intentionally omits the control");
        root.check(!controlCenterModel.brightnessAvailable, "control-centre omits brightness when the shared adapter has no target");

        console.info("PASS power-adapters: battery absence, charging, thresholds, estimates, reconnect, brightness targets, async writes, failure, delayed update, omission, and polling ownership");
        Qt.exit(0);
    }
    function target(id: string, current: int, maximum: int): var {
        return Object.freeze({
            "id": id,
            "name": id,
            "kind": "backlight",
            "minimum": 0,
            "maximum": maximum,
            "current": current
        });
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeBatteryRuntime {
        id: batteryRuntime
    }
    FakeBrightnessRuntime {
        id: brightnessRuntime
    }
    PowerServices.BatteryAdapter {
        id: batteryAdapter

        runtime: batteryRuntime
    }
    PowerServices.BrightnessAdapter {
        id: brightnessAdapter

        runtime: brightnessRuntime
    }
    PowerFeatures.BatteryController {
        id: batteryController

        adapter: batteryAdapter
        criticalPercent: 5
        showPercentSign: false
        warningPercent: 15
    }
    PowerFeatures.BrightnessController {
        id: brightnessController

        adapter: brightnessAdapter
        brightnessStep: 0.05
    }
    ControlCenter.ControlCenterPlaceholderModel {
        id: controlCenterModel

        brightnessController: brightnessController
    }
    BarFixtures.FakeBarTheme {
        id: fixtureTheme
    }
    QtObject {
        id: fixtureSurfaceCoordinator

        property var activePopover: null
        property string activePopoverId: ""
    }
    Item {
        height: 48
        width: 48

        Bar.BarFixtureCell {
            id: batteryCell

            batteryController: batteryController
            datum: Object.freeze({
                "id": "battery",
                "label": "fixture",
                "accessibleName": "Fixture battery",
                "visible": true,
                "emphasis": "metric",
                "popoverId": "fixture.battery",
                "popoverTitle": "Battery"
            })
            extent: 48
            monitorId: "fixture-monitor"
            surfaceCoordinator: fixtureSurfaceCoordinator
            theme: fixtureTheme
            vertical: true
        }
    }
}
