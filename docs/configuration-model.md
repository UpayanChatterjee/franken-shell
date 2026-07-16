# Franken Shell — Configuration Model

> **Status:** Working configuration baseline  
> **Purpose:** Define the authoritative settings structure, loading rules, validation, migration, persistence, and ownership boundaries  
> **Related documents:** `architecture.md`, `feature-map.md`, `interaction-language.md`, `visual-language.md`

This document defines how Franken Shell configuration should be structured and consumed.

The configuration model must support:

- one source of truth;
- safe reloads;
- schema validation;
- clear defaults;
- versioned migrations;
- hardware-dependent capabilities;
- shared workspace definitions;
- external command configuration;
- per-monitor settings;
- notification policy;
- adopted-component integration;
- future settings UI.

The examples below use JSONC-like syntax for readability. The final file format may be JSONC, TOML, or another structured format, but the logical schema should remain equivalent.

---

# 1. Configuration Principles

## 1.1 One authoritative user configuration

The shell should have one primary user configuration file:

```text
$XDG_CONFIG_HOME/franken-shell/config.jsonc
```

This file owns user-facing shell settings.

Generated files for Vicinae, quickshell-overview, or other integrations must derive from this source rather than becoming additional authoritative configuration.

---

## 1.2 Layered configuration

Configuration should be resolved in this order:

```text
Built-in defaults
        ↓
Package/system defaults
        ↓
User configuration
        ↓
Machine-specific overrides
        ↓
Runtime/session overrides
```

Later layers override earlier layers.

### Built-in defaults

Bundled with the shell and always valid.

### Package/system defaults

Optional distribution or deployment defaults.

Suggested location:

```text
/etc/xdg/franken-shell/config.jsonc
```

### User configuration

Primary user-owned configuration.

### Machine-specific overrides

Optional file for device-specific settings:

```text
$XDG_CONFIG_HOME/franken-shell/machines/<machine-id>.jsonc
```

Useful for:

- monitor mappings;
- brightness backends;
- sensor labels;
- hardware commands;
- laptop versus desktop behaviour.

### Runtime/session overrides

Temporary state that should not automatically rewrite persistent configuration.

Examples:

- current DND state;
- current idle-inhibitor state;
- temporary power override;
- currently selected control-centre tab.

---

## 1.3 Configuration is declarative

Configuration should describe desired behaviour and mappings.

It should not contain:

- arbitrary QML;
- arbitrary shell scripts;
- executable expressions;
- unrestricted D-Bus calls;
- raw JavaScript callbacks.

Commands may be configured only through structured executable-plus-arguments definitions.

---

## 1.4 Semantic settings over visual micromanagement

Expose settings that represent meaningful behaviour.

Prefer:

```text
bar.edge = "left"
bar.autohide.enabled = true
```

Avoid exposing dozens of low-level values such as:

```text
workspaceButton.paddingLeft = 7
workspaceButton.paddingRight = 9
```

Visual values should normally come from shared theme tokens.

---

## 1.5 Invalid configuration never replaces valid state

On reload:

1. parse candidate configuration;
2. validate schema;
3. normalize values;
4. run semantic validation;
5. construct derived models;
6. apply atomically.

If validation fails:

- keep the current valid configuration;
- report the exact error;
- expose the failure through diagnostics;
- do not partially apply the candidate.

---

# 2. File and Schema Versioning

Every configuration must include:

```jsonc
{
  "schemaVersion": 1
}
```

The shell also exposes:

```text
projectVersion
configSchemaVersion
ipcVersion
```

## 2.1 Schema migrations

Migrations should be sequential:

```text
1 → 2
2 → 3
3 → 4
```

Do not maintain many direct migration paths.

Migration process:

1. create backup;
2. parse old configuration;
3. apply migration in memory;
4. validate new structure;
5. write migrated file atomically;
6. preserve comments where the chosen format permits;
7. report migration summary.

## 2.2 Forward compatibility

If the file schema is newer than the running shell:

- refuse destructive rewriting;
- use only clearly compatible fields if safe;
- otherwise retain built-in defaults and show a clear error.

Never silently downgrade a newer configuration.

---

# 3. Proposed Top-Level Structure

```jsonc
{
  "schemaVersion": 1,

  "shell": {},
  "appearance": {},
  "bar": {},
  "controlCenter": {},
  "workspaces": {},
  "gestures": {},
  "notifications": {},
  "audio": {},
  "network": {},
  "bluetooth": {},
  "resources": {},
  "power": {},
  "calendar": {},
  "tray": {},
  "session": {},
  "monitors": {},
  "commands": {},
  "integrations": {},
  "accessibility": {},
  "diagnostics": {}
}
```

Sections may be omitted. Missing values resolve to defaults.

---

# 4. `shell`

General shell behaviour.

```jsonc
{
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
  }
}
```

## Fields

### `language`

Allowed:

- `"system"`;
- explicit locale such as `"en-IN"`.

### `timeFormat`

Allowed:

- `"24h"`;
- `"12h"`.

Project default:

```text
24h
```

### `firstDayOfWeek`

Allowed:

- `"system"`;
- `"monday"`;
- `"sunday"`;
- explicit supported weekday later.

### `startup.restoreSessionState`

Controls restoration of safe transient state such as:

- last selected control-centre tab;
- last valid theme;
- non-sensitive UI preferences.

It must not restore stale destructive prompts or credentials.

---

# 5. `appearance`

Shared visual preferences.

```jsonc
{
  "appearance": {
    "mode": "dynamic",
    "fallbackMode": "dark",
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
    },
    "iconTheme": "system",
    "reducedMotion": false,
    "highContrast": false
  }
}
```

## Fields

### `mode`

Allowed:

- `"dynamic"`;
- `"dark"`;
- `"light"`.

### `dynamicColors.source`

Initial supported value:

- `"caelestia"`.

Future values may include:

- `"matugen"`;
- `"static"`.

### `surfaceOpacity`

Values should be bounded to a safe readable range.

Suggested semantic validation:

```text
0.75 ≤ opacity ≤ 1.0
```

The settings UI should expose presets rather than arbitrary decimals initially.

### `blur`

Default off.

Blur is decorative and must not be required for readability.

### `font.family`

`"system"` uses project default selection.

An explicit family may be configured.

### `font.scale`

Suggested range:

```text
0.8–1.5
```

### `reducedMotion`

Disables or reduces nonessential movement.

### `highContrast`

Uses stronger outlines and contrast-adjusted semantic roles.

---

# 6. `bar`

Persistent edge-bar configuration.

```jsonc
{
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
      "activationWidth": 2,
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
  }
}
```

## 6.1 `edge`

Allowed:

- `"left"`;
- `"right"`;
- `"top"`;
- `"bottom"`.

Per-monitor overrides may replace this.

## 6.2 `thickness`

Allowed:

- `"auto"`;
- positive logical pixel value.

Recommended default implementation range:

```text
44–48 logical pixels
```

## 6.3 `layout`

The initial user settings UI should not expose arbitrary component reordering.

This structure may exist internally for future use, but the first release should preserve the designed hierarchy.

## 6.4 `workspacePager.groupSize`

Default:

```text
5
```

Suggested range:

```text
3–10
```

The user workflow is designed around groups of five.

## 6.5 `networkSpeed.unit`

Allowed:

- `"bytes"`;
- `"bits"`.

Project default:

```text
bytes
```

## 6.6 `networkSpeed.base`

Allowed:

- `1000`;
- `1024`.

## 6.7 Formatter rules

With:

```jsonc
{
  "decimals": 0,
  "base": 1000
}
```

examples are:

```text
3K
20M
1G
```

Tooltip includes both directions and may include `/s`.

---

# 7. `controlCenter`

Right-edge drawer configuration.

```jsonc
{
  "controlCenter": {
    "enabled": true,
    "edge": "right",
    "width": "auto",
    "defaultPage": "notifications",
    "restoreLastPageForMs": 15000,

    "edgeDrag": {
      "enabled": true,
      "activationWidth": 2,
      "minimumDistance": 24,
      "openThreshold": 0.35,
      "velocityThreshold": 900,
      "horizontalIntentRatio": 1.5,
      "allowInFullscreen": false
    },

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

    "scrim": {
      "enabled": true,
      "dismissOnClick": true
    }
  }
}
```

## 7.1 `edge`

Initial supported value:

```text
right
```

The control centre remains conceptually right-attached even if the bar moves.

## 7.2 `width`

Allowed:

- `"auto"`;
- explicit logical pixels.

Recommended prototype range:

```text
380–420
```

## 7.3 Edge-drag values

Raw thresholds should initially remain advanced settings or internal defaults.

The settings UI may expose presets:

- conservative;
- balanced;
- responsive.

---

# 8. `workspaces`

Authoritative workspace definitions.

```jsonc
{
  "workspaces": {
    "numbered": {
      "minimum": 1,
      "maximum": 10,
      "groupSize": 5,
      "wrap": false,
      "semanticLabels": {
        "1": "Browser",
        "2": "Files and terminal",
        "3": "PDF",
        "4": "Obsidian"
      }
    },

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
        "shortcutHint": "Super+S"
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
  }
}
```

## 8.1 Semantic labels

Optional labels help tooltips and settings.

They do not appear permanently in the bar.

## 8.2 Special workspace IDs

`id` is the stable Franken Shell identifier.

`hyprlandName` is the compositor-facing name.

Do not use labels as stable identifiers.

## 8.3 `defaultApplication`

Informational and integration-oriented.

It may be used by:

- settings;
- diagnostics;
- Vicinae commands;
- optional launch helpers.

The shell should not assume one application is always the only window in a special workspace.

## 8.4 Overview generation

quickshell-overview configuration should be generated from this section.

Users must not maintain a second special-workspace list manually.

---

# 9. `gestures`

Gesture configuration and conflict policy.

```jsonc
{
  "gestures": {
    "enabled": true,

    "workspaceSwipe": {
      "enabled": true,
      "owner": "hyprland",
      "fingers": 3,
      "direction": "horizontal"
    },

    "controlCenter": {
      "enabled": false,
      "fingers": 4,
      "direction": "left",
      "continuous": true
    },

    "overview": {
      "enabled": false,
      "fingers": 4,
      "direction": "up"
    },

    "conflictPolicy": "warn"
  }
}
```

## 9.1 `owner`

Allowed:

- `"hyprland"`;
- `"shell"`.

Do not let both claim the same gesture.

## 9.2 `conflictPolicy`

Allowed:

- `"warn"`;
- `"disableShellGesture"`;
- `"preferShell"`;
- `"error"`.

Recommended default:

```text
warn
```

Gesture support remains near-term rather than first-prototype critical.

---

# 10. `notifications`

Notification, DND, grouping, popup, and sound policy.

```jsonc
{
  "notifications": {
    "enabled": true,
    "history": {
      "mode": "memory",
      "maximumItems": 500,
      "maximumAgeHours": 24
    },

    "popups": {
      "enabled": true,
      "position": "topRight",
      "timeoutMs": {
        "routine": 6000,
        "important": 9000,
        "critical": 0
      },
      "pauseOnHover": true,
      "pauseOnFocus": true,
      "suppressWhileDrawerOpen": true,
      "suppressInFullscreen": true,
      "replayAfterFullscreen": false
    },

    "grouping": {
      "byApplication": true,
      "burstWindowMs": 2500,
      "maximumVisiblePopups": 4
    },

    "doNotDisturb": {
      "default": false,
      "suppressPopups": true,
      "suppressSounds": true,
      "allowUserActionFeedback": true,
      "allowOsds": true
    },

    "criticalBypass": {
      "incomingCalls": true,
      "alarms": true,
      "timers": true,
      "authentication": true,
      "pairingRequests": true,
      "criticalBattery": true,
      "criticalTemperature": true,
      "criticalStorage": true,
      "userActionFailures": true,
      "recordingFailure": true,
      "calendarReminders": false,
      "downloadCompletion": false
    },

    "sounds": {
      "enabled": true,
      "default": null,
      "rules": [
        {
          "id": "incoming-calls",
          "match": {
            "category": "incomingCall"
          },
          "sound": "call"
        }
      ]
    },

    "privacy": {
      "persistBodies": false,
      "logBodies": false
    }
  }
}
```

## 10.1 Silent by default

`sounds.enabled` allows the sound engine.

`sounds.default = null` means ordinary notifications remain silent.

## 10.2 Sound rules

Rules should support deterministic matching.

Possible match fields:

```text
appId
appName
title
titleRegex
category
urgency
```

Recommended initial implementation:

- exact app ID;
- exact title;
- safe regular expression for title;
- category.

Rules are evaluated in order.

First matching rule wins unless a later merge strategy is explicitly defined.

## 10.3 Sound definition

A sound may refer to:

- named built-in sound;
- approved local file;
- desktop sound-theme event.

Do not allow arbitrary commands.

## 10.4 Critical timeout

`0` means persistent until acted on or dismissed.

---

# 11. `audio`

Audio behaviour.

```jsonc
{
  "audio": {
    "backend": "pipewire",
    "volumeStep": 0.02,
    "maximumVolume": 1.0,
    "middleClickMute": true,
    "scrollOnBar": true,

    "osd": {
      "enabled": true,
      "timeoutMs": 1000
    },

    "outputIconRules": [
      {
        "match": "bluetooth",
        "icon": "bluetoothHeadphones"
      },
      {
        "match": "headphones",
        "icon": "headphones"
      },
      {
        "match": "hdmi",
        "icon": "displayAudio"
      }
    ]
  }
}
```

## 11.1 `maximumVolume`

Default:

```text
1.0
```

Values above 1.0 should require explicit opt-in.

## 11.2 Icon rules

Rules should primarily derive from normalized device metadata.

User overrides may address misidentified hardware.

---

# 12. `network`

Network and throughput behaviour.

```jsonc
{
  "network": {
    "backend": "networkmanager",

    "connectivity": {
      "showFailureIndicator": true,
      "checkInternet": true,
      "captivePortal": true
    },

    "wifi": {
      "scanOnPageOpen": true,
      "scanIntervalWhileOpenMs": 15000,
      "showSavedNetworks": true,
      "showHiddenNetworkAction": true
    },

    "ethernet": {
      "showInNetworkPage": true
    },

    "advancedSettingsCommand": "network.advanced"
  }
}
```

## 12.1 Secrets

No password or secret fields are allowed in the shell configuration.

## 12.2 Backend abstraction

Initial backend:

```text
networkmanager
```

Feature UI should consume normalized models.

---

# 13. `bluetooth`

Bluetooth behaviour.

```jsonc
{
  "bluetooth": {
    "backend": "bluez",
    "scanOnPageOpen": true,
    "scanTimeoutMs": 30000,
    "showPreviouslyPaired": true,
    "showBattery": true,
    "autoSelectConnectedAudioOutput": false,
    "pairingPromptPolicy": "foreground"
  }
}
```

## 13.1 `pairingPromptPolicy`

Allowed:

- `"foreground"`;
- `"criticalPopup"`;
- `"controlCenterOnly"`.

Recommended:

```text
foreground
```

Pairing prompts must remain visible and must not be dismissed accidentally.

---

# 14. `resources`

Resource indicator and popover.

```jsonc
{
  "resources": {
    "barIndicator": {
      "metric": "memoryPercent",
      "updateIntervalMs": 2000
    },

    "popover": {
      "updateIntervalMs": 1000,
      "show": [
        "cpuUsage",
        "cpuTemperature",
        "cpuClock",
        "cpuFan",
        "gpuUsage",
        "gpuTemperature",
        "gpuClock",
        "gpuFan",
        "memory",
        "swap",
        "storage",
        "uptime",
        "powerProfile",
        "topProcess"
      ]
    },

    "storage": {
      "mounts": [
        "/"
      ]
    },

    "sensorOverrides": {},

    "systemMonitorCommand": "systemMonitor.open"
  }
}
```

## 14.1 Conditional metrics

Entries in `show` are preferences, not guarantees.

Unavailable metrics are omitted.

## 14.2 Sensor overrides

May map hardware-specific sensor identifiers to semantic names.

Example:

```jsonc
{
  "sensorOverrides": {
    "cpuTemperature": "k10temp/Tctl",
    "cpuFan": "asus/fan1"
  }
}
```

These belong preferably in machine-specific overrides.

---

# 15. `power`

Battery and auto-cpufreq.

```jsonc
{
  "power": {
    "battery": {
      "warningPercent": 15,
      "criticalPercent": 5,
      "criticalBypassesDnd": true
    },

    "autoCpuFreq": {
      "enabled": true,
      "configPreference": [
        "user",
        "system"
      ],
      "userConfigPath": "$XDG_CONFIG_HOME/auto-cpufreq/auto-cpufreq.conf",
      "systemConfigPath": "/etc/auto-cpufreq.conf",
      "applyAfterSave": true,
      "createBackup": true
    },

    "temporaryOverrides": {
      "enabled": true,
      "showAutomatic": true,
      "showPowerSave": true,
      "showPerformance": true
    }
  }
}
```

## 15.1 Threshold validation

Require:

```text
0 < criticalPercent < warningPercent ≤ 100
```

## 15.2 Environment variables

Paths may use approved variables:

- `$HOME`;
- `$XDG_CONFIG_HOME`;
- `$XDG_STATE_HOME`;
- `$XDG_CACHE_HOME`.

Do not perform arbitrary shell expansion.

## 15.3 Privileged writes

Configuration only selects behaviour.

Privileged helper policy remains outside the user configuration.

---

# 16. `calendar`

Calendar panel and future providers.

```jsonc
{
  "calendar": {
    "defaultView": "month",
    "showWeekNumbers": false,
    "firstDayOfWeek": "system",

    "providers": [
      {
        "id": "local",
        "type": "local",
        "enabled": true
      }
    ],

    "google": {
      "enabled": false,
      "syncIntervalMinutes": 15,
      "showDeclinedEvents": false
    }
  }
}
```

## 16.1 Prototype

Only the local provider is enabled.

## 16.2 Near-term

Google integration adds account references, but tokens must not live in this configuration file.

The config may store non-secret account IDs after authentication.

---

# 17. `tray`

System tray behaviour.

```jsonc
{
  "tray": {
    "enabled": true,
    "hideWhenEmpty": true,
    "defaultCollapsed": true,
    "showCount": false,

    "ordering": "stable",
    "pinned": [],

    "attention": {
      "surfaceUrgentItems": true,
      "temporaryRevealMs": 5000
    }
  }
}
```

## 17.1 Pinned items

No pinned items by default.

Entries should use stable tray identifiers where available.

Example:

```jsonc
{
  "pinned": [
    "org.localsend.localsend_app"
  ]
}
```

## 17.2 Ordering

Allowed:

- `"stable"`;
- `"application"`;
- explicit order list later.

---

# 18. `session`

Session actions.

```jsonc
{
  "session": {
    "actions": [
      "lock",
      "suspend",
      "logout",
      "reboot",
      "shutdown"
    ],

    "confirm": {
      "lock": false,
      "suspend": false,
      "logout": true,
      "reboot": true,
      "shutdown": true
    },

    "commands": {
      "lock": "session.lock",
      "suspend": "session.suspend",
      "logout": "session.logout",
      "reboot": "session.reboot",
      "shutdown": "session.shutdown"
    }
  }
}
```

The session UI should consume command IDs, not raw shell strings.

---

# 19. `monitors`

Per-monitor shell policy.

```jsonc
{
  "monitors": {
    "default": {
      "bar": {
        "enabled": true,
        "edge": "left"
      },
      "controlCenter": {
        "enabled": true
      }
    },

    "rules": [
      {
        "match": {
          "name": "eDP-1"
        },
        "bar": {
          "enabled": true,
          "edge": "left"
        },
        "controlCenter": {
          "enabled": true
        }
      },
      {
        "match": {
          "name": "DP-1"
        },
        "bar": {
          "enabled": false
        }
      }
    ],

    "keyboardSurfacePolicy": "focusedWindow",
    "notificationPolicy": "focusedWindow",
    "osdPolicy": "activeMonitor",
    "singleControlCenter": true
  }
}
```

## 19.1 Monitor matching

Allowed match fields may include:

```text
name
description
make
model
serial
```

Prefer stable identifiers where available.

## 19.2 Policy values

Possible keyboard surface policies:

- `"focusedWindow"`;
- `"pointer"`;
- `"primary"`;
- explicit monitor.

Possible notification policies:

- `"focusedWindow"`;
- `"pointer"`;
- `"primary"`.

The final multi-monitor specification may refine these.

---

# 20. `commands`

Central command registry.

```jsonc
{
  "commands": {
    "vicinae.root": {
      "executable": "vicinae",
      "arguments": ["toggle"]
    },

    "vicinae.clipboard": {
      "executable": "vicinae",
      "arguments": ["open", "clipboard"]
    },

    "overview.toggle": {
      "executable": "qs",
      "arguments": [
        "ipc",
        "-c",
        "overview",
        "call",
        "overview",
        "toggle"
      ]
    },

    "systemMonitor.open": {
      "executable": "missioncenter",
      "arguments": []
    },

    "network.advanced": {
      "executable": "nm-connection-editor",
      "arguments": []
    }
  }
}
```

The exact Vicinae command syntax must be verified during implementation and may differ from these placeholders.

## 20.1 Command definition

```jsonc
{
  "executable": "program",
  "arguments": ["arg1", "arg2"],
  "environment": {},
  "workingDirectory": null,
  "detached": true,
  "timeoutMs": 5000
}
```

## 20.2 Security rules

Reject:

- shell metacharacter interpretation;
- executable values containing embedded pipelines;
- arbitrary interpolation from notification text;
- secrets in arguments;
- unrestricted commands exposed through shell IPC.

## 20.3 Built-in actions

Some command IDs may map to internal adapters instead of processes.

Example:

```text
session.suspend
```

may call logind directly.

The registry should support both internal and external command targets.

---

# 21. `integrations`

External component configuration.

```jsonc
{
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
      "shortcutMenu": [
        "vicinae.root",
        "vicinae.clipboard",
        "vicinae.windows",
        "vicinae.files",
        "vicinae.shell"
      ]
    },

    "overview": {
      "enabled": true,
      "provider": "quickshell-overview",
      "required": false,
      "instanceName": "overview",
      "themeSync": true,
      "configSync": true,
      "expectedVersion": null
    },

    "autoCpuFreq": {
      "enabled": true,
      "required": false
    }
  }
}
```

## 21.1 `required`

Optional integrations should generally use:

```text
false
```

If a user marks an integration required, startup may enter degraded or failed status when it is absent, but the shell should still show diagnostics where possible.

## 21.2 Retained Caelestia services

The `services` list should be populated only after an inventory of the existing configuration.

Do not import all Caelestia modules by default.

---

# 22. `accessibility`

Accessibility-specific configuration.

```jsonc
{
  "accessibility": {
    "visibleFocus": true,
    "tooltips": true,
    "tooltipDelayMs": 500,
    "largerTargets": false,
    "textScale": 1.0,
    "reducedMotion": false,
    "highContrast": false,
    "notificationTimeoutMultiplier": 1.0
  }
}
```

Some fields overlap appearance.

The config normalizer should merge them into one runtime accessibility model.

Avoid two independently writable settings for the same result.

---

# 23. `diagnostics`

Diagnostics and logging.

```jsonc
{
  "diagnostics": {
    "logLevel": "info",
    "logNotificationContents": false,
    "logCommandArguments": true,
    "serviceHealthChecks": true,
    "warnOnUntestedVersions": true,
    "showIntegrationFailures": true
  }
}
```

## 23.1 Sensitive argument redaction

Even when `logCommandArguments` is true, adapters must redact:

- credentials;
- tokens;
- pairing codes;
- private file contents.

---

# 24. Derived Runtime Models

The configuration service should normalize raw config into typed runtime models.

Examples:

```text
BarConfig
ControlCenterConfig
WorkspaceConfig
NotificationConfig
MonitorConfig
CommandConfig
IntegrationConfig
AccessibilityConfig
```

Feature code consumes typed models.

It should not repeatedly access arbitrary paths such as:

```text
config["bar"]["autohide"]["hideDelayMs"]
```

---

# 25. Default and Override Resolution

For scalar values:

```text
runtime override
    ?? machine override
    ?? user config
    ?? system config
    ?? built-in default
```

For objects:

- deep merge known fields;
- reject conflicting type changes;
- preserve explicit `null` only where the schema defines it.

For lists, each field must define its merge policy.

Possible policies:

- replace;
- append;
- merge by stable ID.

Examples:

- `quickControls` → replace;
- `special workspaces` → merge by `id`;
- `notification sound rules` → replace or merge by rule `id`;
- monitor rules → append in order;
- command registry → merge by command ID.

Merge policy must be documented in the schema.

---

# 26. Environment and Path Expansion

Approved variables:

```text
$HOME
$XDG_CONFIG_HOME
$XDG_STATE_HOME
$XDG_CACHE_HOME
$XDG_DATA_HOME
```

Rules:

- expansion is performed by the configuration service;
- missing XDG variables use standard fallback paths;
- no command substitution;
- no wildcard expansion;
- no tilde variants beyond a simple leading `~/` if supported;
- normalized paths are shown in diagnostics.

---

# 27. Runtime Session State

Session state should be stored separately:

```text
$XDG_STATE_HOME/franken-shell/session.json
```

Possible contents:

```jsonc
{
  "schemaVersion": 1,
  "doNotDisturb": false,
  "idleInhibitor": false,
  "lastControlCenterTab": "notifications",
  "lastSelectedCalendarDate": "2026-07-16",
  "lastValidThemeId": "..."
}
```

Do not store:

- notification bodies;
- passwords;
- pairing codes;
- calendar tokens;
- arbitrary window titles.

Session state writes should be debounced and atomic.

---

# 28. Secret Storage

Secrets must never be placed in `config.jsonc`.

## Wi-Fi

Delegate to NetworkManager or the selected backend's secret storage.

## Google Calendar

Use an appropriate secure credential store.

The configuration may store:

- account alias;
- provider ID;
- non-secret calendar preferences.

It must not store OAuth refresh tokens in plain text.

## Polkit and privileged actions

Use system authentication at action time.

Never store passwords.

---

# 29. Settings UI Behaviour

The settings UI should edit the same typed configuration model.

## 29.1 Save model

Recommended behaviour:

- edit a draft copy;
- validate continuously;
- show changed state;
- Save writes atomically;
- Apply updates runtime state;
- Revert restores current persisted values.

For safe settings, Save and Apply may be combined.

For risky settings, keep them distinct.

## 29.2 Live preview

Appropriate for:

- bar edge;
- theme mode;
- reduced motion;
- control-centre width;
- text scale.

Not appropriate for:

- destructive command changes;
- privileged helper policy;
- notification persistence changes;
- integration executable paths without validation.

## 29.3 Reset

Support:

- reset field;
- reset section;
- reset all.

Full reset requires confirmation and backup.

---

# 30. Validation Rules

Validation has two levels.

## 30.1 Schema validation

Checks:

- field names;
- types;
- allowed enum values;
- numeric ranges;
- required IDs;
- object structure.

## 30.2 Semantic validation

Checks relationships.

Examples:

- workspace minimum ≤ maximum;
- workspace group size positive;
- special workspace IDs unique;
- special Hyprland names unique;
- command IDs referenced by settings exist;
- critical battery < warning battery;
- only one control centre edge;
- monitor rules do not contain impossible matches;
- notification rule IDs unique;
- active sound reference exists;
- opacity remains readable;
- gesture conflict policy is coherent;
- paths are allowed;
- no command contains disallowed shell composition.

---

# 31. Error Reporting

A configuration error should report:

```text
file
line/column where available
JSON path
invalid value
expected form
repair suggestion
```

Example:

```text
config.jsonc:142
notifications.sounds.rules[2].match.titleRegex

Invalid regular expression: unclosed group.
The previous valid notification configuration remains active.
```

Do not replace the entire error with a generic “failed to load config.”

---

# 32. Hot Reload

Configuration hot reload should be supported.

## 32.1 Reload-safe settings

May apply immediately:

- colours;
- bar edge;
- autohide;
- workspace labels;
- notification rules;
- command definitions;
- control-centre width;
- tray preferences;
- text scale.

## 32.2 Restart-required settings

May require controlled recreation or restart:

- notification server ownership;
- tray watcher ownership;
- backend implementation changes;
- helper policy;
- major monitor-host strategy.

The settings UI should state when a restart is required.

## 32.3 Atomic surface transition

When bar edge changes:

1. validate;
2. prepare new geometry;
3. close dependent popovers;
4. update host anchors;
5. restore persistent state;
6. report success.

Avoid leaving old and new bars active simultaneously.

---

# 33. Generated Integration Files

Generated files should live under:

```text
$XDG_CACHE_HOME/franken-shell/generated/
```

or:

```text
$XDG_STATE_HOME/franken-shell/generated/
```

depending on whether they are reproducible cache or durable state.

Possible generated files:

- Vicinae theme;
- quickshell-overview workspace/theme config;
- diagnostic snapshot;
- normalized config for debugging.

Generated files must contain a header such as:

```text
Generated by Franken Shell.
Do not edit directly; edit config.jsonc instead.
```

Writes must be atomic.

---

# 34. Suggested Default Configuration

A compact initial user file may look like:

```jsonc
{
  "schemaVersion": 1,

  "appearance": {
    "mode": "dynamic",
    "dynamicColors": {
      "enabled": true,
      "source": "caelestia"
    }
  },

  "bar": {
    "edge": "left",
    "hideInFullscreen": true,
    "autohide": {
      "enabled": false
    },
    "workspacePager": {
      "groupSize": 5
    },
    "networkSpeed": {
      "unit": "bytes",
      "decimals": 0
    }
  },

  "controlCenter": {
    "defaultPage": "notifications",
    "quickControls": [
      "wifi",
      "bluetooth",
      "doNotDisturb",
      "nightLight",
      "idleInhibitor"
    ]
  },

  "workspaces": {
    "numbered": {
      "minimum": 1,
      "maximum": 10,
      "groupSize": 5
    },
    "special": [
      {
        "id": "music",
        "hyprlandName": "music",
        "label": "Music",
        "icon": "music",
        "shortcutHint": "Super+M"
      },
      {
        "id": "movies",
        "hyprlandName": "movies",
        "label": "Movies",
        "icon": "movie",
        "shortcutHint": "Super+A"
      },
      {
        "id": "books",
        "hyprlandName": "books",
        "label": "Books",
        "icon": "book",
        "shortcutHint": "Super+B"
      },
      {
        "id": "discord",
        "hyprlandName": "discord",
        "label": "Discord",
        "icon": "discord",
        "shortcutHint": "Super+D"
      },
      {
        "id": "scratchpad",
        "hyprlandName": "scratchpad",
        "label": "Scratchpad",
        "icon": "terminal",
        "shortcutHint": "Super+S"
      },
      {
        "id": "todo",
        "hyprlandName": "todo",
        "label": "Todo",
        "icon": "checklist",
        "shortcutHint": "Super+T"
      }
    ]
  },

  "notifications": {
    "sounds": {
      "enabled": true,
      "default": null,
      "rules": []
    }
  },

  "commands": {
    "systemMonitor.open": {
      "executable": "missioncenter",
      "arguments": []
    }
  },

  "integrations": {
    "caelestia": {
      "enabled": true
    },
    "vicinae": {
      "enabled": true
    },
    "overview": {
      "enabled": true,
      "provider": "quickshell-overview"
    },
    "autoCpuFreq": {
      "enabled": true
    }
  }
}
```

---

# 35. Configuration Acceptance Criteria

The configuration system is ready when:

1. the shell starts with no user configuration;
2. every omitted field resolves to a valid default;
3. invalid reloads preserve the previous valid state;
4. errors identify a useful configuration path;
5. workspace definitions are consumed by both bar and overview integration;
6. commands are centralized and safely executed;
7. monitor-specific overrides work without duplicating all settings;
8. runtime state is separated from persistent preferences;
9. secrets never enter configuration;
10. generated integration files are reproducible;
11. schema migrations create backups;
12. the settings UI can edit the same model without a parallel schema;
13. configuration changes can be tested with fixture files;
14. optional integration absence is represented through capability state, not config failure.

---

# 36. Open Configuration Questions

The following require later decisions:

- final file format: JSONC, TOML, or another structured format;
- comment-preserving writer strategy;
- exact schema-validation implementation;
- whether machine-specific overrides are needed in the first release;
- whether notification history limits should be configurable initially;
- final throughput unit default;
- exact external system monitor command;
- final Vicinae invocation commands;
- final quickshell-overview generated configuration format;
- monitor identity matching strategy;
- settings that require restart;
- notification title-pattern syntax;
- calendar account preference structure;
- exact theme-source adapter configuration;
- whether bar layout ordering is exposed at all;
- whether unsafe volume above 100% is supported;
- how user-defined icons are referenced;
- package/system default merging rules;
- whether semantic workspace labels should influence overview presentation.

These should be tracked in `open-questions.md` and resolved through implementation research or prototypes.
