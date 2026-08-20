import "../../features/controlcenter" as ControlCenter
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int closeRequestCount: 0
    property int openRequestCount: 0
    property int settleRequestCount: 0
    property real settleTarget: -1

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL control-center-drag:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function reset() {
        controller.resetClosed();
        root.closeRequestCount = 0;
        root.openRequestCount = 0;
        root.settleRequestCount = 0;
        root.settleTarget = -1;
    }
    function run() {
        root.reset();
        root.check(!controller.beginEdgePress(950, 200, 1000, false, false, 0), "press outside activation strip is rejected");
        root.check(controller.state === "closed" && root.openRequestCount === 0, "outside press leaves the controller closed");
        root.reset();
        root.check(controller.beginEdgePress(999, 200, 1000, false, false, 0), "edge press is accepted");
        root.check(!controller.updateDrag(990, 245, 20), "mostly vertical motion does not commit");
        root.check(!controller.release(990, 245, 20), "vertical gesture settles closed");
        root.check(controller.state === "closed" && root.openRequestCount === 0, "vertical gesture never requests the surface");
        root.reset();
        root.check(controller.beginEdgePress(999, 200, 1000, false, false, 0), "small-movement edge press is accepted");
        root.check(!controller.updateDrag(985, 203, 20), "movement below minimum distance does not commit");
        root.check(!controller.release(985, 203, 20), "insufficient motion closes");
        root.check(controller.state === "closed" && controller.revealProgress === 0, "insufficient motion has no residual reveal");
        root.reset();
        root.check(controller.beginEdgePress(999, 200, 1000, false, false, 0), "distance gesture begins");
        root.check(controller.updateDrag(839, 204, 240), "horizontal intent commits");
        root.check(root.openRequestCount === 1 && controller.revealProgress === 0.4, "reveal progress follows inward distance");
        root.check(controller.release(839, 204, 240), "distance threshold requests open settle");
        root.check(controller.state === "settlingOpen" && root.settleTarget === 1, "distance gesture settles open");
        root.check(controller.completeSettle() && controller.state === "open" && controller.revealProgress === 1, "open settle completes deterministically");
        root.reset();
        root.check(controller.beginEdgePress(999, 200, 1000, false, false, 0), "velocity gesture begins");
        root.check(controller.updateDrag(959, 201, 20), "fast horizontal intent commits");
        root.check(controller.revealProgress === 0.1, "velocity gesture remains below distance threshold");
        root.check(controller.release(959, 201, 20), "inward velocity opens below distance threshold");
        root.check(controller.state === "settlingOpen", "velocity gesture settles open");
        root.reset();
        root.check(controller.beginEdgePress(999, 200, 1000, false, false, 0), "reversal gesture begins");
        root.check(controller.updateDrag(799, 201, 250), "reversal gesture commits");
        root.check(controller.revealProgress === 0.5, "gesture reaches half reveal");
        root.check(controller.updateDrag(959, 201, 450), "committed drag accepts reversal");
        root.check(controller.revealProgress === 0.1, "reversal directly reduces reveal progress");
        root.check(!controller.release(959, 201, 450), "reversed gesture settles closed");
        root.check(controller.state === "settlingClosed" && root.settleTarget === 0, "reversal chooses closed target");
        root.check(controller.completeSettle() && root.closeRequestCount === 1, "closed settle releases major-surface ownership once");
        root.reset();
        root.check(controller.beginEdgePress(999, 200, 1000, false, false, 0), "cancel gesture begins");
        root.check(controller.updateDrag(899, 201, 100), "cancel gesture commits");
        root.check(controller.cancel("pointerCancelled"), "active drag can be cancelled");
        root.check(controller.state === "closed" && controller.revealProgress === 0 && root.closeRequestCount === 1, "cancellation resets reveal and requests close");
        root.reset();
        root.check(!controller.beginEdgePress(999, 200, 1000, true, false, 0), "true fullscreen suppresses pointer edge drag by default");
        root.check(controller.beginEdgePress(999, 200, 1000, true, true, 0), "explicit fullscreen configuration permits pointer edge drag");
        controller.cancel("testReset");
        root.reset();
        controller.showOpen();
        root.check(controller.beginCloseDrag(600, 200, 0), "open drawer accepts close drag from an eligible region");
        root.check(controller.updateDrag(760, 202, 200), "outward horizontal close intent commits");
        root.check(controller.revealProgress === 0.6, "close drag directly reduces reveal progress");
        root.check(!controller.release(760, 202, 200), "sufficient outward distance requests closed settle");
        root.check(controller.state === "settlingClosed", "close gesture settles closed");
        controller.completeSettle();
        console.info("PASS control-center-drag: activation geometry, intent, distance, velocity, reversal, cancellation, fullscreen suppression, and close drag");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    ControlCenter.ControlCenterRevealController {
        id: controller

        activationWidth: 2
        drawerWidth: 400
        horizontalIntentRatio: 1.5
        minimumDistance: 24
        openThreshold: 0.35
        velocityThreshold: 900

        onCloseRequested: reason => {
            void reason;
            root.closeRequestCount += 1;
        }
        onOpenRequested: root.openRequestCount += 1
        onSettleRequested: targetProgress => {
            root.settleRequestCount += 1;
            root.settleTarget = targetProgress;
        }
    }
}
