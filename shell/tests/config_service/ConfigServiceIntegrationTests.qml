import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core

ShellRoot {
    id: root

    property int step: 0
    property int activationCount: 0
    property var previousSnapshot: null
    property double previousGeneration: -1
    property double previousRejectedGeneration: -1
    property var writeCallback: null
    property var waitCondition: null
    property var waitCallback: null
    property double waitDeadline: 0

    readonly property string fixturePath: String(
        Quickshell.env("FRANKEN_CONFIG_FIXTURE_PATH") ?? ""
    )
    readonly property string fixtureDirectory: String(
        Quickshell.env("FRANKEN_CONFIG_FIXTURE_DIRECTORY") ?? ""
    )

    function fail(message: string) {
        console.error("FAIL config-service-integration:", message);
        Qt.exit(1);
    }

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }

    function pass(name: string) {
        console.info("PASS config-service-integration:", name);
    }

    function waitUntil(condition, callback, timeoutMs: int) {
        root.waitCondition = condition;
        root.waitCallback = callback;
        root.waitDeadline = Date.now() + timeoutMs;
        waitTimer.restart();
    }

    function fixtureText(name: string): string {
        if (name === "malformed.toml")
            return malformedFixture.text();
        if (name === "complete_valid.toml")
            return completeFixture.text();
        if (name === "missing_optional.toml")
            return partialFixture.text();
        if (name === "unknown_field.toml")
            return unknownFixture.text();
        if (name === "schema_zero.toml")
            return schemaZeroFixture.text();
        if (name === "newer_schema.toml")
            return newerFixture.text();
        root.fail("unknown fixture " + name);
        return "";
    }

    function writeFixture(name: string, callback) {
        root.writeCallback = () => {
            service.requestReload();
            callback();
        };
        writer.setText(root.fixtureText(name));
    }

    function next() {
        root.step += 1;
        actionTimer.restart();
    }

    function runStep() {
        switch (root.step) {
        case 0:
            root.waitUntil(
                () => service.reloadState === "idle",
                () => {
                    root.check(service.activeGeneration === 0, "defaults generation");
                    root.check(service.health === "healthy", "missing file health");
                    root.check(service.sourceState === "defaultsOnly", "missing file state");
                    root.pass("real helper not required for missing file");
                    root.next();
                },
                3000
            );
            break;
        case 1:
            root.writeFixture("malformed.toml", () => {
                root.waitUntil(
                    () => service.health === "degraded"
                        && service.lastRejectedGeneration > 0,
                    () => {
                        root.check(service.activeGeneration === 0, "cold invalid keeps defaults");
                        root.check(service.errorCount > 0, "cold invalid diagnostics");
                        root.check(
                            service.sourceState === "invalidColdStart",
                            "cold invalid source state"
                        );
                        root.check(
                            service.errors[0].code === "CONFIG_TOML_PARSE_ERROR",
                            "cold invalid error code"
                        );
                        root.pass("malformed cold start");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 2:
            root.writeFixture("complete_valid.toml", () => {
                root.waitUntil(
                    () => service.health === "healthy"
                        && service.active.bar.edge === "bottom",
                    () => {
                        const snapshot = service.active;
                        root.check(snapshot.shell.language === "en-IN", "typed shell");
                        root.check(snapshot.appearance.font.family === "Inter", "typed appearance");
                        root.check(snapshot.controlCenter.width === 400, "typed control center");
                        root.check(snapshot.workspaces.special.count === 2, "typed workspaces");
                        root.check(
                            snapshot.workspaces.special.at(0).id === "music",
                            "stable workspace ID"
                        );
                        root.check(
                            snapshot.integrations.vicinae.extensionEnabled,
                            "typed integrations"
                        );
                        const command = snapshot.commands.byId("vicinae.root");
                        root.check(command !== null, "typed command definition");
                        root.check(command.executable === "vicinae", "command executable");
                        root.check(command.arguments[0] === "toggle", "command argument array");
                        command.arguments.push("mutated");
                        root.check(
                            snapshot.commands.byId("vicinae.root").arguments.length === 1,
                            "command lookup returns detached immutable data"
                        );
                        const summary = JSON.stringify(service.configurationSummary());
                        root.check(summary.indexOf("toggle") === -1, "IPC omits command args");
                        root.check(summary.indexOf("tomlSource") === -1, "IPC omits TOML");
                        root.check(
                            summary.indexOf("normalizedConfiguration") === -1,
                            "IPC omits normalized config"
                        );
                        root.pass("complete typed user snapshot and privacy");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 3:
            root.previousSnapshot = service.active;
            root.previousGeneration = service.activeGeneration;
            root.previousRejectedGeneration = service.lastRejectedGeneration;
            root.writeFixture("malformed.toml", () => {
                root.waitUntil(
                    () => service.lastRejectedGeneration
                        > root.previousRejectedGeneration,
                    () => {
                        root.check(service.active === root.previousSnapshot, "hot invalid retains");
                        root.check(
                            service.activeGeneration === root.previousGeneration,
                            "hot invalid generation retained"
                        );
                        root.pass("real-helper invalid hot reload");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 4:
            root.writeFixture("missing_optional.toml", () => {
                root.waitUntil(
                    () => service.health === "healthy"
                        && service.activeGeneration > root.previousGeneration,
                    () => {
                        root.check(service.active.bar.edge === "left", "partial helper default");
                        root.check(
                            service.active.workspaces.special.count === 6,
                            "partial workspace defaults"
                        );
                        root.check(service.active.commands.ids.count === 0, "partial commands");
                        root.pass("partial file helper defaults and recovery");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 5:
            root.writeFixture("unknown_field.toml", () => {
                root.waitUntil(
                    () => service.health === "healthy" && service.warningCount > 0,
                    () => {
                        root.check(
                            service.warnings[0].code === "CONFIG_UNKNOWN_FIELD",
                            "unknown field warning"
                        );
                        root.check(service.active.warnings.count > 0, "snapshot warning metadata");
                        root.pass("unknown-field warning activation");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 6:
            root.writeFixture("schema_zero.toml", () => {
                root.waitUntil(
                    () => service.health === "healthy"
                        && service.active.migratedInMemory,
                    () => {
                        root.check(service.active.bar.edge === "right", "migrated typed value");
                        root.check(service.migrationInMemory, "migration status");
                        root.check(service.warningCount > 0, "migration warning");
                        root.pass("schema-zero in-memory migration");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 7:
            root.previousSnapshot = service.active;
            root.previousGeneration = service.activeGeneration;
            root.previousRejectedGeneration = service.lastRejectedGeneration;
            root.writeFixture("newer_schema.toml", () => {
                root.waitUntil(
                    () => service.lastRejectedGeneration
                        > root.previousRejectedGeneration,
                    () => {
                        root.check(service.active === root.previousSnapshot, "newer retains");
                        root.check(
                            service.activeGeneration === root.previousGeneration,
                            "newer generation retained"
                        );
                        root.check(
                            service.errors[0].code === "CONFIG_SCHEMA_TOO_NEW",
                            "newer schema diagnostic"
                        );
                        root.pass("newer unsupported schema rejection");
                        root.next();
                    },
                    5000
                );
            });
            break;
        case 8:
            root.writeFixture("missing_optional.toml", () => {
                root.waitUntil(
                    () => service.health === "healthy"
                        && service.activeGeneration > root.previousGeneration,
                    () => {
                        root.check(!service.migrationInMemory, "migration state cleared");
                        root.check(service.errorCount === 0, "later valid clears errors");
                        root.pass("healthy again after newer-schema rejection");
                        root.next();
                    },
                    5000
                );
            });
            break;
        default:
            console.info("PASS config-service-integration: all fixtures");
            Qt.quit();
        }
    }

    Core.ConfigHelperClient {
        id: helperClient

        timeoutMs: 3000
    }

    Core.ConfigService {
        id: service

        helperClient: helperClient
        onActivated: snapshot => {
            root.activationCount += 1;
            root.check(service.active === snapshot, "atomic active reference");
            root.check(snapshot.schemaVersion === 1, "complete schema version");
            root.check(snapshot.shell !== null && snapshot.commands !== null, "complete sections");
        }
    }

    FileView {
        id: malformedFixture

        path: root.fixtureDirectory + "/malformed.toml"
        blockLoading: true
        printErrors: true
    }

    FileView {
        id: completeFixture

        path: root.fixtureDirectory + "/complete_valid.toml"
        blockLoading: true
        printErrors: true
    }

    FileView {
        id: partialFixture

        path: root.fixtureDirectory + "/missing_optional.toml"
        blockLoading: true
        printErrors: true
    }

    FileView {
        id: unknownFixture

        path: root.fixtureDirectory + "/unknown_field.toml"
        blockLoading: true
        printErrors: true
    }

    FileView {
        id: schemaZeroFixture

        path: root.fixtureDirectory + "/schema_zero.toml"
        blockLoading: true
        printErrors: true
    }

    FileView {
        id: newerFixture

        path: root.fixtureDirectory + "/newer_schema.toml"
        blockLoading: true
        printErrors: true
    }

    FileView {
        id: writer

        path: root.fixturePath
        preload: false
        blockWrites: true
        atomicWrites: true
        printErrors: true

        onSaved: {
            const callback = root.writeCallback;
            root.writeCallback = null;
            if (callback !== null)
                callback();
        }
        onSaveFailed: error => root.fail(
            "fixture write failed: " + FileViewError.toString(error)
        )
    }

    Timer {
        id: actionTimer

        interval: 0
        repeat: false
        onTriggered: root.runStep()
    }

    Timer {
        id: waitTimer

        interval: 20
        repeat: false
        onTriggered: {
            if (root.waitCondition !== null && root.waitCondition()) {
                const callback = root.waitCallback;
                root.waitCondition = null;
                root.waitCallback = null;
                callback();
            } else if (Date.now() >= root.waitDeadline) {
                root.fail("timed out at step " + root.step);
            } else {
                waitTimer.restart();
            }
        }
    }

    Component.onCompleted: {
        if (root.fixturePath.length === 0 || root.fixtureDirectory.length === 0) {
            root.fail("fixture path and directory are required");
            return;
        }
        actionTimer.restart();
    }
}
