.pragma library

// Generated normalized resource for Rust Configuration::default().
// The Rust defaults_contract test rejects any drift from this object.
var normalized = {
    "schemaVersion": 1,
    "shell": {
        "language": "system",
        "timeFormat": "24h",
        "firstDayOfWeek": "system",
        "startup": {
            "showReadinessToast": false,
            "restoreSessionState": true
        },
        "reload": {
            "watchConfig": true,
            "debounceMs": 300
        }
    },
    "appearance": {
        "mode": "dynamic",
        "fallbackMode": "dark",
        "iconTheme": "system",
        "reducedMotion": false,
        "highContrast": false,
        "dynamicColors": {
            "enabled": true,
            "source": "caelestia",
            "transition": true
        },
        "surfaceOpacity": {
            "bar": 0.96,
            "controlCenter": 0.98,
            "popover": 0.98,
            "notification": 0.98
        },
        "blur": {
            "enabled": false,
            "popovers": false
        },
        "font": {
            "family": "system",
            "scale": 1.0
        }
    },
    "bar": {
        "enabled": true,
        "edge": "left",
        "thickness": "auto",
        "visibleOn": "configuredMonitors",
        "hideInFullscreen": true,
        "autohide": {
            "enabled": false,
            "revealDelayMs": 0,
            "hideDelayMs": 350,
            "activationWidth": 2.0,
            "revealOverFullscreen": false
        },
        "layout": {
            "start": [
                "workspacePager",
                "specialWorkspaces"
            ],
            "context": [
                "contextStatus",
                "tray"
            ],
            "end": [
                "networkSpeed",
                "audio",
                "resources",
                "battery",
                "dateTime",
                "vicinae"
            ]
        },
        "workspacePager": {
            "groupSize": 5,
            "showOccupancy": false,
            "showApplicationIcons": false,
            "scrollEnabled": true,
            "scrollDirection": "natural"
        },
        "contextRegion": {
            "slots": 3,
            "overflow": "stack",
            "priority": [
                "critical",
                "privacy",
                "recording",
                "connectivity",
                "devices",
                "activity"
            ]
        },
        "networkSpeed": {
            "enabled": true,
            "show": "download",
            "unit": "bytes",
            "base": 1000,
            "decimals": 0,
            "updateIntervalMs": 1000,
            "smoothingWindow": 3,
            "zeroFormat": "0K"
        },
        "battery": {
            "showPercentSign": false,
            "chargingAnimation": true
        },
        "dateTime": {
            "showDate": true,
            "monthFormat": "shortText",
            "verticalLayout": "stacked"
        },
        "vicinae": {
            "show": true,
            "position": "absoluteEnd"
        }
    },
    "controlCenter": {
        "enabled": true,
        "edge": "right",
        "width": "auto",
        "defaultPage": "notifications",
        "restoreLastPageForMs": 15000,
        "quickControls": [
            "wifi",
            "bluetooth",
            "doNotDisturb",
            "nightLight",
            "idleInhibitor"
        ],
        "sliders": [
            "volume",
            "brightness"
        ],
        "tabs": [
            "notifications",
            "volumeMixer"
        ],
        "edgeDrag": {
            "enabled": true,
            "activationWidth": 2.0,
            "minimumDistance": 24.0,
            "openThreshold": 0.35,
            "velocityThreshold": 900.0,
            "horizontalIntentRatio": 1.5,
            "allowInFullscreen": false
        },
        "scrim": {
            "enabled": true,
            "dismissOnClick": true
        }
    },
    "workspaces": {
        "special": [
            {
                "id": "music",
                "hyprlandName": "music",
                "label": "Music",
                "icon": "music",
                "shortcutHint": "Super+M",
                "defaultApplication": "cider"
            },
            {
                "id": "movies",
                "hyprlandName": "movies",
                "label": "Movies",
                "icon": "movie",
                "shortcutHint": "Super+A",
                "defaultApplication": "stremio"
            },
            {
                "id": "books",
                "hyprlandName": "books",
                "label": "Books",
                "icon": "book",
                "shortcutHint": "Super+B",
                "defaultApplication": "readest"
            },
            {
                "id": "discord",
                "hyprlandName": "discord",
                "label": "Discord",
                "icon": "discord",
                "shortcutHint": "Super+D",
                "defaultApplication": "discord"
            },
            {
                "id": "scratchpad",
                "hyprlandName": "scratchpad",
                "label": "Scratchpad",
                "icon": "terminal",
                "shortcutHint": "Super+S",
                "defaultApplication": null
            },
            {
                "id": "todo",
                "hyprlandName": "todo",
                "label": "Todo",
                "icon": "checklist",
                "shortcutHint": "Super+T",
                "defaultApplication": "planify"
            }
        ],
        "numbered": {
            "minimum": 1,
            "maximum": 10,
            "groupSize": 5,
            "wrap": false,
            "semanticLabels": {}
        },
        "overview": {
            "provider": "quickshell-overview",
            "openOnActiveWorkspaceClick": true,
            "rows": 2,
            "columns": 5,
            "showSpecialWorkspaces": true,
            "hideEmptyRows": false
        },
        "focusedWindowActions": {
            "enabled": true,
            "actions": [
                "moveToWorkspace",
                "moveToSpecialWorkspace",
                "toggleFloating",
                "toggleFullscreen",
                "close",
                "kill"
            ]
        }
    },
    "integrations": {
        "caelestia": {
            "enabled": true,
            "dynamicColors": true,
            "services": []
        },
        "vicinae": {
            "enabled": true,
            "required": false,
            "themeSync": true,
            "extensionEnabled": true,
            "shortcutMenu": []
        },
        "overview": {
            "enabled": true,
            "provider": "quickshell-overview",
            "required": false,
            "instanceName": "overview",
            "themeSync": true,
            "configSync": true
        },
        "autoCpuFreq": {
            "enabled": true,
            "required": false
        }
    },
    "commands": {}
};
