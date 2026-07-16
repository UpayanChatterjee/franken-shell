import "../../core" as Core
import "../../core/MonitorNormalization.js" as MonitorNormalization
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int stage: -1
    property int addedCount: 0
    property int updatedCount: 0
    property int removedCount: 0
    property string firstRuntimeId: ""
    property string secondRuntimeId: ""
    property var firstRecord: null
    property var secondRecord: null
    property var firstScreenRef: null
    property int revisionBefore: 0
    property int addedBefore: 0
    property int removedBefore: 0
    property double deadline: 0

    function fail(message: string) {
        console.error("FAIL monitor-registry:", message);
        Qt.exit(1);
        throw new Error(message);
    }

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }

    function pass(name: string) {
        console.info("PASS monitor-registry:", name);
    }

    function waitForStage(stageValue: int, timeoutMs: int) {
        root.stage = stageValue;
        root.deadline = Date.now() + timeoutMs;
        stageTimer.restart();
    }

    function screen(name, values) {
        return Object.assign({
            ref: {},
            mappedMonitorRef: null,
            name: name,
            model: "Panel",
            serialNumber: "serial-" + name,
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
            devicePixelRatio: 1
        }, values ?? {});
    }

    function monitor(name, values) {
        const result = Object.assign({
            ref: {},
            id: 0,
            name: name,
            description: "Vendor Panel",
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
            scale: 1,
            focused: false,
            raw: {
                name: name,
                model: "Panel",
                serial: "serial-" + name,
                transform: 0
            },
            activeWorkspace: {
                id: 1,
                hasFullscreen: false
            }
        }, values ?? {});
        result.raw = Object.assign({
            name: result.name,
            model: "Panel",
            serial: "serial-" + result.name,
            transform: 0
        }, values?.raw ?? {});
        return result;
    }

    function snapshot(screens, monitors, values) {
        return Object.assign({
            screens: screens,
            hyprlandMonitors: monitors,
            focusedMonitorRef: null,
            focusedMonitorId: -1,
            focusedWindowMonitorRef: null,
            focusedWindowMonitorId: -1,
            backendAvailability: "fixture"
        }, values ?? {});
    }

    function normalize(screens, monitors, configuration, values) {
        return MonitorNormalization.normalize(
            root.snapshot(screens, monitors, values),
            configuration ?? {
                barEnabled: true,
                barEdge: "left",
                _provisionalMonitorRules: []
            }
        );
    }

    function runNormalizationFixtures() {
        {
            const hypr = root.monitor("eDP-1");
            const qt = root.screen("eDP-1", {
                mappedMonitorRef: hypr.ref
            });
            const result = root.normalize([qt], [hypr]);
            root.check(result.records.length === 1, "normal mapping count");
            root.check(result.records[0].mappingHealth === "mapped", "normal mapping health");
            root.check(result.records[0].logicalGeometry.coordinateSpace === "qtDeviceIndependentPixels", "Qt logical coordinate space");
            root.check(result.mappingErrors.indexOf("focusedMonitorUnavailable") >= 0, "missing focus is diagnosed");
            root.pass("one normally mapped monitor");
        }
        {
            const first = root.monitor("DP-1", {
                id: 1
            });
            const second = root.monitor("HDMI-A-1", {
                id: 2,
                x: 1920
            });
            const result = root.normalize([
                root.screen("DP-1", {
                    mappedMonitorRef: first.ref
                }),
                root.screen("HDMI-A-1", {
                    mappedMonitorRef: second.ref,
                    x: 1920
                })
            ], [first, second]);
            root.check(result.records.length === 2 && result.records.every(record => record.mappingHealth === "mapped"), "multiple monitor mapping");
            root.pass("multiple monitors");
        }
        {
            const first = root.monitor("DP-1", {
                id: 1,
                scale: 1
            });
            const second = root.monitor("DP-2", {
                id: 2,
                x: 1920,
                width: 2560,
                height: 1440,
                scale: 2
            });
            const result = root.normalize([
                root.screen("DP-1", {
                    mappedMonitorRef: first.ref
                }),
                root.screen("DP-2", {
                    mappedMonitorRef: second.ref,
                    x: 1920,
                    width: 1280,
                    height: 720,
                    devicePixelRatio: 2
                })
            ], [first, second]);
            root.check(result.records[0].scale === 1 && result.records[1].scale === 2, "mixed compositor scales");
            root.check(result.records[1].devicePixelRatio === 2, "mixed Qt device pixel ratio");
            root.pass("mixed scales");
        }
        {
            const rotated = root.monitor("DP-1", {
                width: 1920,
                height: 1080,
                raw: {
                    transform: 1
                }
            });
            const result = root.normalize([], [rotated]);
            root.check(result.records[0].transform === "rotate90CounterClockwise", "rotated transform name");
            root.check(result.records[0].logicalGeometry.width === 1080 && result.records[0].logicalGeometry.height === 1920, "rotated axes");
            root.check(result.records[0].orientation === "portrait", "rotated orientation");
            root.pass("rotated transforms");
        }
        {
            const names = [
                "normal",
                "rotate90CounterClockwise",
                "rotate180",
                "rotate270CounterClockwise",
                "flipped",
                "flipped90CounterClockwise",
                "flipped180",
                "flipped270CounterClockwise"
            ];
            for (let code = 0; code < names.length; code++) {
                const transform = MonitorNormalization.transformForCode(code);
                root.check(transform.name === names[code], "transform name " + code);
                root.check(transform.flipped === (code >= 4), "transform flipped state " + code);
                root.check(transform.swapsAxes === [1, 3, 5, 7].includes(code), "transform axis state " + code);
            }
            root.pass("flipped transforms");
        }
        {
            const result = root.normalize([root.screen("DP-1")], []);
            root.check(result.records[0].mappingHealth === "screenOnly", "screen before Hyprland data");
            root.pass("Qt screen before Hyprland data");
        }
        {
            const result = root.normalize([], [root.monitor("DP-1")]);
            root.check(result.records[0].mappingHealth === "hyprlandOnly", "Hyprland before screen");
            root.pass("Hyprland data before Qt screen");
        }
        {
            const one = root.monitor("DP-1", {
                id: 1,
                raw: {
                    serial: "",
                    model: ""
                }
            });
            const two = root.monitor("DP-1", {
                id: 2,
                raw: {
                    serial: "",
                    model: ""
                }
            });
            const result = root.normalize([
                root.screen("DP-1", {
                    serialNumber: "",
                    model: ""
                })
            ], [one, two], null, {
                focusedMonitorRef: one.ref,
                focusedMonitorId: 1,
                focusedMonitorName: "DP-1"
            });
            root.check(result.records[0].mappingHealth === "ambiguous", "duplicate connector ambiguity");
            root.check(result.records.filter(record => record.focused).length === 1, "duplicate names do not duplicate focused state");
            root.check(result.records.every(record => record._identityKeys.every(key => !key.startsWith("connector-model:"))), "duplicate connector/model is not an identity key");
            root.pass("duplicate connector names and ambiguous mapping");
        }
        {
            const hypr = root.monitor("DP-1", {
                description: "",
                raw: {
                    serial: "",
                    model: ""
                }
            });
            const result = root.normalize([
                root.screen("DP-1", {
                    mappedMonitorRef: hypr.ref,
                    serialNumber: "",
                    model: ""
                })
            ], [hypr]);
            root.check(result.records[0].serial === "" && result.records[0].model === "", "missing identity fields retained");
            root.check(result.records[0].mappingHealth === "mapped", "missing metadata does not prevent unique connector mapping");
            root.pass("missing serial and model information");
        }
        {
            const hypr = root.monitor("DP-1", {
                activeWorkspace: {
                    id: 7,
                    hasFullscreen: true
                }
            });
            const result = root.normalize([], [hypr]);
            root.check(result.records[0].activeWorkspaceId === 7 && result.records[0].fullscreenActive, "workspace fullscreen state");
            root.pass("per-monitor fullscreen state");
        }
        {
            const hypr = root.monitor("DP-1", {
                raw: {
                    maximized: true
                },
                activeWorkspace: {
                    id: 1,
                    hasFullscreen: false
                }
            });
            const result = root.normalize([], [hypr]);
            root.check(!result.records[0].fullscreenActive, "maximized does not imply fullscreen");
            root.pass("maximized state not treated as fullscreen");
        }
        {
            const result = root.normalize([], [root.monitor("DP-1")], {
                barEnabled: true,
                barEdge: "left",
                _provisionalMonitorRules: []
            });
            root.check(result.records[0].configured && result.records[0].barEnabled && result.records[0].configuredBarEdge === "left", "defaults-only configuration");
            root.pass("ConfigService defaults-only state");
        }
        {
            const result = root.normalize([], [root.monitor("DP-1")], {
                barEnabled: true,
                barEdge: "left",
                monitorRules: [{
                    match: {
                        connector: "DP-1"
                    },
                    barEnabled: false
                }],
                _provisionalMonitorRules: [{
                    match: {
                        name: "DP-1"
                    },
                    bar: {
                        enabled: false,
                        edge: "right"
                    }
                }]
            });
            root.check(!result.records[0].barEnabled && result.records[0].configuredBarEdge === "right", "only documented provisional monitor rule shape is accepted");
            root.pass("private provisional monitor rules");
        }
    }

    function runStage() {
        if (Date.now() > root.deadline)
            root.fail("timed out at lifecycle stage " + root.stage);

        switch (root.stage) {
        case 0:
            if (registry.monitors.length !== 1)
                break;
            root.firstRuntimeId = registry.monitors[0].runtimeId;
            root.firstRecord = registry.monitors[0];
            root.firstScreenRef = backend.currentSnapshot.screens[0].ref;
            root.check(registry.focusedMonitor === registry.monitors[0], "focused monitor selector");
            root.check(registry.focusedWindowMonitor === registry.monitors[0], "focused-window monitor selector");
            root.check(registry.fallbackMonitor === registry.monitors[0], "initial fallback");
            root.check(registry.fullscreenOnMonitor(root.firstRuntimeId), "fullscreen lookup");
            root.check(typeof registry.monitors[0].state._screenRef === "undefined"
                && typeof registry.monitors[0].state._hyprlandRef === "undefined", "normalized record state excludes backend references");
            root.revisionBefore = registry.revision;
            root.addedBefore = root.addedCount;
            root.removedBefore = root.removedCount;
            backend.publish(backend.currentSnapshot);
            backend.publish(backend.currentSnapshot);
            backend.publish(backend.currentSnapshot);
            root.waitForStage(1, 1000);
            return;
        case 1:
            if (registry.revision <= root.revisionBefore)
                break;
            root.check(registry.revision === root.revisionBefore + 1, "rapid backend signals coalesce to one refresh");
            root.check(registry.monitors.length === 1, "repeated refresh has no duplicates");
            root.check(registry.monitors[0].runtimeId === root.firstRuntimeId, "runtime id stable across repeated refresh");
            root.check(registry.monitors[0] === root.firstRecord, "unchanged MonitorRecord object is reused");
            root.check(root.addedCount === root.addedBefore && root.removedCount === root.removedBefore, "repeated refresh emits no add/remove cycle");
            root.pass("repeated refresh without duplicate records");
            root.revisionBefore = registry.revision;
            const second = root.monitor("HDMI-A-1", {
                id: 2,
                x: 1920,
                focused: false,
                activeWorkspace: {
                    id: 2,
                    hasFullscreen: false
                }
            });
            const secondScreen = root.screen("HDMI-A-1", {
                mappedMonitorRef: second.ref,
                x: 1920
            });
            backend.publish(root.snapshot(
                backend.currentSnapshot.screens.concat([secondScreen]),
                backend.currentSnapshot.hyprlandMonitors.concat([second]),
                {
                    focusedMonitorRef: backend.currentSnapshot.hyprlandMonitors[0].ref,
                    focusedWindowMonitorRef: backend.currentSnapshot.hyprlandMonitors[0].ref
                }
            ));
            root.waitForStage(2, 1000);
            return;
        case 2:
            if (registry.monitors.length !== 2)
                break;
            root.secondRuntimeId = registry.monitors[1].runtimeId;
            root.secondRecord = registry.monitors[1];
            root.check(root.addedCount === root.addedBefore + 1, "one added event for hotplug");
            root.check(root.secondRuntimeId !== root.firstRuntimeId, "hotplug runtime id unique");
            root.pass("monitor hotplug");
            root.revisionBefore = registry.revision;
            const updatedSecond = Object.assign({}, backend.currentSnapshot.hyprlandMonitors[1], {
                raw: Object.assign({}, backend.currentSnapshot.hyprlandMonitors[1].raw, {
                    transform: 5
                })
            });
            backend.publish(root.snapshot(
                backend.currentSnapshot.screens,
                [backend.currentSnapshot.hyprlandMonitors[0], updatedSecond],
                {
                    focusedMonitorRef: backend.currentSnapshot.hyprlandMonitors[0].ref,
                    focusedWindowMonitorRef: backend.currentSnapshot.hyprlandMonitors[0].ref
                }
            ));
            root.waitForStage(3, 1000);
            return;
        case 3:
            if (registry.revision <= root.revisionBefore || registry.monitors[1].transformCode !== 5)
                break;
            root.check(registry.monitors[1].runtimeId === root.secondRuntimeId, "transform update preserves identity");
            root.check(root.updatedCount > 0, "updated event emitted");
            root.pass("stale transform refresh");
            root.revisionBefore = registry.revision;
            fakeConfig.active = {
                bar: {
                    enabled: false,
                    edge: "bottom"
                }
            };
            fakeConfig.activated(fakeConfig.active);
            root.waitForStage(4, 1000);
            return;
        case 4:
            if (registry.revision <= root.revisionBefore || registry.monitors[0].configuredBarEdge !== "bottom")
                break;
            root.check(registry.monitors.every(record => !record.barEnabled), "configuration bar enablement update");
            root.check(registry.monitors.every(record => record.configuredBarEdge === "bottom"), "configuration bar edge update");
            root.check(registry.monitors[0].runtimeId === root.firstRuntimeId, "config update preserves monitor identity");
            root.check(registry.monitors[0] === root.firstRecord && registry.monitors[1] === root.secondRecord, "config update reuses existing MonitorRecord objects");
            root.pass("configuration update affecting bar edge and enablement");
            root.revisionBefore = registry.revision;
            root.removedBefore = root.removedCount;
            const survivingScreen = backend.currentSnapshot.screens[1];
            const survivingMonitor = Object.assign({}, backend.currentSnapshot.hyprlandMonitors[1], {
                focused: true
            });
            backend.publish(root.snapshot([survivingScreen], [survivingMonitor], {
                focusedMonitorRef: survivingMonitor.ref,
                focusedWindowMonitorRef: survivingMonitor.ref
            }));
            root.waitForStage(5, 1000);
            return;
        case 5:
            if (registry.monitors.length !== 1 || registry.revision <= root.revisionBefore)
                break;
            root.check(root.removedCount === root.removedBefore + 1, "removed event emitted exactly once");
            root.check(registry.monitorByRuntimeId(root.firstRuntimeId) === null, "removed monitor lookup cleared");
            root.check(registry.monitorForScreen(root.firstScreenRef) === null, "removed Qt screen reference cleared");
            root.check(registry.monitorForScreen(backend.currentSnapshot.screens[0].ref) === registry.monitors[0], "screen lookup has no stale reference");
            root.check(registry.fallbackMonitor.runtimeId === root.secondRuntimeId, "fallback replaced after removal");
            root.check(registry.focusedMonitor.runtimeId === root.secondRuntimeId, "focused replacement normalized");
            root.check(registry.monitors[0] === root.secondRecord, "surviving MonitorRecord object is retained");
            root.pass("monitor removal and focused/fallback replacement");
            root.revisionBefore = registry.revision;
            root.removedBefore = root.removedCount;
            root.addedBefore = root.addedCount;
            backend.publish(backend.currentSnapshot);
            root.waitForStage(6, 1000);
            return;
        case 6:
            if (registry.revision <= root.revisionBefore)
                break;
            root.check(root.removedCount === root.removedBefore, "removed event is not repeated");
            root.check(root.addedCount === root.addedBefore, "post-removal refresh emits no add event");
            root.check(registry.monitors[0] === root.secondRecord, "post-removal refresh reuses survivor");
            const diagnostics = registry.diagnosticsSummary();
            const serialized = JSON.stringify(diagnostics);
            root.check(diagnostics.connectedMonitorCount === 1 && diagnostics.mappedMonitorCount === 1, "diagnostic counts");
            root.check(serialized.indexOf("serial-HDMI-A-1") === -1 && serialized.indexOf("Vendor Panel") === -1, "diagnostics omit serial and description");
            root.check(diagnostics.transforms[0].transform === "flipped90CounterClockwise", "diagnostic transform state");
            root.pass("sanitized diagnostics");
            console.info("PASS monitor-registry: all fixtures");
            Qt.exit(0);
            return;
        }
        stageTimer.restart();
    }

    QtObject {
        id: fakeConfig

        property var active: ({
            bar: {
                enabled: true,
                edge: "left"
            }
        })
        signal activated(var snapshot)
    }

    FakeMonitorBackend {
        id: backend
    }

    Core.MonitorRegistry {
        id: registry

        backend: backend
        configService: fakeConfig
    }

    Connections {
        target: registry

        function onAdded(monitor) {
            void monitor;
            root.addedCount += 1;
        }

        function onUpdated(monitor, changedFields) {
            void monitor;
            void changedFields;
            root.updatedCount += 1;
        }

        function onRemoved(runtimeId, lastState) {
            void runtimeId;
            root.check(lastState.connected === false, "removed event marks disconnected");
            root.removedCount += 1;
        }
    }

    Timer {
        id: stageTimer

        interval: 10
        onTriggered: root.runStage()
    }

    Component.onCompleted: {
        root.runNormalizationFixtures();
        const first = root.monitor("eDP-1", {
            id: 1,
            focused: true,
            activeWorkspace: {
                id: 1,
                hasFullscreen: true
            }
        });
        const firstScreen = root.screen("eDP-1", {
            mappedMonitorRef: first.ref
        });
        backend.publish(root.snapshot([firstScreen], [first], {
            focusedMonitorRef: first.ref,
            focusedWindowMonitorRef: first.ref
        }));
        root.waitForStage(0, 1000);
    }
}
