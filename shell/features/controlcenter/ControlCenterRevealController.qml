import QtQuick

QtObject {
    id: root

    property real _currentX: 0
    property real _currentY: 0
    property bool _edgeOpening: true
    property real _lastSampleMs: 0
    property real _lastX: 0
    property real _startProgress: 0
    property real _startX: 0
    property real _startY: 0
    property real _velocity: 0
    property real activationWidth: 2
    readonly property bool dragging: root.state === "draggingOpen" || root.state === "draggingClosed"
    property real drawerWidth: 400
    property bool enabled: true
    property real horizontalIntentRatio: 1.5
    property real minimumDistance: 24
    property real openThreshold: 0.35
    property real revealProgress: 0
    readonly property bool settling: root.state === "settlingOpen" || root.state === "settlingClosed"
    property string state: "closed"
    readonly property real velocity: root._velocity
    property real velocityThreshold: 900

    signal closeRequested(string reason)
    signal openRequested
    signal settleRequested(real targetProgress)

    function _clamp(value: real): real {
        return Math.max(0, Math.min(1, value));
    }
    function _resetTracking() {
        root._currentX = 0;
        root._currentY = 0;
        root._lastSampleMs = 0;
        root._lastX = 0;
        root._startProgress = root.revealProgress;
        root._startX = 0;
        root._startY = 0;
        root._velocity = 0;
    }
    function beginCloseDrag(x: real, y: real, nowMs: real): bool {
        if (!root.enabled || root.state !== "open")
            return false;

        root._edgeOpening = false;
        root._startProgress = root.revealProgress;
        root._startX = x;
        root._startY = y;
        root._currentX = x;
        root._currentY = y;
        root._lastX = x;
        root._lastSampleMs = nowMs;
        root._velocity = 0;
        root.state = "pressedOpen";
        return true;
    }
    function beginEdgePress(x: real, y: real, surfaceWidth: real, fullscreenActive: bool, allowInFullscreen: bool, nowMs: real): bool {
        const withinStrip = surfaceWidth > 0 && x >= surfaceWidth - root.activationWidth && x <= surfaceWidth;
        if (!root.enabled || root.state !== "closed" || fullscreenActive && !allowInFullscreen || !withinStrip)
            return false;

        root._edgeOpening = true;
        root._startProgress = 0;
        root._startX = x;
        root._startY = y;
        root._currentX = x;
        root._currentY = y;
        root._lastX = x;
        root._lastSampleMs = nowMs;
        root._velocity = 0;
        root.revealProgress = 0;
        root.state = "pressedAtEdge";
        return true;
    }
    function cancel(reason: string): bool {
        const wasActive = root.state !== "closed" && root.state !== "open";
        const hadVisibleReveal = root.revealProgress > 0;
        if (!wasActive)
            return false;

        root.revealProgress = root._edgeOpening ? 0 : 1;
        root.state = root._edgeOpening ? "closed" : "open";
        root._resetTracking();
        if (hadVisibleReveal && root.state === "closed")
            root.closeRequested(reason.length > 0 ? reason : "dragCancelled");

        return true;
    }
    function cancelPointerGesture(reason: string): bool {
        if (root.state !== "pressedAtEdge" && root.state !== "pressedOpen" && !root.dragging)
            return false;

        return root.cancel(reason);
    }
    function completeSettle(): bool {
        if (!root.settling)
            return false;

        const closing = root.state === "settlingClosed";
        root.revealProgress = closing ? 0 : 1;
        root.state = closing ? "closed" : "open";
        root._resetTracking();
        if (closing)
            root.closeRequested("dragSettledClosed");

        return true;
    }
    function release(): bool {
        if (root.state === "pressedAtEdge") {
            root.cancel("insufficientIntent");
            return false;
        }
        if (root.state === "pressedOpen") {
            root.state = "open";
            root._resetTracking();
            return false;
        }
        if (!root.dragging)
            return false;

        const opening = root._edgeOpening;
        const distancePassed = opening ? root.revealProgress >= root.openThreshold : 1 - root.revealProgress >= root.openThreshold;
        const velocityPassed = opening ? root._velocity >= root.velocityThreshold : -root._velocity >= root.velocityThreshold;
        const settleOpen = opening ? distancePassed || velocityPassed : !(distancePassed || velocityPassed);
        root.state = settleOpen ? "settlingOpen" : "settlingClosed";
        root.settleRequested(settleOpen ? 1 : 0);
        return settleOpen;
    }
    function resetClosed() {
        root.revealProgress = 0;
        root.state = "closed";
        root._resetTracking();
    }
    function showOpen() {
        root.revealProgress = 1;
        root.state = "open";
        root._resetTracking();
    }
    function updateDrag(x: real, y: real, nowMs: real): bool {
        if (root.state !== "pressedAtEdge" && root.state !== "pressedOpen" && !root.dragging)
            return false;

        const horizontal = root._edgeOpening ? root._startX - x : x - root._startX;
        const vertical = Math.abs(y - root._startY);
        const intentDistance = Math.abs(horizontal);
        if (root.state === "pressedAtEdge" || root.state === "pressedOpen") {
            if (intentDistance < root.minimumDistance)
                return false;

            if (horizontal <= 0 || intentDistance < vertical * root.horizontalIntentRatio)
                return false;

            root.state = root._edgeOpening ? "draggingOpen" : "draggingClosed";
            if (root._edgeOpening)
                root.openRequested();

            if (!root.dragging)
                return false;
        }
        const elapsedMs = nowMs - root._lastSampleMs;
        if (elapsedMs > 0)
            root._velocity = (root._lastX - x) * 1000 / elapsedMs;

        root._lastX = x;
        root._lastSampleMs = nowMs;
        root._currentX = x;
        root._currentY = y;
        const progressDelta = horizontal / Math.max(1, root.drawerWidth);
        root.revealProgress = root._clamp(root._edgeOpening ? root._startProgress + progressDelta : root._startProgress - progressDelta);
        return true;
    }
}
