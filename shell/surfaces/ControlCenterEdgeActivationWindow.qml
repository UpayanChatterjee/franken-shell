import QtQuick
import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    readonly property bool activationAvailable: root.controlCenterConfig?.enabled === true && root.controlCenterConfig?.edgeDrag?.enabled === true && root.monitor?.connected === true && !root.suppressionActive && root.revealController?.state === "closed"
    property var controlCenterConfig: null
    property var monitor: null
    property var revealController: null
    property var screenInfo: null
    readonly property bool suppressionActive: root.monitor?.fullscreenActive === true && root.controlCenterConfig?.edgeDrag?.allowInFullscreen !== true
    readonly property bool tracking: root.revealController?.state === "pressedAtEdge" || root.revealController?.state === "draggingOpen"

    function pointerX(): real {
        return edgeDrag.centroid.pressPosition.x + edgeDrag.activeTranslation.x;
    }
    function pointerY(): real {
        return edgeDrag.centroid.pressPosition.y + edgeDrag.activeTranslation.y;
    }

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "franken-shell-control-center-edge"
    aboveWindows: true
    anchors.bottom: true
    anchors.right: true
    anchors.top: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: false
    implicitWidth: Math.max(1, root.controlCenterConfig?.edgeDrag?.activationWidth ?? 2)
    reloadableId: "control-center-edge-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    visible: root.activationAvailable || root.tracking

    DragHandler {
        id: edgeDrag

        acceptedButtons: Qt.LeftButton
        dragThreshold: 0
        enabled: root.activationAvailable || root.tracking
        target: null

        onActiveChanged: {
            const nowMs = Date.now();
            if (active) {
                const press = centroid.pressPosition;
                if (root.revealController.beginEdgePress(press.x, press.y, root.width, root.monitor?.fullscreenActive === true, root.controlCenterConfig?.edgeDrag?.allowInFullscreen === true, nowMs))
                    root.revealController.updateDrag(root.pointerX(), root.pointerY(), nowMs);
            } else if (root.tracking) {
                root.revealController.release(root.pointerX(), root.pointerY(), nowMs);
            }
        }
        onCanceled: point => {
            void point;
            root.revealController.cancel("pointerCancelled");
        }
        onTranslationChanged: delta => {
            void delta;
            if (active && root.tracking)
                root.revealController.updateDrag(root.pointerX(), root.pointerY(), Date.now());
        }
    }
}
