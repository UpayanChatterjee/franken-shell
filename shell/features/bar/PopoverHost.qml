pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../tray" as Tray
import "../workspaces" as Workspaces

Scope {
    id: root

    readonly property var activePopover: root.surfaceCoordinator?.activePopover ?? null
    readonly property Item anchorItem: root.owned ? root.anchorResolver(root.activePopover.anchorId) : null
    required property var anchorResolver
    property var audioController: null
    property var batteryController: null
    property var calendarController: null
    property var contextController: null
    required property string edge
    required property var fixtureModel
    required property bool fixtureWindow
    readonly property bool keyboardOpened: root.activePopover?.origin === "keyboard"
    required property string monitorId
    readonly property bool open: root.owned && root.anchorItem !== null
    readonly property bool owned: root.activePopover !== null && root.activePopover.ownerMonitorId === root.monitorId
    required property var parentWindow
    property var resourceController: null
    required property var screenInfo
    required property var specialWorkspaceController
    required property var surfaceCoordinator
    required property var theme
    property var trayController: null
    property var vicinaeAdapter: null
    readonly property string visibleSurfaceId: root.open ? root.activePopover?.surfaceId ?? "" : ""

    function dismissEscape(): var {
        if (root.visibleSurfaceId === "tray.drawer" && root.trayController?.menuState?.active === true)
            return root.trayController.closeMenu();
        return root.owned ? root.surfaceCoordinator.closePopover("escape") : Object.freeze({
            "accepted": true,
            "changed": false,
            "errorCode": ""
        });
    }
    function dismissOutside(): var {
        return root.owned ? root.surfaceCoordinator.closePopover("outsideClick") : Object.freeze({
            "accepted": true,
            "changed": false,
            "errorCode": ""
        });
    }
    function summary(): var {
        return Object.freeze({
            "open": root.open,
            "surfaceId": root.visibleSurfaceId,
            "anchorId": root.open ? root.activePopover?.anchorId ?? "" : "",
            "monitorId": root.monitorId,
            "edge": placement.normalizedEdge,
            "popupEdge": placement.popupEdge,
            "inwardDirection": placement.inwardDirection,
            "keyboardOpened": root.keyboardOpened,
            "anchorResolved": root.anchorItem !== null
        });
    }

    PopoverPlacement {
        id: placement

        edge: root.edge
    }
    FloatingWindow {
        id: fixturePopup

        color: "transparent"
        implicitHeight: Math.max(1, fixtureFrame.implicitHeight)
        implicitWidth: Math.max(1, fixtureFrame.implicitWidth)
        screen: root.screenInfo
        title: qsTr("Franken Shell fixture popover")
        visible: root.fixtureWindow && root.open

        Loader {
            id: fixtureFrame

            anchors.fill: parent
            sourceComponent: popoverFrame
        }
    }
    Loader {
        active: !root.fixtureWindow
        sourceComponent: popupWindowComponent
    }
    Component {
        id: popupWindowComponent

        PopupWindow {
            // qmllint disable missing-type unresolved-type
            anchor.edges: {
                switch (placement.popupEdge) {
                case "left":
                    return Edges.Left;
                case "top":
                    return Edges.Top;
                case "bottom":
                    return Edges.Bottom;
                default:
                    return Edges.Right;
                }
            }
            anchor.gravity: anchor.edges
            // qmllint enable missing-type unresolved-type
            anchor.item: root.anchorItem
            anchor.window: root.parentWindow
            color: "transparent"
            grabFocus: root.keyboardOpened
            implicitHeight: Math.max(1, liveFrame.implicitHeight)
            implicitWidth: Math.max(1, liveFrame.implicitWidth)
            visible: root.open

            onClosed: {
                if (root.owned)
                    root.dismissOutside();
            }

            Loader {
                id: liveFrame

                anchors.fill: parent
                sourceComponent: popoverFrame
            }
        }
    }
    Component {
        id: popoverFrame

        Rectangle {
            border.color: root.theme.colors.outlineSubtle
            border.width: root.theme.metrics.outlineWidth
            color: Qt.alpha(root.theme.colors.surfacePopup, root.theme.opacity.popover)
            implicitHeight: contentLoader.implicitHeight
            implicitWidth: contentLoader.implicitWidth
            radius: root.theme.radius.radiusMedium

            Loader {
                id: contentLoader

                anchors.fill: parent
                sourceComponent: root.activePopover?.surfaceId === "workspace.special-selector" ? specialWorkspaceContent : root.activePopover?.surfaceId === "tray.drawer" && root.trayController !== null ? trayContent : root.fixtureWindow ? fixtureContent : root.activePopover?.surfaceId === "audio.compact" ? audioContent : root.activePopover?.surfaceId === "resources.summary" ? resourceContent : root.activePopover?.surfaceId === "power.summary" ? batteryContent : root.activePopover?.surfaceId === "calendar.local" ? calendarContent : root.activePopover?.surfaceId === "context.summary" ? contextContent : root.activePopover?.surfaceId === "vicinae.menu" ? vicinaeContent : unavailableContent
            }
            Shortcut {
                enabled: root.open
                sequence: "Escape"

                onActivated: root.dismissEscape()
            }
        }
    }
    Component {
        id: specialWorkspaceContent

        Workspaces.SpecialWorkspaceSelector {
            controller: root.specialWorkspaceController
            focus: root.keyboardOpened
            theme: root.theme

            onDismissed: reason => {
                void reason;
                root.surfaceCoordinator.closePopover("requested");
            }
        }
    }
    Component {
        id: trayContent

        Tray.TrayPopover {
            controller: root.trayController
            focus: root.keyboardOpened
            keyboardOpened: root.keyboardOpened
            theme: root.theme

            onDismissed: reason => {
                void reason;
                root.surfaceCoordinator.closePopover("requested");
            }
        }
    }
    Component {
        id: audioContent

        AudioCompactPopover {
            controller: root.audioController
            focus: root.keyboardOpened
            keyboardOpened: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: resourceContent

        ResourceSummaryPopover {
            controller: root.resourceController
            focus: root.keyboardOpened
            keyboardOpened: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: batteryContent

        BatterySummaryPopover {
            controller: root.batteryController
            focus: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: calendarContent

        CalendarPopover {
            controller: root.calendarController
            focus: root.keyboardOpened
            keyboardOpened: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: contextContent

        ContextStatusPopover {
            controller: root.contextController
            focus: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: vicinaeContent

        VicinaeMenuPopover {
            adapter: root.vicinaeAdapter
            focus: root.keyboardOpened
            keyboardOpened: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: fixtureContent

        FixturePopoverContent {
            datum: root.fixtureModel.popoverDatum(root.activePopover?.surfaceId ?? "")
            focus: root.keyboardOpened
            theme: root.theme
        }
    }
    Component {
        id: unavailableContent

        FixturePopoverContent {
            datum: Object.freeze({
                "popoverTitle": qsTr("Unavailable"),
                "accessibleName": qsTr("This bar surface is unavailable")
            })
            focus: root.keyboardOpened
            theme: root.theme
        }
    }
}
