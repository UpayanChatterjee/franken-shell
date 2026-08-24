pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    readonly property int actionButtonCount: root.visibleActions.length
    readonly property var actions: root.record?.actions ?? []
    property bool actionsExpanded: false
    property bool allowSwipe: false
    property bool bodyExpanded: false
    readonly property bool bodyTruncated: bodyText.truncated
    property bool compact: false
    required property var controller
    property bool dismissible: root.record?.dismissible === true
    property int presentationCount: 1
    required property var record
    readonly property string safeAppIcon: {
        const candidate = String(root.record?.appIcon ?? "");
        return /^image:\/\/icon\/[A-Za-z0-9._@+:-]{1,512}$/.test(candidate) ? candidate : "";
    }
    property real swipeOffset: 0
    required property var theme
    readonly property bool usesIconFallback: !appIcon.visible
    readonly property var visibleActions: root.actionsExpanded ? root.actions : root.actions.slice(0, 2)

    signal dismissRequested(string internalId, string source)
    signal focused(string internalId)
    signal timeoutPauseChanged(string internalId, string reason, bool paused)

    function finishSwipe() {
        const threshold = Math.max(72, root.width * 0.28);
        if (root.allowSwipe && root.dismissible && root.swipeOffset >= threshold) {
            root.requestDismiss("swipe");
            root.swipeOffset = 0;
        } else {
            root.resetSwipe();
        }
    }
    function requestDismiss(source: string) {
        if (root.dismissible)
            root.dismissRequested(root.record.internalId, source);
    }
    function resetSwipe() {
        swipeReturn.stop();
        swipeReturn.from = root.swipeOffset;
        swipeReturn.to = 0;
        swipeReturn.start();
    }
    function timeText(): string {
        const timestamp = Number(root.record?.updatedAtMs ?? root.record?.createdAtMs ?? 0);
        return timestamp > 0 ? new Date(timestamp).toLocaleTimeString(Qt.locale(), Locale.ShortFormat) : "";
    }

    Accessible.description: root.record?.body ?? ""
    Accessible.name: qsTr("%1 notification: %2").arg(root.record?.appName || qsTr("Unknown application")).arg(root.record?.title || qsTr("Untitled"))
    Accessible.role: Accessible.Grouping
    activeFocusOnTab: true
    implicitHeight: cardContent.implicitHeight + 2 * root.theme.spacing.space3

    transform: Translate {
        x: root.swipeOffset
    }

    Keys.onDeletePressed: event => {
        root.requestDismiss("keyboard");
        event.accepted = root.dismissible;
    }
    Keys.onEscapePressed: event => {
        if (root.actionsExpanded) {
            root.actionsExpanded = false;
            event.accepted = true;
        }
    }
    onActiveFocusChanged: {
        root.timeoutPauseChanged(root.record.internalId, "focus", root.activeFocus);
        if (root.activeFocus)
            root.focused(root.record.internalId);
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.record?.classification === "critical" ? root.theme.colors.critical : root.record?.classification === "important" ? root.theme.colors.warning : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: Qt.alpha(root.theme.colors.surfaceRaised, root.theme.opacity.notification)
        radius: root.theme.radius.radiusMedium
    }
    Column {
        id: cardContent

        anchors.left: parent.left
        anchors.leftMargin: root.theme.spacing.space3
        anchors.right: parent.right
        anchors.rightMargin: root.theme.spacing.space3
        anchors.top: parent.top
        anchors.topMargin: root.theme.spacing.space3
        spacing: root.theme.spacing.space2

        Row {
            spacing: root.theme.spacing.space2
            width: parent.width

            Item {
                height: root.theme.metrics.iconLarge
                width: height

                Image {
                    id: appIcon

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: root.safeAppIcon
                    sourceSize.height: Math.ceil(height)
                    sourceSize.width: Math.ceil(width)
                    visible: source.toString().length > 0 && status === Image.Ready
                }
                Rectangle {
                    anchors.fill: parent
                    color: root.theme.colors.surfaceOverlay
                    radius: root.theme.radius.radiusSmall
                    visible: !appIcon.visible

                    Text {
                        anchors.centerIn: parent
                        color: root.theme.colors.textSecondary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        font.weight: root.theme.typography.fontWeightSemibold
                        text: String(root.record?.appName || "?").slice(0, 1).toUpperCase()
                    }
                }
            }
            Column {
                spacing: 0
                width: Math.max(0, parent.width - parent.spacing * 2 - root.theme.metrics.iconLarge - dismissButton.width)

                Text {
                    color: root.theme.colors.textSecondary
                    elide: Text.ElideRight
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeLabel
                    text: root.record?.appName || qsTr("Unknown application")
                    width: parent.width
                }
                Text {
                    color: root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeMetricSmall
                    text: {
                        const classification = root.record?.classification === "critical" ? qsTr("Critical") : root.record?.classification === "important" ? qsTr("Important") : qsTr("Routine");
                        const grouped = root.presentationCount > 1 ? qsTr(" · %1 grouped").arg(root.presentationCount) : "";
                        return classification + grouped + (root.timeText().length > 0 ? " · " + root.timeText() : "");
                    }
                    width: parent.width
                }
            }
            NotificationActionButton {
                id: dismissButton

                Accessible.name: qsTr("Dismiss notification")
                enabled: root.dismissible
                implicitWidth: 40
                label: root.dismissible ? "×" : "—"
                theme: root.theme

                onTriggered: source => root.requestDismiss(source)
            }
        }
        Text {
            color: root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeTitle
            font.weight: root.theme.typography.fontWeightMedium
            text: root.record?.title || qsTr("Untitled notification")
            visible: text.length > 0
            width: parent.width
            wrapMode: Text.Wrap
        }
        Text {
            id: bodyText

            color: root.theme.colors.textSecondary
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            maximumLineCount: root.bodyExpanded ? 20 : root.compact ? 3 : 6
            text: root.record?.body ?? ""
            visible: text.length > 0
            width: parent.width
            wrapMode: Text.Wrap
        }
        NotificationActionButton {
            label: root.bodyExpanded ? qsTr("Show less") : qsTr("Show more")
            theme: root.theme
            visible: bodyText.truncated || root.bodyExpanded
            width: Math.min(implicitWidth, parent.width)

            onTriggered: source => {
                void source;
                root.bodyExpanded = !root.bodyExpanded;
            }
        }
        Item {
            height: root.record?.progress?.active === true ? 6 : 0
            visible: height > 0
            width: parent.width

            Rectangle {
                anchors.fill: parent
                color: root.theme.colors.surfaceOverlay
                radius: root.theme.radius.radiusFull
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.top: parent.top
                color: root.theme.colors.accentPrimary
                radius: root.theme.radius.radiusFull
                width: root.record?.progress?.indeterminate === true ? parent.width * 0.38 : parent.width * Math.max(0, Math.min(1, Number(root.record?.progress?.value ?? 0) / Math.max(1, Number(root.record?.progress?.maximum ?? 100))))
            }
        }
        Flow {
            spacing: root.theme.spacing.space2
            visible: root.visibleActions.length > 0
            width: parent.width

            Repeater {
                model: root.visibleActions

                delegate: NotificationActionButton {
                    required property int index
                    required property var modelData

                    emphasized: index === 0
                    label: modelData.label
                    theme: root.theme

                    onTriggered: source => {
                        void source;
                        root.controller.invokeAction(root.record.internalId, modelData.id);
                    }
                }
            }
            NotificationActionButton {
                label: root.actionsExpanded ? qsTr("Fewer actions") : qsTr("%1 more").arg(root.actions.length - 2)
                theme: root.theme
                visible: root.actions.length > 2

                onTriggered: source => {
                    void source;
                    root.actionsExpanded = !root.actionsExpanded;
                }
            }
        }
    }
    HoverHandler {
        id: hover

        onHoveredChanged: root.timeoutPauseChanged(root.record.internalId, "hover", hovered)
    }
    DragHandler {
        acceptedButtons: Qt.LeftButton
        enabled: root.allowSwipe && root.dismissible
        target: null
        xAxis.enabled: true
        yAxis.enabled: false

        onActiveChanged: {
            if (!active)
                root.finishSwipe();
        }
        onTranslationChanged: root.swipeOffset = Math.max(0, translation.x)
    }
    NumberAnimation {
        id: swipeReturn

        duration: root.theme.reducedMotion ? 0 : root.theme.motion.durationFast
        easing.type: Easing.OutCubic
        property: "swipeOffset"
        target: root
    }
}
