import QtQuick
import Quickshell
import "../../core" as Core

ShellRoot {
    id: root

    property int step: 0
    property bool supersededObserved: false
    property int rapidSupersededCount: 0

    readonly property string fakeHelper: String(
        Quickshell.env("FRANKEN_CONFIG_HELPER_TEST_FAKE") ?? ""
    )

    function fail(message: string) {
        console.error("FAIL config-helper-client:", message);
        Qt.exit(1);
    }

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }

    function pass(name: string) {
        console.info("PASS config-helper-client:", name);
    }

    function useRealHelper() {
        client.helperExecutableOverride = "";
        client.helperArguments = [];
        client.timeoutMs = 1000;
    }

    function useFakeHelper(scenario: string, timeoutMs: int) {
        client.helperExecutableOverride = root.fakeHelper;
        client.helperArguments = [scenario];
        client.timeoutMs = timeoutMs;
    }

    function defer(delayMs: int, callback) {
        actionTimer.interval = delayMs;
        actionTimer.callback = callback;
        actionTimer.restart();
    }

    function runStep() {
        switch (root.step) {
        case 0:
            root.useRealHelper();
            client.validateAndNormalize(1, "fixture:success", "schemaVersion = 1\n");
            break;
        case 1:
            root.useRealHelper();
            client.validateAndNormalize(
                2,
                "fixture:invalid",
                "schemaVersion = 1\n[bar]\nenabled = \"yes\"\n"
            );
            break;
        case 2:
            root.useFakeHelper("malformed-stdout", 1000);
            client.validateAndNormalize(3, "fixture:malformed", "schemaVersion = 1\n");
            break;
        case 3:
            root.useFakeHelper("wrong-protocol", 1000);
            client.validateAndNormalize(4, "fixture:wrong-protocol", "schemaVersion = 1\n");
            break;
        case 4:
            root.useFakeHelper("mismatched-generation", 1000);
            client.validateAndNormalize(5, "fixture:mismatched-generation", "schemaVersion = 1\n");
            break;
        case 5:
            root.useFakeHelper("nonzero-exit", 1000);
            client.validateAndNormalize(6, "fixture:nonzero", "schemaVersion = 1\n");
            break;
        case 6:
            client.helperExecutableOverride = "/definitely/missing/franken-config-helper";
            client.helperArguments = [];
            client.timeoutMs = 1000;
            client.validateAndNormalize(7, "fixture:missing", "schemaVersion = 1\n");
            break;
        case 7:
            root.useFakeHelper("timeout", 50);
            client.validateAndNormalize(8, "fixture:timeout", "schemaVersion = 1\n");
            break;
        case 8:
            root.useFakeHelper("stderr", 1000);
            client.validateAndNormalize(9, "fixture:stderr", "schemaVersion = 1\n");
            break;
        case 9:
            root.supersededObserved = false;
            root.useFakeHelper("delayed-success", 1000);
            client.validateAndNormalize(10, "fixture:superseded-old", "schemaVersion = 1\n");
            root.defer(10, function() {
                client.helperArguments = ["success"];
                client.validateAndNormalize(
                    11,
                    "fixture:superseded-new",
                    "schemaVersion = 1\n"
                );
            });
            break;
        case 10:
            root.rapidSupersededCount = 0;
            root.useFakeHelper("delayed-success", 1000);
            client.validateAndNormalize(20, "fixture:rapid-20", "schemaVersion = 1\n");
            client.helperArguments = ["success"];
            for (let generation = 21; generation <= 30; ++generation) {
                client.validateAndNormalize(
                    generation,
                    "fixture:rapid-" + generation,
                    "schemaVersion = 1\n"
                );
            }
            break;
        default:
            console.info("PASS config-helper-client: all fixtures");
            Qt.quit();
        }
    }

    function handleResult(result) {
        switch (root.step) {
        case 0:
            root.check(result.generation === 1, "success generation");
            root.check(result.success, "real helper success");
            root.check(result.state === "completed", "success state");
            root.check(result.normalizedConfiguration.schemaVersion === 1, "normalized payload");
            root.pass("successful validation");
            break;
        case 1:
            root.check(result.generation === 2, "validation-failure generation");
            root.check(!result.success, "validation failure should fail");
            root.check(result.state === "helperValidationFailure", "validation-failure state");
            root.check(result.transportFailure === null, "validation failure is not transport");
            root.check(result.errors.length > 0, "validation diagnostics");
            root.pass("helper-reported invalid configuration");
            break;
        case 2:
            root.check(result.state === "invalidProtocolResponse", "malformed stdout state");
            root.check(
                result.transportFailure.category === "invalidProtocolResponse",
                "malformed stdout category"
            );
            root.pass("malformed stdout");
            break;
        case 3:
            root.check(result.state === "invalidProtocolResponse", "wrong protocol state");
            root.pass("wrong protocol version");
            break;
        case 4:
            root.check(result.state === "invalidProtocolResponse", "mismatched generation state");
            root.pass("mismatched generation");
            break;
        case 5:
            root.check(result.state === "unexpectedProcessExit", "nonzero exit state");
            root.check(result.process.exitCode === 7, "nonzero exit code");
            root.check(result.process.stderrPresent, "nonzero stderr collection");
            root.pass("nonzero exit");
            break;
        case 6:
            root.check(result.state === "helperUnavailable", "missing helper state");
            root.check(
                result.transportFailure.category === "helperUnavailable",
                "missing helper category"
            );
            root.pass("missing helper binary");
            break;
        case 7:
            root.check(result.state === "timedOut", "timeout state");
            root.check(result.transportFailure.category === "timeout", "timeout category");
            root.pass("timeout");
            break;
        case 8:
            root.check(result.success, "stderr fixture should otherwise succeed");
            root.check(result.process.stderrPresent, "stderr was collected separately");
            root.check(result.process.stderrLength > 0, "stderr length");
            root.check(result.process.stderrExcerpt === undefined, "stderr content stays private");
            root.pass("stderr output");
            break;
        case 9:
            root.check(result.generation === 11, "only newer superseding result is published");
            root.check(root.supersededObserved, "superseded state was reported");
            root.pass("superseded request");
            break;
        case 10:
            root.check(result.generation === 30, "rapid requests publish only newest generation");
            root.check(root.rapidSupersededCount >= 10, "rapid requests were coalesced");
            root.pass("rapid repeated requests");
            break;
        default:
            root.fail("unexpected result at step " + root.step);
            return;
        }

        root.step += 1;
        root.defer(0, root.runStep);
    }

    Timer {
        id: actionTimer

        property var callback: null

        repeat: false
        onTriggered: {
            const action = callback;
            callback = null;
            if (action !== null)
                action();
        }
    }

    Core.ConfigHelperClient {
        id: client

        onRequestStateChanged: (generation, state) => {
            if (generation === 10 && state === "superseded")
                root.supersededObserved = true;
            if (generation >= 20 && generation < 30 && state === "superseded")
                root.rapidSupersededCount += 1;
        }
        onResultReady: result => root.handleResult(result)
    }

    Component.onCompleted: {
        if (root.fakeHelper.length === 0) {
            root.fail("test helper paths were not provided");
            return;
        }
        root.runStep();
    }
}
