import "../../features/bar" as Bar
import "../../features/telemetry" as TelemetryFeatures
import "../../services/telemetry" as TelemetryServices
import "../../services/telemetry/ResourceCommandDefinitions.js" as ResourceCommands
import "../../services/telemetry/ThroughputMath.js" as ThroughputMath
import "../bar_host" as BarFixtures
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function counters(received: real, transmitted: real): var {
        return Object.freeze({
            "eth0": Object.freeze({
                "received": received,
                "transmitted": transmitted
            })
        });
    }
    function fail(message: string) {
        console.error("FAIL telemetry-adapters:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function memory(totalKiB: int, availableKiB: int): string {
        return "MemTotal:       " + totalKiB + " kB\nMemAvailable:   " + availableKiB + " kB\n";
    }
    function network(records): string {
        let output = "Inter-| Receive | Transmit\n face |bytes packets errs drop fifo frame compressed multicast|bytes packets errs drop fifo colls carrier compressed\n";
        for (const record of records)
            output += record.name + ": " + record.rx + " 0 0 0 0 0 0 0 " + record.tx + " 0 0 0 0 0 0 0\n";
        return output;
    }
    function run() {
        const storageCommand = ResourceCommands.definitions()[0];
        root.check(storageCommand.executable === "df" && storageCommand.runtimeArgumentPolicy === "none" && storageCommand.arguments.join(" ") === "--block-size=1 --output=size,used,target /", "storage sampling uses one fixed trusted command without view-owned or runtime arguments");
        root.check(!throughputAdapter.available && !resourceAdapter.available, "missing proc data starts unavailable without fabricated zero metrics");
        runtime.setConnected(true);

        runtime.publish(1000, root.network([
            {
                name: "eth0",
                rx: 1000,
                tx: 500
            },
            {
                name: "wlan0",
                rx: 2000,
                tx: 1000
            }
        ]), root.memory(1000, 400), "cpu 100 0 0 900 0 0 0 0\n", "1B-blocks Used Mounted on\n1000 250 /\n");
        root.check(throughputAdapter.available && throughputAdapter.activeInterfaceCount === 2 && throughputController.formattedDownload === "0K", "first aggregate sample establishes a zero-rate baseline across Ethernet and Wi-Fi");
        root.check(resourceAdapter.available && resourceAdapter.memoryPercent === 60 && resourceController.label === "60", "memory summary uses MemAvailable and presents a whole-number RAM value");
        root.check(resourceAdapter.storage !== null && resourceAdapter.storage.percent === 25, "root storage summary parses independently of optional sensors");
        root.check(resourceAdapter.cpuPercent === -1, "first CPU counter sample is a baseline rather than fabricated usage");

        runtime.publish(2000, root.network([
            {
                name: "wlan0",
                rx: 4000,
                tx: 1300
            },
            {
                name: "eth0",
                rx: 2000,
                tx: 700
            }
        ]), root.memory(1000, 400), "cpu 150 0 0 950 0 0 0 0\n", "1B-blocks Used Mounted on\n1000 250 /\n");
        root.check(throughputAdapter.rawDownloadRate === 3000 && throughputAdapter.rawUploadRate === 500, "Wi-Fi and Ethernet deltas aggregate independently of interface order");
        root.check(resourceAdapter.cpuPercent === 50, "CPU usage derives from bounded aggregate counter deltas");

        const introduced = ThroughputMath.rates(root.counters(1000, 100), Object.freeze(Object.assign({}, root.counters(1500, 200), {
            "wlan0": Object.freeze({
                "received": 9000000,
                "transmitted": 8000000
            })
        })), 1000);
        root.check(introduced.download === 500 && introduced.upload === 100 && introduced.sampledInterfaceCount === 1, "a newly appearing interface is baselined and cannot create a rate spike");
        const disappeared = ThroughputMath.rates(Object.freeze(Object.assign({}, root.counters(1000, 100), {
            "wlan0": Object.freeze({
                "received": 2000,
                "transmitted": 300
            })
        })), root.counters(1500, 200), 1000);
        root.check(disappeared.download === 500 && disappeared.upload === 100 && disappeared.sampledInterfaceCount === 1, "a disappearing interface does not invalidate remaining interface deltas");
        const reset = ThroughputMath.rates(root.counters(1000, 500), root.counters(20, 10), 1000);
        root.check(reset.download === 0 && reset.upload === 0, "ordinary counter reset is treated as a new baseline");
        const wrapped = ThroughputMath.rates(root.counters(4294967200, 4294967200), root.counters(50, 100), 1000);
        root.check(wrapped.download === 146 && wrapped.upload === 196, "32-bit counter wrap is bounded without a negative or enormous sample");
        const idle = ThroughputMath.rates(root.counters(50, 100), root.counters(50, 100), 1000);
        root.check(idle.download === 0 && idle.upload === 0, "zero traffic remains an authoritative zero sample");
        let history = ThroughputMath.appendBounded(Object.freeze([]), 1000, 2);
        history = ThroughputMath.appendBounded(history, 3000, 2);
        history = ThroughputMath.appendBounded(history, 5000, 2);
        root.check(history.length === 2 && ThroughputMath.average(history) === 4000, "moving-average smoothing retains only the configured bounded window");
        root.check(ThroughputMath.compactRate(0, "bytes", 1000, "0K") === "0K" && ThroughputMath.compactRate(3000, "bytes", 1000, "0K") === "3K" && ThroughputMath.compactRate(2e15, "bytes", 1000, "0K") === "2P", "compact formatter covers zero through very large units with whole numbers");

        runtime.publish(3000, "", "", "", "", {
            network: "NETWORK_READ_FAILED",
            memory: "MEMORY_READ_FAILED",
            storage: "STORAGE_SAMPLE_FAILED"
        });
        root.check(throughputAdapter.available && throughputAdapter.stale && resourceAdapter.available && resourceAdapter.stale, "one failed sample briefly retains last-known-good values as stale");
        runtime.publish(4000, "", "", "", "", {
            network: "NETWORK_READ_FAILED",
            memory: "MEMORY_READ_FAILED",
            storage: "STORAGE_SAMPLE_FAILED"
        });
        root.check(!throughputAdapter.available && throughputController.formattedDownload === "–" && !resourceAdapter.available && resourceController.label === "–", "persistent missing proc data becomes explicit unavailable state instead of false zero");

        resourceController.detailVisible = true;
        root.check(runtime.detailActive && runtime.pollIntervalMs === 1000, "visible detail consumer explicitly selects elevated polling");
        resourceController.detailVisible = false;
        root.check(!runtime.detailActive && runtime.pollIntervalMs === 2000, "hidden detail consumer returns to low-frequency polling");

        runtime.publish(5000, root.network([
            {
                name: "eth0",
                rx: 20,
                tx: 10
            }
        ]), root.memory(2000, 500), "cpu 200 0 0 1000 0 0 0 0\n", "");
        root.check(throughputAdapter.available && resourceAdapter.available && !throughputAdapter.stale && !resourceAdapter.stale, "valid data recovers both adapters without a shell restart");
        root.check(networkCell.effectiveLabel === throughputController.formattedDownload && resourceCell.effectiveLabel === "75" && networkCell.width === resourceCell.width, "persistent bar cells consume live formatted metrics while preserving fixed extent from 0K through large units");

        console.info("PASS telemetry-adapters: aggregation, counter reset/wrap, smoothing inputs, formatting, resource summaries, missing data, recovery, bounded polling, and fixed bar layout");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeTelemetryRuntime {
        id: runtime
    }
    TelemetryServices.ThroughputAdapter {
        id: throughputAdapter

        runtime: runtime
        smoothingWindow: 1
    }
    TelemetryServices.ResourceSummaryAdapter {
        id: resourceAdapter

        runtime: runtime
    }
    TelemetryFeatures.ThroughputController {
        id: throughputController

        adapter: throughputAdapter
    }
    TelemetryFeatures.ResourceSummaryController {
        id: resourceController

        adapter: resourceAdapter
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
        width: 96

        Bar.BarFixtureCell {
            id: networkCell

            datum: Object.freeze({
                "id": "networkSpeed",
                "label": "fixture",
                "accessibleName": "Fixture throughput",
                "visible": true,
                "emphasis": "metric",
                "popoverId": "",
                "popoverTitle": ""
            })
            extent: 48
            monitorId: "fixture-monitor"
            surfaceCoordinator: fixtureSurfaceCoordinator
            theme: fixtureTheme
            throughputController: throughputController
            vertical: false
        }
        Bar.BarFixtureCell {
            id: resourceCell

            datum: Object.freeze({
                "id": "resources",
                "label": "fixture",
                "accessibleName": "Fixture memory",
                "visible": true,
                "emphasis": "metric",
                "popoverId": "fixture.resources",
                "popoverTitle": "Resources"
            })
            extent: 48
            monitorId: "fixture-monitor"
            resourceController: resourceController
            surfaceCoordinator: fixtureSurfaceCoordinator
            theme: fixtureTheme
            throughputController: throughputController
            vertical: false
            x: 48
        }
    }
}
