import QtQuick

FocusScope {
    id: root

    readonly property string focusId: "slider." + root.sliderId
    required property string sliderId
    required property var sliderModel
    required property var theme

    signal stepRequested(int step, string source)
    signal valueRequested(real value, string source)

    function boundedValue(value: real): real {
        return Math.max(0, Math.min(1, Number(value)));
    }
    function requestStep(step: int, source: string): bool {
        if (root.sliderModel?.available !== true || root.sliderModel?.enabled !== true || step === 0)
            return false;
        root.stepRequested(step, source);
        return true;
    }
    function requestValue(value: real, source: string): bool {
        if (root.sliderModel?.available !== true || root.sliderModel?.enabled !== true)
            return false;
        root.valueRequested(root.boundedValue(value), source);
        return true;
    }
    function valueForPosition(position: real): real {
        return track.width <= 0 ? 0 : root.boundedValue(position / track.width);
    }

    Accessible.description: qsTr("%1 percent").arg(Math.round((root.sliderModel?.value ?? 0) * 100))
    Accessible.name: root.sliderModel?.label ?? ""
    Accessible.role: Accessible.Slider
    activeFocusOnTab: root.visible && root.sliderModel?.enabled === true
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
        color: root.sliderModel?.enabled === true ? root.theme.colors.textPrimary : root.theme.colors.textDisabled
        elide: Text.ElideRight
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeLabel
        text: root.sliderModel?.label ?? ""
        width: 86
    }
    Item {
        id: track

        anchors.left: parent.left
        anchors.leftMargin: 104
        anchors.right: valueText.left
        anchors.rightMargin: root.theme.spacing.space3
        anchors.verticalCenter: parent.verticalCenter
        height: Math.max(24, parent.height)

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.colors.outlineSubtle
            height: 6
            radius: root.theme.radius.radiusFull
            width: parent.width

            Rectangle {
                color: root.theme.colors.accentPrimary
                height: parent.height
                radius: parent.radius
                width: parent.width * root.boundedValue(root.sliderModel?.value ?? 0)
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.colors.accentPrimary
            height: 14
            radius: height / 2
            width: height
            x: Math.max(0, Math.min(parent.width - width, parent.width * root.boundedValue(root.sliderModel?.value ?? 0) - width / 2))
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: root.sliderModel?.enabled === true

            onTapped: eventPoint => root.requestValue(root.valueForPosition(eventPoint.position.x), "pointer")
        }
        DragHandler {
            acceptedButtons: Qt.LeftButton
            enabled: root.sliderModel?.enabled === true
            target: null

            onActiveTranslationChanged: {
                if (active)
                    root.requestValue(root.valueForPosition(centroid.pressPosition.x + activeTranslation.x), "pointer");
            }
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
        horizontalAlignment: Text.AlignRight
        text: qsTr("%1%").arg(Math.round(root.boundedValue(root.sliderModel?.value ?? 0) * 100))
        width: 38
    }
    WheelHandler {
        enabled: root.sliderModel?.enabled === true

        onWheel: event => {
            root.requestStep(event.angleDelta.y > 0 ? 1 : -1, "pointer");
            event.accepted = true;
        }
    }
}
