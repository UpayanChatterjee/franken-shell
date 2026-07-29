import "../../core" as Core
import "../../core/ConfigDefaults.js" as ConfigDefaults
import "../../core/ConfigSnapshotBuilder.js" as ConfigSnapshotBuilder
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property Core.ConfigSnapshot testedSnapshot: null

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function cloneDefaults() {
        return JSON.parse(JSON.stringify(ConfigDefaults.normalized));
    }
    function expectThrows(callback, fragment: string) {
        let thrown = false;
        try {
            callback();
        } catch (error) {
            thrown = true;
            root.check(String(error).indexOf(fragment) !== -1, "error contains '" + fragment + "': " + error);
        }
        root.check(thrown, "expected error containing '" + fragment + "'");
    }
    function fail(message: string) {
        console.error("FAIL config-snapshot:", message);
        Qt.exit(1);
    }
    function member(object, key: string) {
        return object[key];
    }

    Component.onCompleted: {
        const candidate = root.cloneDefaults();
        candidate.unknownTopLevel = "discarded";
        candidate.bar.unknownNested = "discarded";
        candidate.workspaces.numbered.semanticLabels = {
            "2": "Web",
            "1": "Code"
        };
        candidate.commands = {
            "z.last": {
                "executable": "/usr/bin/true",
                "arguments": ["--last"],
                "detached": false,
                "timeoutMs": 500,
                "environment": {}
            },
            "a.first": {
                "executable": "/usr/bin/printf",
                "arguments": ["safe", "value"],
                "detached": false,
                "timeoutMs": 250,
                "environment": {}
            }
        };
        const projected = ConfigSnapshotBuilder.build(candidate);
        root.check(Object.isFrozen(projected), "projected root is frozen");
        root.check(Object.isFrozen(projected.bar), "projected sections are frozen");
        root.check(Object.isFrozen(projected.commands.definitions), "command list is frozen");
        root.check(Object.isFrozen(projected.commands.definitions[0].arguments), "nested command arguments are frozen");
        root.check(typeof projected.unknownTopLevel === "undefined", "unknown top-level fields are projected out");
        root.check(typeof projected.bar.unknownNested === "undefined", "unknown nested fields are projected out");
        root.check(projected.commands.ids.join(",") === "a.first,z.last", "command IDs have deterministic order");
        root.check(projected.commands.definitions[0].id === "a.first", "command definitions carry their stable ID");
        const diagnostics = ConfigSnapshotBuilder.sanitizeDiagnostics([
            {
                "severity": "warning",
                "code": "UNKNOWN_FIELD",
                "message": "ignored",
                "configurationPath": "bar.unknownNested",
                "source": "fixture.toml",
                "line": 4,
                "column": 2,
                "repairHint": null,
                "rawToml": "must not escape"
            }
        ]);
        root.check(Object.isFrozen(diagnostics) && Object.isFrozen(diagnostics[0]), "sanitized diagnostics are deeply frozen");
        root.check(typeof diagnostics[0].rawToml === "undefined", "diagnostics expose only approved fields");
        const metadata = ConfigSnapshotBuilder.deepFreeze({
            "requestGeneration": 7,
            "source": "fixture",
            "sourceState": "valid",
            "migratedInMemory": false,
            "warnings": diagnostics,
            "activationSequence": 3,
            "activatedAt": "2026-07-29T00:00:00.000Z"
        });
        root.testedSnapshot = snapshotComponent.createObject(root, {
            "_source": projected,
            "_metadata": metadata
        });
        root.check(root.testedSnapshot !== null, "typed snapshot constructs");
        root.check(root.testedSnapshot.schemaVersion === 1, "schema version is typed");
        const bar = root.member(root.testedSnapshot, "bar");
        const commands = root.member(root.testedSnapshot, "commands");
        const workspaces = root.member(root.testedSnapshot, "workspaces");
        root.check(root.member(bar, "edge") === candidate.bar.edge, "nested scalar is typed");
        root.check(root.testedSnapshot.requestGeneration === 7, "metadata is typed");
        root.check(root.testedSnapshot.warnings.count === 1, "sanitized warnings are exposed");
        root.check(root.member(commands, "ids").toArray().join(",") === "a.first,z.last", "typed command IDs preserve deterministic order");
        const barLayout = root.member(bar, "layout");
        const barStart = root.member(barLayout, "start");
        const startItems = barStart.toArray();
        startItems.push("mutated");
        root.check(barStart.count === 2, "list conversion returns a detached copy");
        const specialWorkspaces = root.member(workspaces, "special");
        const firstSpecial = specialWorkspaces.at(0);
        firstSpecial.label = "mutated";
        root.check(specialWorkspaces.at(0).label === "Music", "list element access returns a detached copy");
        const numberedWorkspaces = root.member(workspaces, "numbered");
        const semanticLabelMap = root.member(numberedWorkspaces, "semanticLabels");
        const semanticLabels = semanticLabelMap.toObject();
        semanticLabels["1"] = "mutated";
        root.check(semanticLabelMap.value("1", "") === "Code", "map conversion returns a detached copy");
        const commandById = root.member(commands, "byId");
        const command = commandById("a.first");
        command.arguments.push("mutated");
        root.check(commandById("a.first").arguments.length === 2, "command lookup returns a detached copy");
        root.check(commandById("missing") === null, "unknown command lookup is explicit");
        const missingSection = root.cloneDefaults();
        delete missingSection.bar.layout;
        root.expectThrows(() => {
            return ConfigSnapshotBuilder.build(missingSection);
        }, "configuration.bar.layout is missing");
        const wrongScalar = root.cloneDefaults();
        wrongScalar.appearance.reducedMotion = "false";
        root.expectThrows(() => {
            return ConfigSnapshotBuilder.build(wrongScalar);
        }, "configuration.appearance.reducedMotion");
        const negativeInteger = root.cloneDefaults();
        negativeInteger.shell.reload.debounceMs = -1;
        root.expectThrows(() => {
            return ConfigSnapshotBuilder.build(negativeInteger);
        }, "configuration.shell.reload.debounceMs");
        const wrongSchema = root.cloneDefaults();
        wrongSchema.schemaVersion = 2;
        root.expectThrows(() => {
            return ConfigSnapshotBuilder.build(wrongSchema);
        }, "configuration.schemaVersion must equal 1");
        root.expectThrows(() => {
            return ConfigSnapshotBuilder.sanitizeDiagnostics({});
        }, "diagnostics must be an array");
        root.expectThrows(() => {
            return ConfigSnapshotBuilder.sanitizeDiagnostics([
                {
                    "severity": "warning"
                }
            ]);
        }, "diagnostic 0 is malformed");
        root.testedSnapshot.destroy();
        console.info("PASS config-snapshot: projection, typing, and immutability contracts");
        exitTimer.start();
    }

    Timer {
        id: exitTimer

        interval: 0

        onTriggered: Qt.quit()
    }
    Component {
        id: snapshotComponent

        Core.ConfigSnapshot {
        }
    }
}
