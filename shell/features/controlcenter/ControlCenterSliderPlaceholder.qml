import QtQuick

FocusScope {
    id: root

    readonly property string focusId: "slider." + root.sliderId
    required property string sliderId
    required property var sliderModel
    required property var theme

    signal adjustmentRequested(int step, string source)

    function requestStep(step: int, source: string): bool {
        if (root.sliderModel?.available !== true || root.sliderModel?.enabled !== true || step === 0)
            return false;
        root.adjustmentRequested(step, source);
        return true;
    }

    Accessible.description: qsTr("%1 percent").arg(Math.round((root.sliderModel?.value ?? 0) * 100))
    Accessible.name: root.sliderModel?.label ?? ""
    Accessible.role: Accessible.Slider
    activeFocusOnTab: true
    implicitHeight: 48
    visible: root.sliderModel?.available === true

    Keys.onDownPressed: event => {
        root.requestStep(-1, "keyboard");
        event.accepted = true;
    }
    Keys.onLeftPressed: event => {
        root.requestStep(-1, "keyboard");
        event.accepted = true;
    }
    Keys.onRightPressed: event => {
        root.requestStep(1, "keyboard");
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        root.requestStep(1, "keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: root.theme.colors.surfaceOverlay
        radius: root.theme.radius.radiusMedium
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.theme.spacing.space3
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.colors.textPrimary
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeLabel
        text: root.sliderModel?.label ?? ""
        width: 86
    }
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 104
        anchors.right: valueText.left
        anchors.rightMargin: root.theme.spacing.space3
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.colors.outlineSubtle
        height: 6
        radius: root.theme.radius.radiusFull

        Rectangle {
            color: root.theme.colors.accentPrimary
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.sliderModel?.value ?? 0))
        }
    }
    Text {
        id: valueText

        anchors.right: parent.right
        anchors.rightMargin: root.theme.spacing.space3
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.colors.textSecondary
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeMetricSmall
        text: qsTr("%1%").arg(Math.round((root.sliderModel?.value ?? 0) * 100))
        width: 38
    }
    WheelHandler {
        onWheel: event => {
            root.requestStep(event.angleDelta.y > 0 ? 1 : -1, "pointer");
            event.accepted = true;
        }
    }
}
