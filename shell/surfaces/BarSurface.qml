import QtQuick
import "../features/bar" as Bar

Item {
    id: root

    required property var barConfig
    readonly property string edge: geometry.edge
    readonly property int exclusiveZone: geometry.exclusiveZone
    property alias fixtureModel: fixtureState
    readonly property bool fullscreenSuppressed: root.barConfig?.hideInFullscreen === true && root.monitor?.fullscreenActive === true
    readonly property bool hostEnabled: root.barConfig?.enabled === true && root.monitor?.connected === true && root.monitor?.barEnabled === true
    readonly property string inwardDirection: geometry.inwardDirection
    readonly property bool layoutOverflow: barLayout.layoutOverflow
    readonly property real minimumMainAxisExtent: barLayout.minimumMainAxisExtent + 2 * root.theme.spacing.space1
    required property var monitor
    readonly property string orientation: geometry.orientation
    readonly property string ownerMonitorId: root.monitor?.runtimeId ?? ""
    required property var theme
    readonly property real thickness: geometry.thickness
    readonly property bool vertical: geometry.vertical
    readonly property bool windowVisible: root.hostEnabled && !root.fullscreenSuppressed

    signal fixtureCaptured(string path, bool saved)

    function captureFixture(path: string) {
        barLayout.grabToImage(result => {
            root.fixtureCaptured(path, result.saveToFile(path));
        });
    }
    function layoutSnapshot(): var {
        return barLayout.snapshot();
    }
    function summary(): var {
        const layout = barLayout.snapshot();
        return Object.freeze({
            "monitorId": root.ownerMonitorId,
            "edge": root.edge,
            "orientation": root.orientation,
            "inwardDirection": root.inwardDirection,
            "visible": root.windowVisible,
            "fullscreenSuppressed": root.fullscreenSuppressed,
            "thickness": geometry.thickness,
            "exclusiveZone": root.exclusiveZone,
            "mainAxisStartInset": geometry.mainAxisStartInset,
            "mainAxisEndInset": geometry.mainAxisEndInset,
            "outwardInset": geometry.outwardInset,
            "layoutOverflow": layout.layoutOverflow,
            "contextCapacity": layout.contextCapacity
        });
    }

    Bar.BarGeometry {
        id: geometry

        configuredEdge: root.monitor?.configuredBarEdge ?? root.barConfig?.edge ?? "left"
        configuredThickness: root.barConfig?.thickness ?? "auto"
        persistentVisible: root.windowVisible
        theme: root.theme
    }
    Bar.BarFixtureModel {
        id: fixtureState
    }
    Rectangle {
        anchors.fill: parent
        border.color: root.theme.colors.outlineSubtle
        border.width: root.theme.metrics.outlineWidth
        color: Qt.alpha(root.theme.colors.surfaceBase, root.theme.opacity.bar)

        Bar.BarLayout {
            id: barLayout

            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            contextCapacity: Math.max(0, root.barConfig?.contextRegion?.slots ?? 3)
            fixtureModel: fixtureState
            theme: root.theme
            vertical: geometry.vertical
        }
    }
}
