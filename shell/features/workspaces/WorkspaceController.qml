import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool actionBusy: root.adapter?.actionBusy === true
    required property var activeActivationPolicy
    readonly property int activeNumber: controller.activeNumber(state.backendRevision)
    readonly property bool activeNumberInConfiguredRange: root.activeNumber >= root.minimumNumber && root.activeNumber <= root.maximumNumber
    required property var adapter
    readonly property int groupSize: Math.max(1, Number(root.numberedConfig?.groupSize ?? root.pagerConfig?.groupSize ?? 5))
    property string lastError: ""
    readonly property int maximumNumber: Number(root.numberedConfig?.maximum ?? 10)
    readonly property int minimumNumber: Number(root.numberedConfig?.minimum ?? 1)
    required property var monitor
    readonly property string monitorId: String(root.monitor?.runtimeId ?? "")
    required property var numberedConfig
    readonly property bool overviewAvailable: root.activeActivationPolicy?.available === true
    readonly property bool overviewBusy: root.activeActivationPolicy?.busy === true
    readonly property string overviewLastError: String(root.activeActivationPolicy?.lastError ?? root.activeActivationPolicy?.integrationError ?? "")
    required property var pagerConfig
    readonly property string scrollDirection: String(root.pagerConfig?.scrollDirection ?? "natural")
    readonly property bool scrollEnabled: root.pagerConfig?.scrollEnabled !== false
    readonly property bool stateAvailable: root.adapter?.available === true && Number.isInteger(root.activeNumber)
    readonly property var visibleNumbers: controller.visibleNumbers(root.activeNumber, root.minimumNumber, root.maximumNumber, root.groupSize)
    readonly property bool wrapEnabled: root.numberedConfig?.wrap === true

    signal activationFailed(int number, string errorCode)
    signal activationRequested(int number, string source)
    signal activationSucceeded(int number)
    signal escapeRequested

    function activateFocusedNumber(invocationContext): var {
        const result = root.activeActivationPolicy.activate(root.monitorId, invocationContext);
        root.lastError = result.accepted ? "" : result.errorCode;
        if (!result.accepted)
            root.activationFailed(root.activeNumber, result.errorCode);
        return result;
    }
    function activateNumber(number: int, invocationContext): var {
        if (!root.stateAvailable)
            return controller.failure(number, "WORKSPACE_STATE_UNAVAILABLE");
        if (number < root.minimumNumber || number > root.maximumNumber)
            return controller.failure(number, "WORKSPACE_TARGET_OUT_OF_RANGE");
        if (number === root.activeNumber)
            return root.activateFocusedNumber(invocationContext);

        root.activationRequested(number, String(invocationContext?.source ?? "unknown"));
        const result = root.adapter.activateNumberedWorkspace(number, root.monitorId, invocationContext);
        root.lastError = result.accepted ? "" : String(result.errorCode ?? "WORKSPACE_ACTIVATION_FAILED");
        if (result.accepted)
            root.activationSucceeded(number);
        else
            root.activationFailed(number, root.lastError);
        return controller.result(result.accepted === true, root.lastError);
    }
    function flushPendingScroll() {
        scrollTimer.stop();
        controller.flushScroll();
    }
    function queueScroll(delta: real, invocationContext) {
        if (!root.scrollEnabled || !root.stateAvailable || delta === 0)
            return;

        state.pendingInvocationContext = invocationContext;
        state.scrollAccumulator += delta;
        while (Math.abs(state.scrollAccumulator) >= 120) {
            const wheelDirection = state.scrollAccumulator > 0 ? -1 : 1;
            const policyDirection = root.scrollDirection === "reverse" ? -wheelDirection : wheelDirection;
            const base = state.pendingScrollTarget >= 0 ? state.pendingScrollTarget : root.activeNumber;
            state.pendingScrollTarget = controller.targetForStep(base, policyDirection);
            state.scrollAccumulator += state.scrollAccumulator > 0 ? -120 : 120;
        }
        if (state.pendingScrollTarget >= 0)
            scrollTimer.restart();
    }
    function semanticLabel(number: int): string {
        const labels = root.numberedConfig?.semanticLabels;
        if (labels === null || labels === undefined)
            return "";
        if (typeof labels.value === "function")
            return String(labels.value(String(number), labels.value(number, "")) ?? "");
        return String(labels[number] ?? labels[String(number)] ?? "");
    }
    function step(delta: int, invocationContext): var {
        if (!root.stateAvailable)
            return controller.failure(root.activeNumber, "WORKSPACE_STATE_UNAVAILABLE");
        const target = controller.targetForStep(root.activeNumber, delta);
        if (target === root.activeNumber)
            return controller.result(true, "");
        return root.activateNumber(target, invocationContext);
    }

    Connections {
        function onStateChanged() {
            controller.cancelPendingScroll();
            state.backendRevision += 1;
        }

        target: root.adapter
    }
    Timer {
        id: scrollTimer

        interval: 24

        onTriggered: controller.flushScroll()
    }
    QtObject {
        id: state

        property int backendRevision: 0
        property var pendingInvocationContext: null
        property int pendingScrollTarget: -1
        property real scrollAccumulator: 0
    }
    QtObject {
        id: controller

        function activeNumber(revision: int): int {
            void revision;
            return Number(root.adapter?.activeNumberForMonitor(root.monitorId) ?? -1);
        }
        function cancelPendingScroll() {
            scrollTimer.stop();
            state.pendingInvocationContext = null;
            state.pendingScrollTarget = -1;
            state.scrollAccumulator = 0;
        }
        function failure(number: int, errorCode: string): var {
            root.lastError = errorCode;
            root.activationFailed(number, errorCode);
            return controller.result(false, errorCode);
        }
        function flushScroll() {
            if (state.pendingScrollTarget < 0)
                return;
            const target = state.pendingScrollTarget;
            const context = state.pendingInvocationContext;
            state.pendingScrollTarget = -1;
            state.pendingInvocationContext = null;
            if (target !== root.activeNumber)
                root.activateNumber(target, context);
        }
        function result(accepted: bool, errorCode: string): var {
            return Object.freeze({
                "accepted": accepted,
                "errorCode": errorCode
            });
        }
        function targetForStep(base: int, delta: int): int {
            let target = base + (delta < 0 ? -1 : 1);
            if (target < root.minimumNumber)
                target = root.wrapEnabled ? root.maximumNumber : root.minimumNumber;
            else if (target > root.maximumNumber)
                target = root.wrapEnabled ? root.minimumNumber : root.maximumNumber;
            return target;
        }
        function visibleNumbers(active: int, minimum: int, maximum: int, size: int): var {
            if (maximum < minimum)
                return Object.freeze([]);
            const groupActive = active >= minimum && active <= maximum ? active : minimum;
            const groupStart = minimum + Math.floor((groupActive - minimum) / size) * size;
            const values = [];
            for (let number = groupStart; number <= maximum && number < groupStart + size; number += 1)
                values.push(number);
            return Object.freeze(values);
        }
    }
}
