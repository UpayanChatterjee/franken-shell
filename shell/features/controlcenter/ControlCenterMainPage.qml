pragma ComponentBehavior: Bound
import QtQuick

import "../audio" as AudioFeatures
import "../notifications" as NotificationFeatures

FocusScope {
    id: root

    required property string activeTab
    required property var contentModel
    readonly property string focusedControlId: header.focusedControlId.length > 0 ? header.focusedControlId : wifi.activeFocus ? wifi.focusId : bluetooth.activeFocus ? bluetooth.focusId : doNotDisturb.activeFocus ? doNotDisturb.focusId : nightLight.activeFocus ? nightLight.focusId : idleInhibitor.activeFocus ? idleInhibitor.focusId : volume.activeFocus ? volume.focusId : brightness.activeFocus ? brightness.focusId : notificationsTab.activeFocus ? notificationsTab.focusId : volumeMixerTab.activeFocus ? volumeMixerTab.focusId : root.notificationHistory?.focusedRowId ?? ""
    readonly property real mixerHeight: audioMixerLoader.height
    readonly property bool mixerLoaded: audioMixerLoader.status === Loader.Ready
    readonly property var notificationHistory: notificationLoader.status === Loader.Ready ? notificationLoader.item : null
    required property var theme
    readonly property int visibleSliderCount: 1 + (brightness.visible ? 1 : 0)

    signal headerActionRequested(string actionId, string source)
    signal mixerActionRequested(string actionId, string targetId, real value, string source)
    signal pageRequested(string pageId, string invokerFocusId, string source)
    signal quickControlActionRequested(string controlId, string action, string source)
    signal sliderActionRequested(string sliderId, int step, string source)
    signal sliderValueActionRequested(string sliderId, real value, string source)
    signal tabRequested(string tabId, string source)

    function focusControl(focusId: string): bool {
        switch (focusId) {
        case "quick.wifi":
            wifi.forceActiveFocus();
            return true;
        case "quick.bluetooth":
            bluetooth.forceActiveFocus();
            return true;
        case "quick.doNotDisturb":
            doNotDisturb.forceActiveFocus();
            return true;
        case "quick.nightLight":
            nightLight.forceActiveFocus();
            return true;
        case "quick.idleInhibitor":
            idleInhibitor.forceActiveFocus();
            return true;
        case "slider.volume":
            volume.forceActiveFocus();
            return true;
        case "slider.brightness":
            if (brightness.visible) {
                brightness.forceActiveFocus();
                return true;
            }
            return false;
        case "tab.notifications":
            notificationsTab.forceActiveFocus();
            return true;
        case "tab.volumeMixer":
            volumeMixerTab.forceActiveFocus();
            return true;
        default:
            return false;
        }
    }
    function quickControlItem(controlId: string): var {
        switch (controlId) {
        case "wifi":
            return wifi;
        case "bluetooth":
            return bluetooth;
        case "doNotDisturb":
            return doNotDisturb;
        case "nightLight":
            return nightLight;
        case "idleInhibitor":
            return idleInhibitor;
        default:
            return null;
        }
    }
    function quickControlState(controlId: string): string {
        return root.quickControlItem(controlId)?.stateName ?? "unknown";
    }
    function requestQuickControlAction(controlId: string, action: string, source: string): bool {
        const item = root.quickControlItem(controlId);
        return item !== null ? item.requestAction(action, source) : false;
    }
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        if (sliderId === "volume")
            return volume.requestStep(step, source);
        if (sliderId === "brightness")
            return brightness.requestStep(step, source);
        return false;
    }

    Flickable {
        id: viewport

        anchors.fill: parent
        contentHeight: content.height
        contentWidth: width
        interactive: contentHeight > height

        Column {
            id: content

            spacing: root.theme.spacing.space3
            width: viewport.width

            ControlCenterHeader {
                id: header

                height: implicitHeight
                theme: root.theme
                width: parent.width

                onActionRequested: (actionId, source) => root.headerActionRequested(actionId, source)
            }
            Column {
                spacing: root.theme.spacing.space3
                width: parent.width

                Row {
                    spacing: root.theme.spacing.space3
                    width: parent.width

                    ControlCenterQuickControl {
                        id: wifi

                        KeyNavigation.down: doNotDisturb
                        KeyNavigation.left: bluetooth
                        controlId: "wifi"
                        controlModel: root.contentModel.quickControl(controlId)
                        height: implicitHeight
                        theme: root.theme
                        width: (parent.width - parent.spacing) / 2

                        onActionRequested: (action, source) => {
                            root.quickControlActionRequested(controlId, action, source);
                            if (action === "details")
                                root.pageRequested("network", focusId, source);
                        }
                    }
                    ControlCenterQuickControl {
                        id: bluetooth

                        KeyNavigation.down: nightLight
                        KeyNavigation.left: wifi
                        controlId: "bluetooth"
                        controlModel: root.contentModel.quickControl(controlId)
                        height: implicitHeight
                        theme: root.theme
                        width: (parent.width - parent.spacing) / 2

                        onActionRequested: (action, source) => {
                            root.quickControlActionRequested(controlId, action, source);
                            if (action === "details")
                                root.pageRequested("bluetooth", focusId, source);
                        }
                    }
                }
                Row {
                    spacing: root.theme.spacing.space3
                    width: parent.width

                    ControlCenterQuickControl {
                        id: doNotDisturb

                        KeyNavigation.down: idleInhibitor
                        KeyNavigation.right: nightLight
                        KeyNavigation.up: wifi
                        controlId: "doNotDisturb"
                        controlModel: root.contentModel.quickControl(controlId)
                        height: implicitHeight
                        theme: root.theme
                        width: (parent.width - parent.spacing) / 2

                        onActionRequested: (action, source) => root.quickControlActionRequested(controlId, action, source)
                    }
                    ControlCenterQuickControl {
                        id: nightLight

                        KeyNavigation.down: idleInhibitor
                        KeyNavigation.left: doNotDisturb
                        KeyNavigation.up: bluetooth
                        controlId: "nightLight"
                        controlModel: root.contentModel.quickControl(controlId)
                        height: implicitHeight
                        theme: root.theme
                        width: (parent.width - parent.spacing) / 2

                        onActionRequested: (action, source) => root.quickControlActionRequested(controlId, action, source)
                    }
                }
                ControlCenterQuickControl {
                    id: idleInhibitor

                    KeyNavigation.up: doNotDisturb
                    controlId: "idleInhibitor"
                    controlModel: root.contentModel.quickControl(controlId)
                    height: implicitHeight
                    theme: root.theme
                    width: parent.width

                    onActionRequested: (action, source) => root.quickControlActionRequested(controlId, action, source)
                }
            }
            Column {
                spacing: root.theme.spacing.space2
                width: parent.width

                ControlCenterSlider {
                    id: volume

                    height: implicitHeight
                    sliderId: "volume"
                    sliderModel: root.contentModel.slider(sliderId)
                    theme: root.theme
                    width: parent.width

                    onStepRequested: (step, source) => root.sliderActionRequested(sliderId, step, source)
                    onValueRequested: (value, source) => root.sliderValueActionRequested(sliderId, value, source)
                }
                ControlCenterSlider {
                    id: brightness

                    height: visible ? implicitHeight : 0
                    sliderId: "brightness"
                    sliderModel: root.contentModel.slider(sliderId)
                    theme: root.theme
                    width: parent.width

                    onStepRequested: (step, source) => root.sliderActionRequested(sliderId, step, source)
                    onValueRequested: (value, source) => root.sliderValueActionRequested(sliderId, value, source)
                }
            }
            Row {
                spacing: root.theme.spacing.space2
                width: parent.width

                ControlCenterTabButton {
                    id: notificationsTab

                    KeyNavigation.right: volumeMixerTab
                    activeTab: root.activeTab
                    height: implicitHeight
                    label: qsTr("Notifications")
                    tabId: "notifications"
                    theme: root.theme
                    width: (parent.width - parent.spacing) / 2

                    onSelectedRequested: source => root.tabRequested(tabId, source)
                }
                ControlCenterTabButton {
                    id: volumeMixerTab

                    KeyNavigation.left: notificationsTab
                    activeTab: root.activeTab
                    height: implicitHeight
                    label: qsTr("Volume Mixer")
                    tabId: "volumeMixer"
                    theme: root.theme
                    width: (parent.width - parent.spacing) / 2

                    onSelectedRequested: source => root.tabRequested(tabId, source)
                }
            }
            Loader {
                id: notificationLoader

                active: root.activeTab === "notifications" && root.contentModel.notificationController !== null
                height: active ? Math.max(320, viewport.height - 128) : 0
                sourceComponent: notificationHistoryComponent
                width: parent.width
            }
            Loader {
                id: audioMixerLoader

                active: root.activeTab === "volumeMixer"
                height: active ? Math.max(112, implicitHeight) : 0
                sourceComponent: audioMixerComponent
                width: parent.width
            }
            Rectangle {
                border.color: root.theme.colors.outlineSubtle
                border.width: root.theme.metrics.outlineWidth
                color: root.theme.colors.surfaceRaised
                height: root.activeTab === "notifications" && root.contentModel.notificationController === null ? 112 : 0
                radius: root.theme.radius.radiusLarge
                visible: height > 0
                width: parent.width

                Column {
                    anchors.centerIn: parent
                    spacing: root.theme.spacing.space2
                    width: parent.width - root.theme.spacing.space6 * 2

                    Text {
                        color: root.theme.colors.textPrimary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeSection
                        font.weight: root.theme.typography.fontWeightMedium
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Notification history unavailable")
                        width: parent.width
                    }
                    Text {
                        color: root.theme.colors.textSecondary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("The notification model is not connected to this fixture.")
                        width: parent.width
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
    Component {
        id: notificationHistoryComponent

        NotificationFeatures.NotificationHistoryView {
            controller: root.contentModel.notificationController
            theme: root.theme
        }
    }
    Component {
        id: audioMixerComponent

        AudioFeatures.AudioMixerView {
            audioController: root.contentModel.audioController
            theme: root.theme
            width: parent.width

            onActionRequested: (actionId, targetId, value, source) => root.mixerActionRequested(actionId, targetId, value, source)
        }
    }
}
