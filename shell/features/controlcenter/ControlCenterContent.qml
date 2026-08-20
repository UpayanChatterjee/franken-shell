pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    readonly property string activePage: navigation.activePage
    readonly property string activeTab: navigation.activeTab
    required property var contentModel
    readonly property ControlCenterDetailPage detailItem: detailLoader.status === Loader.Ready ? detailLoader.item as ControlCenterDetailPage : null
    readonly property string focusedControlId: root.activePage === "main" ? mainPage.focusedControlId : root.detailItem?.focusedControlId ?? ""
    required property var theme

    signal closeRequested
    signal headerActionRequested(string actionId, string source)
    signal quickControlActionRequested(string controlId, string action, string source)
    signal sliderActionRequested(string sliderId, int step, string source)

    function focusInitial() {
        mainPage.focusControl("quick.wifi");
    }
    function handleEscape(): var {
        const result = navigation.handleEscape();
        if (result.handled) {
            Qt.callLater(() => mainPage.focusControl(result.restoreFocusId));
        } else if (result.closeRequested) {
            root.closeRequested();
        }
        return result;
    }
    function openPage(pageId: string, invokerFocusId: string, source: string): bool {
        void source;
        const changed = navigation.pushPage(pageId, invokerFocusId);
        if (changed)
            Qt.callLater(() => {
                if (root.detailItem !== null)
                    root.detailItem.focusInitial();
            });
        return changed;
    }
    function quickControlState(controlId: string): string {
        return mainPage.quickControlState(controlId);
    }
    function requestQuickControlAction(controlId: string, action: string, source: string): bool {
        return mainPage.requestQuickControlAction(controlId, action, source);
    }
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        return mainPage.requestSliderStep(sliderId, step, source);
    }
    function resetSession() {
        navigation.resetSession();
    }
    function selectTab(tabId: string, source: string): bool {
        void source;
        return navigation.selectTab(tabId);
    }
    function summary(): var {
        return Object.freeze({
            "activePage": root.activePage,
            "activeTab": root.activeTab,
            "stackDepth": navigation.stackDepth,
            "focusedControlId": root.focusedControlId,
            "quickControlCount": root.contentModel.quickControlCount ?? 0,
            "visibleSliderCount": mainPage.visibleSliderCount
        });
    }

    Keys.onEscapePressed: event => {
        root.handleEscape();
        event.accepted = true;
    }

    ControlCenterNavigationController {
        id: navigation
    }
    ControlCenterMainPage {
        id: mainPage

        activeTab: root.activeTab
        anchors.fill: parent
        contentModel: root.contentModel
        enabled: root.activePage === "main"
        focus: root.focus && root.activePage === "main"
        theme: root.theme
        visible: root.activePage === "main"

        onHeaderActionRequested: (actionId, source) => root.headerActionRequested(actionId, source)
        onPageRequested: (pageId, invokerFocusId, source) => root.openPage(pageId, invokerFocusId, source)
        onQuickControlActionRequested: (controlId, action, source) => root.quickControlActionRequested(controlId, action, source)
        onSliderActionRequested: (sliderId, step, source) => root.sliderActionRequested(sliderId, step, source)
        onTabRequested: (tabId, source) => root.selectTab(tabId, source)
    }
    Loader {
        id: detailLoader

        active: root.activePage !== "main"
        anchors.fill: parent
        sourceComponent: detailPage
    }
    Component {
        id: detailPage

        ControlCenterDetailPage {
            pageId: root.activePage
            theme: root.theme

            onBackRequested: source => {
                void source;
                root.handleEscape();
            }
        }
    }
}
