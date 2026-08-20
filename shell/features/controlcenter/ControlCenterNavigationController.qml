import QtQuick

QtObject {
    id: root

    property string _invokerFocusId: ""
    property string activePage: "main"
    property string activeTab: "notifications"
    property string lastRestoreFocusId: ""
    readonly property int stackDepth: root.activePage === "main" ? 0 : 1

    function handleEscape(): var {
        if (root.activePage !== "main") {
            const focusId = root.popPage();
            return root.result(true, false, focusId);
        }

        return root.result(false, true, "");
    }
    function popPage(): string {
        if (root.activePage === "main")
            return "";

        const focusId = root._invokerFocusId;
        root.activePage = "main";
        root.activeTab = "notifications";
        root._invokerFocusId = "";
        root.lastRestoreFocusId = focusId;
        return focusId;
    }
    function pushPage(pageId: string, invokerFocusId: string): bool {
        if (root.activePage !== "main" || pageId !== "network" && pageId !== "bluetooth" || invokerFocusId.length === 0)
            return false;

        root.activePage = pageId;
        root._invokerFocusId = invokerFocusId;
        root.lastRestoreFocusId = "";
        return true;
    }
    function resetSession() {
        root.activePage = "main";
        root.activeTab = "notifications";
        root._invokerFocusId = "";
        root.lastRestoreFocusId = "";
    }
    function result(handled: bool, closeRequested: bool, restoreFocusId: string): var {
        return Object.freeze({
            "handled": handled,
            "closeRequested": closeRequested,
            "restoreFocusId": restoreFocusId
        });
    }
    function selectTab(tabId: string): bool {
        if (root.activePage !== "main" || tabId !== "notifications" && tabId !== "volumeMixer")
            return false;
        if (root.activeTab === tabId)
            return false;

        root.activeTab = tabId;
        return true;
    }
}
