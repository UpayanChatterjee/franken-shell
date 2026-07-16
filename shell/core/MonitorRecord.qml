import QtQuick

QtObject {
    id: root

    readonly property string runtimeId: state.runtimeId ?? ""
    readonly property string connector: state.connector ?? ""
    readonly property string name: root.connector
    readonly property string make: state.make ?? ""
    readonly property string model: state.model ?? ""
    readonly property string serial: state.serial ?? ""
    readonly property string description: state.description ?? ""
    // Qt device-independent global geometry when a screen is mapped. A
    // Hyprland-only record uses compositor logical coordinates and says so in
    // logicalGeometry.coordinateSpace.
    readonly property var logicalGeometry: state.logicalGeometry ?? null
    // Hyprland's global logical layout geometry. Null while compositor data is
    // unavailable.
    readonly property var compositorGeometry: state.compositorGeometry ?? null
    // Unscaled monitor-mode pixel dimensions. This has no global origin.
    readonly property var physicalModeDimensions: state.physicalModeDimensions ?? null
    // Compositor logical-to-mode-pixel scale.
    readonly property real scale: state.scale ?? 1
    // Qt physical-to-device-independent pixel ratio.
    readonly property real devicePixelRatio: state.devicePixelRatio ?? 1
    readonly property int transformCode: state.transformCode ?? 0
    readonly property string transform: state.transform ?? "normal"
    readonly property bool transformFlipped: state.transformFlipped ?? false
    readonly property string orientation: state.orientation ?? "landscape"
    readonly property bool focused: state.focused ?? false
    readonly property bool focusedWindowMonitor: state.focusedWindowMonitor ?? false
    readonly property int activeWorkspaceId: state.activeWorkspaceId ?? -1
    readonly property bool fullscreenActive: state.fullscreenActive ?? false
    readonly property int fallbackRank: state.fallbackRank ?? 300
    readonly property bool configured: state.configured ?? true
    readonly property bool barEnabled: state.barEnabled ?? true
    readonly property string configuredBarEdge: state.configuredBarEdge ?? "left"
    readonly property string mappingHealth: state.mappingHealth ?? "unmapped"
    readonly property bool connected: state.connected ?? false

    property var _initialState: null
    signal normalizedStateChanged

    function _apply(nextState) {
        const previous = state;
        const publicState = {};
        for (const key of Object.keys(nextState)) {
            if (!key.startsWith("_"))
                publicState[key] = nextState[key];
        }
        const changed = [];
        for (const key of Object.keys(publicState)) {
            if (JSON.stringify(previous[key]) !== JSON.stringify(publicState[key]))
                changed.push(key);
        }
        if (changed.length === 0)
            return changed;
        root._storage.state = Object.freeze(publicState);
        root.normalizedStateChanged();
        return changed;
    }

    function sanitizedSnapshot() {
        return Object.freeze({
            runtimeId: root.runtimeId,
            connector: root.connector,
            logicalGeometry: root.logicalGeometry,
            scale: root.scale,
            devicePixelRatio: root.devicePixelRatio,
            transform: root.transform,
            orientation: root.orientation,
            focused: root.focused,
            focusedWindowMonitor: root.focusedWindowMonitor,
            activeWorkspaceId: root.activeWorkspaceId,
            fullscreenActive: root.fullscreenActive,
            fallbackRank: root.fallbackRank,
            configured: root.configured,
            barEnabled: root.barEnabled,
            configuredBarEdge: root.configuredBarEdge,
            mappingHealth: root.mappingHealth,
            connected: root.connected
        });
    }

    readonly property var state: root._storage.state
    property var _storage: QtObject {
        property var state: Object.freeze({})
    }

    Component.onCompleted: {
        if (root._initialState !== null)
            root._apply(root._initialState);
        root._initialState = null;
    }
}
