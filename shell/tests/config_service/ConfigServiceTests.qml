import "../../core" as Core
import "../../core/ConfigPathResolver.js" as ConfigPathResolver
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property int step: 0
    property int activationCount: 0
    property int rejectionCount: 0
    property var previousSnapshot: null
    property double previousGeneration: -1
    property int requestsBefore: 0
    property int activationsBefore: 0
    property var writeCallback: null
    property var waitCondition: null
    property var waitCallback: null
    property double waitDeadline: 0
    readonly property string fixturePath: String(Quickshell.env("FRANKEN_CONFIG_FIXTURE_PATH") ?? "")

    function fail(message: string) {
        console.error("FAIL config-service:", message);
        Qt.exit(1);
    }

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);

    }

    function pass(name: string) {
        console.info("PASS config-service:", name);
    }

    function waitUntil(condition, callback, timeoutMs: int) {
        root.waitCondition = condition;
        root.waitCallback = callback;
        root.waitDeadline = Date.now() + timeoutMs;
        waitTimer.restart();
    }

    function write(text: string, callback) {
        root.writeCallback = callback;
        writer.setText(text);
    }

    function validMarker(marker: string) : string {
        return "schemaVersion = 1\n# " + marker + "\n";
    }

    function next() {
        root.step += 1;
        actionTimer.restart();
    }

    function runStep() {
        switch (root.step) {
        case 0:
            root.waitUntil(() => {
                return service.reloadState === "idle";
            }, () => {
                root.check(service.active !== null, "defaults snapshot exists");
                root.check(service.active.source === "builtInDefaults", "defaults source");
                root.check(service.activeGeneration === 0, "defaults generation");
                root.check(service.health === "healthy", "missing file is healthy");
                root.check(service.sourceState === "defaultsOnly", "missing file state");
                root.check(service.authoritativePath === root.fixturePath, "fixture override");
                root.check(ConfigPathResolver.resolve("/xdg", "/home/user", "", false) === "/xdg/franken-shell/config.toml", "XDG path resolution");
                root.check(ConfigPathResolver.resolve("", "/home/user", "", false) === "/home/user/.config/franken-shell/config.toml", "HOME fallback path resolution");
                root.check(ConfigPathResolver.resolve("/xdg", "/home/user", "/tmp/inherited-config.toml", false) === "/xdg/franken-shell/config.toml", "fixture override ignored outside explicit mode");
                root.check(ConfigPathResolver.resolve("/xdg", "/home/user", "/tmp/fixture-config.toml", true) === "/tmp/fixture-config.toml", "fixture override accepted in explicit mode");
                root.check(ConfigPathResolver.watchAnchor("/xdg/franken-shell/config.toml") === "/xdg/franken-shell", "missing-parent watch anchor");
                root.check(service.authoritativePath.indexOf("/home/tony/.config/franken-shell/config.toml") === -1, "test never uses live user path");
                const startItems = service.active.bar.layout.start.toArray();
                startItems.push("mutated");
                root.check(service.active.bar.layout.start.count === 2, "snapshot lists expose only detached copies");
                const authoritativeSnapshot = service.active;
                root.check(authoritativeSnapshot._source === null && authoritativeSnapshot._metadata === null && authoritativeSnapshot.bar.layout.start._values === null, "snapshot backing inputs detach after construction");
                authoritativeSnapshot._source = {
                    "schemaVersion": 999
                };
                authoritativeSnapshot._metadata = {
                    "requestGeneration": 999
                };
                authoritativeSnapshot.bar.layout.start._values = ["mutated"];
                root.check(service.active === authoritativeSnapshot && service.active.schemaVersion === 1 && service.active.bar.layout.start.count === 2, "consumer writes cannot mutate the active snapshot");
                root.check(typeof service["_active"] === "undefined" && typeof service["_publish"] === "undefined", "active storage and publication are not consumer-visible");
                root.pass("missing file, paths, and immutable defaults");
                root.next();
            }, 3000);
            break;
        case 1:
            root.write(root.validMarker("EDGE_RIGHT"), () => {
                root.waitUntil(() => {
                    return service.active.bar.edge === "right" && service.active.source === "userFile";
                }, () => {
                    root.check(service.health === "healthy", "valid file health");
                    root.check(service.activeGeneration > 0, "valid generation");
                    root.check(root.activationCount === 2, "one user activation");
                    root.pass("watched valid file activation");
                    root.next();
                }, 3000);
            });
            break;
        case 2:
            root.previousSnapshot = service.active;
            root.previousGeneration = service.activeGeneration;
            root.activationsBefore = root.activationCount;
            root.write(root.validMarker("INVALID"), () => {
                root.waitUntil(() => {
                    return service.health === "degraded";
                }, () => {
                    root.check(service.active === root.previousSnapshot, "snapshot retained");
                    root.check(service.activeGeneration === root.previousGeneration, "generation retained");
                    root.check(root.activationCount === root.activationsBefore, "invalid edit did not activate");
                    root.check(service.errorCount === 1, "validation diagnostic retained");
                    root.pass("invalid hot reload retention");
                    root.next();
                }, 3000);
            });
            break;
        case 3:
            root.write(root.validMarker("EDGE_BOTTOM"), () => {
                root.waitUntil(() => {
                    return service.health === "healthy" && service.active.bar.edge === "bottom";
                }, () => {
                    root.check(service.activeGeneration > root.previousGeneration, "recovery generation advanced");
                    root.check(service.errorCount === 0, "recovery cleared errors");
                    root.pass("later valid edit recovery");
                    root.next();
                }, 3000);
            });
            break;
        case 4:
            root.requestsBefore = fakeClient.requestCount;
            root.activationsBefore = root.activationCount;
            root.write(root.validMarker("EDGE_RIGHT"), () => {
                root.write(root.validMarker("EDGE_BOTTOM"), () => {
                    root.write(root.validMarker("EDGE_TOP"), () => {
                        root.waitUntil(() => {
                            return service.active.bar.edge === "top" && fakeClient.requestCount === root.requestsBefore + 1 && root.activationCount === root.activationsBefore + 1;
                        }, () => {
                            root.check(root.activationCount === root.activationsBefore + 1, "rapid edits activated once");
                            root.pass("rapid edit debounce");
                            root.next();
                        }, 3000);
                    });
                });
            });
            break;
        case 5:
            root.requestsBefore = fakeClient.requestCount;
            root.write(root.validMarker("DELAY_OLD EDGE_RIGHT"), () => {
                root.waitUntil(() => {
                    return fakeClient.requestCount === root.requestsBefore + 1;
                }, () => {
                    root.write(root.validMarker("EDGE_BOTTOM"), () => {
                        root.waitUntil(() => {
                            return service.active.bar.edge === "bottom" && fakeClient.requestCount === root.requestsBefore + 2;
                        }, () => {
                            root.previousGeneration = service.activeGeneration;
                            root.activationsBefore = root.activationCount;
                            staleWaitTimer.restart();
                        }, 3000);
                    });
                }, 3000);
            });
            break;
        case 6:
            root.previousSnapshot = service.active;
            root.write(root.validMarker("UNAVAILABLE"), () => {
                root.waitUntil(() => {
                    return service.helperTransportHealth === "unavailable";
                }, () => {
                    root.check(service.active === root.previousSnapshot, "unavailable retains");
                    root.check(service.health === "degraded", "unavailable degrades");
                    root.pass("helper unavailable");
                    root.next();
                }, 3000);
            });
            break;
        case 7:
            root.previousSnapshot = service.active;
            root.write(root.validMarker("TRANSPORT"), () => {
                root.waitUntil(() => {
                    return service.helperTransportHealth === "failed";
                }, () => {
                    root.check(service.active === root.previousSnapshot, "transport retains");
                    root.check(service.sourceState !== "helperUnavailable", "transport failure remains distinct");
                    root.pass("helper transport failure");
                    root.next();
                }, 3000);
            });
            break;
        case 8:
            root.previousSnapshot = service.active;
            root.previousGeneration = service.lastRejectedGeneration;
            root.write(root.validMarker("MALFORMED_RESULT"), () => {
                root.waitUntil(() => {
                    return service.sourceState === "previousValidRetained" && service.errors.length > 0 && service.lastRejectedGeneration > root.previousGeneration;
                }, () => {
                    root.check(service.active === root.previousSnapshot, "malformed retains");
                    root.check(service.errors[0].code === "CONFIG_SNAPSHOT_INVALID", "malformed normalized payload rejected");
                    root.pass("malformed helper result");
                    root.next();
                }, 3000);
            });
            break;
        case 9:
            root.write(root.validMarker("EDGE_RIGHT"), () => {
                root.waitUntil(() => {
                    return service.health === "healthy" && service.active.bar.edge === "right";
                }, () => {
                    root.requestsBefore = fakeClient.requestCount;
                    root.activationsBefore = root.activationCount;
                    service.requestReload();
                    root.waitUntil(() => {
                        return fakeClient.requestCount === root.requestsBefore + 1 && root.activationCount === root.activationsBefore + 1;
                    }, () => {
                        root.pass("explicit reload");
                        root.next();
                    }, 3000);
                }, 3000);
            });
            break;
        case 10:
            root.write(root.validMarker("COMMAND_SECRET EDGE_TOP"), () => {
                root.waitUntil(() => {
                    return service.active.bar.edge === "top" && service.active.commands.ids.count === 1;
                }, () => {
                    const summary = JSON.stringify(service.configurationSummary());
                    root.check(summary.indexOf("fixture-secret") === -1, "secret omitted");
                    root.check(summary.indexOf("arguments") === -1, "arguments omitted");
                    root.check(summary.indexOf("tomlSource") === -1, "source text omitted");
                    root.check(summary.indexOf("normalizedConfiguration") === -1, "normalized config omitted");
                    root.check(writer.atomicWrites, "test writer used atomic replacement");
                    root.pass("sanitized diagnostics and atomic replace watch");
                    root.next();
                }, 3000);
            });
            break;
        default:
            console.info("PASS config-service: all fixtures");
            Qt.quit();
        }
    }

    Component.onCompleted: {
        if (root.fixturePath.length === 0) {
            root.fail("FRANKEN_CONFIG_FIXTURE_PATH is required");
            return ;
        }
        actionTimer.restart();
    }

    FakeConfigHelperClient {
        id: fakeClient
    }

    Core.ConfigService {
        id: service

        helperClient: fakeClient
        onActivated: (snapshot) => {
            root.activationCount += 1;
            root.check(service.active === snapshot, "activation signal follows atomic swap");
            root.check(snapshot.schemaVersion === 1, "activated candidate is complete");
        }
        onCandidateRejected: root.rejectionCount += 1
    }

    FileView {
        id: writer

        path: root.fixturePath
        preload: false
        printErrors: true
        atomicWrites: true
        blockWrites: true
        onSaved: {
            const callback = root.writeCallback;
            root.writeCallback = null;
            if (callback !== null)
                callback();

        }
        onSaveFailed: (error) => {
            return root.fail("fixture write failed: " + FileViewError.toString(error));
        }
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

    Timer {
        id: staleWaitTimer

        interval: 500
        repeat: false
        onTriggered: {
            root.check(service.activeGeneration === root.previousGeneration, "stale helper result did not replace generation");
            root.check(root.activationCount === root.activationsBefore, "stale helper result did not activate");
            root.pass("stale helper response rejection");
            root.next();
        }
    }

}
