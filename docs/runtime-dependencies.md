# Active Shell Runtime Dependencies

## Scope

This inventory covers the active QML and shipped helper assets under `shell/`. Historical prose in `shell/changes.md` and editor policy under `shell/.claude/` are excluded. Caelestia reference-plugin `CMakeLists.txt` files are used only as provenance for native QML module declarations and build/link dependencies; they do not prove that the locally installed plugin has the same binary graph. Facts are directly observed and source-cited. `[INFERENCE]` marks a derived consequence. An **opaque** value or transport is not exposed by the inspected source.

The native QML imports are load-bearing: active files import them without an import fallback. The `caelestia` executable is not classified globally as either required or optional; each CLI-backed feature below records its own behavior. This document contains no proposed architecture or visual direction.

## Runtime host and compositor

| Integration | Observed active contract | Availability and failure boundary | Source anchors |
|---|---|---|---|
| Qt 6 / Quickshell | The entry point is a `ShellRoot` using Qt Quick and Quickshell. `PanelWindow`, `Variants`, `FileView`, `Process`, `PersistentProperties`, desktop-entry, IPC, and service modules are active runtime primitives. | These imports and root types have no alternative host path, so failure to load them prevents the affected QML component—and for the bootstrap imports, the shell—from being constructed. | `shell/shell.qml:8-40`; `shell/components/containers/StyledWindow.qml:1-14`; `shell/modules/launcher/services/Apps.qml:1-20` |
| Wayland layer shell | Common styled windows are `PanelWindow` instances with `WlrLayershell.namespace: caelestia-${name}`. Drawer focus/layer/exclusion and input mask respond to visibility and fullscreen state. | A Wayland layer-shell-capable compositor is required for these windows to behave as authored. | `shell/components/containers/StyledWindow.qml:5-14`; `shell/modules/drawers/ContentWindow.qml:15-32,60-79` |
| Hyprland models and events | `Quickshell.Hyprland` provides monitors, workspaces, toplevels and raw events. `HyprExtras` supplies extra keyboard/device state. Model refreshes are explicitly triggered for selected raw Hyprland events. | The shell is coupled to Hyprland object models and event vocabulary; consumers often null-guard absent focused objects, but there is no compositor-neutral replacement. | `shell/services/Hypr.qml:1-29,174-207,269-274` |
| Hyprland commands/messages | `Hypr.dispatch()` translates selected requests in Lua mode and launches `hyprctl dispatch`. Colour reload sends a direct `Hypr.extras.batchMessage(...)`. No active execution site calls a method spelled `HyprExtras.message(...)`. | Detached `hyprctl` dispatch has no completion/error handler. The extras message is direct protocol/plugin behavior rather than an external process and has no fallback in the caller. | `shell/services/Hypr.qml:40-105`; `shell/services/Colours.qml:81-96` |
| Global shortcuts | `GlobalShortcut` is imported from `Quickshell.Hyprland` with application ID `caelestia`; the shortcut wrapper exposes registered names to active components. | This depends on the compositor/Quickshell global-shortcut integration. The app ID is not a CLI call. | `shell/components/misc/CustomShortcut.qml:1-7`; literal token `shell/components/misc/CustomShortcut.qml:6` |
| Session lock / screencopy | `WlSessionLock` owns lock state; `WlSessionLockSurface` supplies per-screen lock surfaces. `ScreencopyView` captures a screen or Hyprland toplevel, including pre-lock warming because capture may be refused after lock. | No alternate lock protocol or capture backend is implemented. | `shell/modules/lock/Lock.qml:10-40`; `shell/modules/lock/LockSurface.qml:5-14`; `shell/modules/bar/popouts/ActiveWindow.qml:88-95` |
| Idle protocol | `IdleMonitor` instances use configured timeouts, can respect inhibitors, and route idle/return actions. | Missing configured actions are ignored; command and session behavior is documented in the execution table. | `shell/modules/IdleMonitors.qml:17-76` |
| Desktop entries and URL opening | Quickshell enumerates desktop applications, executes entries, and delegates notification hyperlinks to `Qt.openUrlExternally`. | Desktop-entry expansion/launch and external URL routing are host-owned; QML ignores completion/failure. | `shell/modules/launcher/services/Apps.qml:7-20`; `shell/modules/notifications/Notification.qml:432-438`; `shell/modules/sidebar/Notif.qml:142-144` |

## Caelestia CLI

The following table records exact argv as constructed by active QML. Dynamic operands are angle-bracketed. “Feature dependency” is intentionally local to the consuming behavior.

| Command | Consumer/source anchor | Purpose | Required/optional behavior | Failure/fallback behavior |
|---|---|---|---|---|
| `sh -c 'caelestia --version 2>/dev/null'` | About page process at `shell/modules/nexus/pages/AboutPage.qml:39-47` | Display the CLI version. | Optional for the About-page version field only; the rest of the page and native imports do not use this probe. | Stderr is suppressed. Missing/unmatched output produces an empty version; no retry. |
| `caelestia scheme list` | Process `shell/modules/launcher/services/Schemes.qml:39`; exact argv literal `shell/modules/launcher/services/Schemes.qml:43` | Populate launcher scheme choices from JSON. | Required for scheme-list population. | Starts immediately; stdout is parsed without a guard. No process-error or model fallback. |
| `caelestia scheme get -nfv` | Process `shell/modules/launcher/services/Schemes.qml:63`; exact argv literal `shell/modules/launcher/services/Schemes.qml:67` | Read current name, flavour, and variant. | Required for the launcher service’s current-scheme state. | First three output lines are assigned; no exit/error fallback. |
| `caelestia scheme set -n <name> -f <flavour>` | `shell/modules/launcher/services/Schemes.qml:85` | Select a named scheme/flavour. | Required for this launcher action. | Detached after closing the launcher; result is not observed. |
| `caelestia scheme set -v <variant>` | `shell/modules/launcher/services/M3Variants.qml:82` | Select a Material variant. | Required for this launcher action. | Detached after closing the launcher; result is not observed. |
| `caelestia scheme set --notify -m <mode>` | `shell/services/Colours.qml:82` | Change colour mode and ask the CLI to notify. | Required for `Colours.setMode`. | Detached; no result, rollback, or alternate setter. |
| `caelestia wallpaper -r [--no-smart]` | `shell/services/Wallpapers.qml:33`; smart flag `shell/services/Wallpapers.qml:13` | Select a random wallpaper; `--no-smart` is added when smart schemes are disabled. | Required for random-wallpaper action. | Detached and unobserved. |
| `caelestia wallpaper -f <path> [--no-smart]` | `shell/services/Wallpapers.qml:38` | Set an explicit wallpaper. | Required for this setter. | Local `actualCurrent` is updated before dispatch; no rollback on failure. |
| `caelestia wallpaper -f <packaged-fallback> [--no-smart]` | Empty pointer branch `shell/services/Wallpapers.qml:94`; load-failure branch `shell/services/Wallpapers.qml:102`; fallback definition `shell/services/Wallpapers.qml:16` | Restore `assets/wallpaper.webp` when the watched wallpaper pointer is empty or cannot load. | Required for applying the fallback wallpaper; local state can still point at the packaged fallback independently. | Both file-state failures retry through this fixed fallback command, but detached CLI success is not observed. |
| `caelestia wallpaper -p <preview-path> [--no-smart]` | Process declaration `shell/services/Wallpapers.qml:114`; exact argv literal `shell/services/Wallpapers.qml:117` | Produce preview colours for a dynamic scheme. | Used only when the active scheme is `dynamic`; other schemes do not start it. | Successful stdout is loaded as preview colours. No explicit exit/error fallback. |
| `pidof gpu-screen-recorder`, then `caelestia record` | Probe `shell/services/Recorder.qml:44`; stop literal `shell/services/Recorder.qml:54` | Detect recorder process and stop an existing recording. | The CLI command is required for the stop action; `pidof` gates whether it is issued. | Exit-zero probe plus stop intent dispatches detached stop and optimistically clears running/paused; command result is not observed. |
| `pidof gpu-screen-recorder`, then `caelestia record -p` | Probe `shell/services/Recorder.qml:44`; pause literal `shell/services/Recorder.qml:58` | Toggle pause for an existing recording. | Required for pause/resume; issued only when the recorder PID exists. | Local paused state is optimistically toggled; no result handling. Stop intent wins over pause in the branch order. |
| `pidof gpu-screen-recorder`, then `caelestia record <start-args...>` | Probe `shell/services/Recorder.qml:44`; dynamic literal call `shell/services/Recorder.qml:62`; callers `shell/modules/utilities/cards/Record.qml:82-107` | Start fullscreen/region capture with or without sound. Active suffixes are `[]`, `-r`, `-s`, and `-sr`. | Required for recording start. The suffix is caller supplied, so the service itself does not enumerate all possible future callers. | Issued only when the probe reports no PID. State is optimistically set running; no detached result. Intent flags are cleared after the probe decision. |

Two additional quoted `caelestia` tokens are not CLI invocations: the global-shortcut application ID at `shell/components/misc/CustomShortcut.qml:6`, and the configured logo sentinel at `shell/utils/SysInfo.qml:61` (which selects `${Quickshell.shellDir}/assets/logo.svg`). Together with the 13 exact argv literal lines above, these account for all 15 active lines containing a quoted literal `caelestia` token.

## Caelestia native plugin

All nine modules below are active imports without fallback. The eight `Caelestia*` declarations and link sets are proven only for the inspected reference source; `M3Shapes` is separate and has no declaration in that CMake set.

| Native QML module | Concrete active types/consumers | Authorized reference-source declaration/build provenance |
|---|---|---|
| `Caelestia` | `Qalculator` evaluates launcher math; `CUtils` saves/copies items; `AppDb` stores application frequencies; `Toaster` produces battery notices; `ImageAnalyser` is used by coloured icons. | URI and sources are declared at `references/repos/caelestia/plugin/src/Caelestia/CMakeLists.txt:1-9`; links Qt Gui/Quick/Concurrent/SQL and libqalculate at `references/repos/caelestia/plugin/src/Caelestia/CMakeLists.txt:10-15`. Active examples: `shell/modules/launcher/items/CalcItem.qml:4,16-22`; `shell/modules/launcher/services/Apps.qml:68-73`; `shell/modules/BatteryMonitor.qml:17-43`. |
| `Caelestia.Config` | `GlobalConfig`, `TokenConfig`, attached per-screen `Config`/`Tokens`, font/tokens and config status. | URI/sources `references/repos/caelestia/plugin/src/Caelestia/Config/CMakeLists.txt:1-30`; Qt Quick/QuickControls2 links `references/repos/caelestia/plugin/src/Caelestia/Config/CMakeLists.txt:31-33`. Active examples: `shell/components/StyledText.qml:4-15`; `shell/components/containers/StyledWindow.qml:13-14`; `shell/modules/ConfigToasts.qml:25-37`. |
| `Caelestia.Services` | `CavaProvider`, `BeatTracker`, `SessionManager`, `PowerProfiles`, `Cpu`, `Gpu`, `ServiceRef`, and `Lyrics`. | URI/sources `references/repos/caelestia/plugin/src/Caelestia/Services/CMakeLists.txt:1-20`; links Qt DBus, PipeWire, Aubio, Cava, libsensors, and Caelestia core/config/internal libraries at `references/repos/caelestia/plugin/src/Caelestia/Services/CMakeLists.txt:21-29`. Active examples: `shell/services/Audio.qml:9,31-38,190-200`; `shell/modules/IdleMonitors.qml:36-54`; `shell/modules/dashboard/Performance.qml:75-103`; `shell/modules/dashboard/media/LyricList.qml:22-34`. |
| `Caelestia.Internal` | `CircularIndicatorManager`, `LinearIndicatorManager`, `SparklineItem`, `VisualiserBars`, and `HyprExtras`. | URI/sources `references/repos/caelestia/plugin/src/Caelestia/Internal/CMakeLists.txt:1-10`; Qt Gui/Quick/Network links `references/repos/caelestia/plugin/src/Caelestia/Internal/CMakeLists.txt:11-14`. Active examples: `shell/components/controls/CircularIndicator.qml:4,84`; `shell/modules/dashboard/performance/NetworkCard.qml:52`; `shell/services/Hypr.qml:269`. |
| `Caelestia.Components` | `WavyLine`, `LazyListView`, and `ButtonRow`. | URI/sources and Qt Quick link at `references/repos/caelestia/plugin/src/Caelestia/Components/CMakeLists.txt:1-8`. Active examples: `shell/components/controls/CircularProgress.qml:5,69-77`; `shell/modules/sidebar/NotifDockList.qml:10`; `shell/modules/dashboard/dash/Media.qml:123`. |
| `Caelestia.Models` | `FileSystemModel` enumerates wallpaper images and recordings. | URI/source and Qt Gui/Concurrent links at `references/repos/caelestia/plugin/src/Caelestia/Models/CMakeLists.txt:1-7`. Active examples: `shell/services/Wallpapers.qml:7,106-111`; `shell/modules/utilities/cards/RecordingList.qml:57-60`. |
| `Caelestia.Images` | `IUtils.urlForPath` backs caching image URLs. | URI/sources and Qt Gui/Quick/Concurrent links at `references/repos/caelestia/plugin/src/Caelestia/Images/CMakeLists.txt:1-10`. Active consumer `shell/components/images/CachingImage.qml:3-12`. |
| `Caelestia.Blobs` | `BlobGroup`, `BlobInvertedRect`, and `BlobRect` draw Nexus geometry. | URI/blob sources, Qt Quick link, and shader compilation at `references/repos/caelestia/plugin/src/Caelestia/Blobs/CMakeLists.txt:1-19`. Active consumer `shell/modules/nexus/Nexus.qml:4,34-53`. |
| `M3Shapes` | `MaterialShape` and shape enums appear in loading/status/cover-art components. | No target occurs in the authorized Caelestia reference-plugin CMake sources; package, link graph, and persistence are opaque. Active examples: `shell/components/controls/LoadingIndicator.qml:3,7-13`; `shell/modules/bar/components/StatusIcons.qml:67-76`; `shell/components/widgets/CoverArt.qml:41-45`. |

Reference build discovery requires Qt components `ShaderTools`, `Core`, `Qml`, `Gui`, `Quick`, `QuickControls2`, `Concurrent`, `Sql`, `Network`, and `DBus`, with Qt 6.9 project setup; it also discovers libqalculate, PipeWire 0.3, Aubio, Cava (trying `libcava`, then `cava`), and a sensors helper (`references/repos/caelestia/plugin/CMakeLists.txt:1-13`). The helper’s internal libsensors discovery is outside the authorized CMake evidence, but `Sensors::Sensors` is an explicit Services link (`references/repos/caelestia/plugin/src/Caelestia/Services/CMakeLists.txt:21-29`).

`[INFERENCE]` Because each URI is a linked native QML module, an unavailable linked SONAME or incompatible ABI can prevent the entire corresponding import from loading rather than merely disabling the feature that visibly uses that library. The CMake colocation does not prove which individual C++ class uses Qt DBus, PipeWire, Aubio, Cava, libsensors, SQL, or Network, and it does not prove the installed runtime has the same build.

## External commands and scripts

Every active line matching the approved execution-site pattern is listed exactly once in this section: 33 `Process` declarations, 27 `Quickshell.execDetached` calls, three `SessionManager.exec` calls, one `DesktopEntry.execute` call, and two `Qt.openUrlExternally` calls. There is no matching `HyprExtras.message` call. “Unobserved” means QML has no completion/error branch at the cited callsite; it does not claim the host emits no diagnostic.

### Fixed executables and known argv shapes

| Execution site | Exact executable/argv or operation | Feature availability and observed result/fallback |
|---|---|---|
| `shell/modules/areapicker/Picker.qml:194` | `Process [hyprctl, cursorpos, -j]` | Starts with the picker; parses JSON cursor position. No parse/exit fallback. |
| `shell/modules/areapicker/Picker.qml:78` | Detached `sh -c 'wl-copy --type image/png < ' + <temp-path>` | Clipboard-only screenshot path; unquoted concatenated path, unobserved result. |
| `shell/modules/areapicker/Picker.qml:79` | Detached `notify-send -a caelestia-cli -i <temp-path> 'Screenshot taken' 'Screenshot copied to clipboard'` | Sent without waiting for clipboard completion; unobserved result. |
| `shell/modules/areapicker/Picker.qml:81` | Detached `swappy -f <temp-path>` | Editor branch; unobserved result and no alternate editor. |
| `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:134` | `xmllint --xpath //layout/configItem[name and description] /usr/share/X11/xkb/rules/base.xml` | Nonzero exit starts the evdev XML process. |
| `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:145` | `xmllint --xpath //layout/configItem[name and description] /usr/share/X11/xkb/rules/evdev.xml` | Fallback parser; no further fallback. |
| `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:154` | `hyprctl -j getoption input:kb_layout` | Empty/invalid JSON falls back to device discovery. |
| `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:174` | `hyprctl -j devices` | Device-layout fallback; JSON exceptions are ignored, then active-layout fetch runs. |
| `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:192` | `hyprctl -j devices` | Active layout fetch; JSON failure clears active index/label. |
| `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:215` | `hyprctl switchxkblayout all <index>` | On any stop, refreshes active layouts without checking success. |
| `shell/modules/dashboard/Wrapper.qml:21` | Detached `notify-send -a caelestia-shell -u low -h STRING:image-path:<path> ...` | Runs only after profile-picture copy success; notification result unobserved. |
| `shell/modules/dashboard/Wrapper.qml:23` | Detached `notify-send -a caelestia-shell -u critical ...` | Copy-failure notice; result unobserved. |
| `shell/modules/launcher/items/CalcItem.qml:16` | Detached `wl-copy <Qalculator.rawResult>` | Closes launcher; copy result unobserved. |
| `shell/modules/launcher/services/M3Variants.qml:82` | Detached `caelestia scheme set -v <variant>` | CLI-dependent variant action; no result handler. |
| `shell/modules/launcher/services/Schemes.qml:39` | `Process [caelestia, scheme, list]` | Immediate JSON model load; no error fallback. |
| `shell/modules/launcher/services/Schemes.qml:63` | `Process [caelestia, scheme, get, -nfv]` | Immediate/reloadable current-state load; no error fallback. |
| `shell/modules/launcher/services/Schemes.qml:85` | Detached `caelestia scheme set -n <name> -f <flavour>` | Closes launcher; no result handler. |
| `shell/modules/lock/Pam.qml:283` | Reusable `Process`: `sh -c 'fprintd-list $USER'` or `sh -c 'command -v howdy'` | Exit zero sets availability; every other code clears it. Fingerprint then restarts its PAM attempt. |
| `shell/modules/nexus/pages/AboutPage.qml:29` | `quickshell --version` | Version field only; absent output leaves it unset/empty. |
| `shell/modules/nexus/pages/AboutPage.qml:39` | `sh -c 'caelestia --version 2>/dev/null'` | About-field probe; missing CLI is intentionally quiet and produces empty value. |
| `shell/services/Brightness.qml:75` | `sh -c 'asdbctl get'` | Apple-display probe; empty/failure leaves detection false. |
| `shell/services/Brightness.qml:83` | `ddcutil detect --brief` | Builds external-display list; no error fallback. |
| `shell/services/Brightness.qml:177` | Per-monitor `asdbctl get`, `ddcutil -b <bus> getvcp 10 --brief`, or `sh -c 'echo a b c $(brightnessctl g) $(brightnessctl m)'` | Backend chosen by display type; output parsed, no exit fallback. |
| `shell/services/Brightness.qml:216` | Detached `asdbctl set <rounded>` | Optimistic local Apple-display state; result unobserved. |
| `shell/services/Brightness.qml:218` | Detached `ddcutil -b <bus> setvcp 10 <rounded>` | DDC writes are throttled/queued; command result unobserved. |
| `shell/services/Brightness.qml:220` | Detached `brightnessctl s <rounded>%` | Optimistic state; command result unobserved. |
| `shell/services/Colours.qml:82` | Detached `caelestia scheme set --notify -m <mode>` | No result/fallback. |
| `shell/services/FanSpeeds.qml:23` | `sh -c` loop over `/sys/class/hwmon/hwmon*/fan*_input`, reading sibling labels | Empty/failing discovery leaves CPU/GPU sensor paths empty. |
| `shell/services/FanSpeeds.qml:45` | `cat <discovered fan paths...>` | Starts only with at least one path; nonnumeric/zero values become `-1`. |
| `shell/services/Hypr.qml:95` | Detached `hyprctl dispatch <translated-or-direct-request>` | No completion/error fallback. |
| `shell/services/Mono.qml:24` | `python3 $HOME/user_scripts/audio/mono_audio_pipewire.py toggle` | Script is fork-specific/opaque; state file reloads whenever process stops, regardless of code. |
| `shell/services/Nmcli.qml:1449` | `sh -c 'cat /sys/class/net/<interface>/statistics/rx_bytes .../tx_bytes 2>/dev/null'` | Fewer than two values returns empty callback; interface is interpolated unescaped. |
| `shell/services/Nmcli.qml:1471` | `sh -c 'cat /sys/class/net/<interface>/speed 2>/dev/null'` | Missing/nonpositive output clears speed; interface is interpolated unescaped. |
| `shell/services/Nmcli.qml:1490` | `nmcli dev <wifi-command-word> list --rescan yes` | Any exit refreshes network list; success is not checked. |
| `shell/services/Nmcli.qml:1497` | `nmcli monitor`, with `LANG` and `LC_ALL` set to `C.UTF-8` | Persistent monitor; any exit schedules restart after two seconds. |
| `shell/services/Nmcli.qml:1528` | Dynamic process always executes `[nmcli, ...<service args>]` | Captures stdout/stderr/exit; returns structured success/error, detects password requirements and triggers connection failure flows. |
| `shell/services/Recorder.qml:44` | `pidof gpu-screen-recorder` | Exit code chooses stop/pause versus start; intent flags clear after the decision. |
| `shell/services/Recorder.qml:54` | Detached `caelestia record` | Stop action; optimistic local state, unobserved result. |
| `shell/services/Recorder.qml:58` | Detached `caelestia record -p` | Pause action; optimistic local state, unobserved result. |
| `shell/services/Recorder.qml:62` | Detached `caelestia record <caller startArgs...>` | Start action; caller suffix is dynamic, state optimistic, result unobserved. |
| `shell/services/STT.qml:16` | `$HOME/user_scripts/tts_stt/stt_record.sh` | Fork-specific/opaque; toggle starts/stops the process, no failure UI. |
| `shell/services/Shazam.qml:16` | `/home/tony/user_scripts/music/music_recognition.sh` | Machine-specific absolute path; toggle only, no fallback. |
| `shell/services/TTS.qml:16` | `$HOME/user_scripts/tts_stt/tts_speak.sh` | Fork-specific/opaque; toggle only, no fallback. |
| `shell/services/VPN.qml:326` | `nmcli monitor` | Runs only while VPN config is enabled; output debounces status checks, but exit has no restart branch. |
| `shell/services/VPN.qml:336` | Provider status: `tailscale status --json`, `netbird status --json`, `warp-cli status`, or `ip link show` | Provider-specific parser. Known daemon-not-running stderr marks disconnected and suggests `sudo systemctl start <daemon>`; no command fallback. |
| `shell/services/VPN.qml:461` | `warp-cli registration new` | WARP authentication branch; exit zero schedules status check, nonzero does nothing. |
| `shell/services/Wallpapers.qml:33` | Detached random-wallpaper CLI argv | Feature-local behavior in CLI table; result unobserved. |
| `shell/services/Wallpapers.qml:38` | Detached explicit-wallpaper CLI argv | Optimistic state; result unobserved. |
| `shell/services/Wallpapers.qml:94` | Detached packaged-fallback wallpaper argv after empty state file | Explicit input fallback; command result unobserved. |
| `shell/services/Wallpapers.qml:102` | Detached packaged-fallback wallpaper argv after file load failure | Explicit input fallback; command result unobserved. |
| `shell/services/Wallpapers.qml:114` | Preview-colour `Process [caelestia, wallpaper, -p, <path>, <smartArg...>]` | Dynamic-scheme only; no process failure fallback. |

### Dynamic/configured execution

| Execution site | Dynamic source | Observable behavior and boundary |
|---|---|---|
| `shell/modules/IdleMonitors.qml:36` | `SessionManager.exec(action)` for configured idle/return action | Opaque full argv/config value. A false return triggers the next-line detached fallback. No transport is inferred. |
| `shell/modules/IdleMonitors.qml:37` | Detached same configured `action` | Only when `SessionManager` declines; result unobserved. String actions instead route to `Hypr.dispatch`. |
| `shell/modules/launcher/services/Actions.qml:49` | `SessionManager.exec(modelData.command)` from `GlobalConfig.launcher.actions` | Empty arrays are ignored; false triggers detached fallback. |
| `shell/modules/launcher/services/Actions.qml:50` | Detached same configured launcher command | Launcher closes before dispatch; no result handler. |
| `shell/modules/launcher/items/CalcItem.qml:81` | `[...GlobalConfig.general.apps.terminal, fish, -C, "exec qalc -i '<math>'"]` | Configured terminal prefix; calculation text is interpolated inside single quotes without local escaping. Result unobserved. |
| `shell/modules/session/Content.qml:89` | `SessionManager.exec(command)` using configured logout/shutdown/hibernate/reboot argv | Opaque configured commands; false triggers detached fallback. |
| `shell/modules/session/Content.qml:90` | Detached configured session command | Only when `SessionManager` declines; no result handler. |
| `shell/modules/utilities/cards/RecordingList.qml:107` | `[...GlobalConfig.general.apps.playback, <recording path>]` | Configured player prefix; closes panels, no result/fallback. |
| `shell/modules/utilities/cards/RecordingList.qml:117` | `[...GlobalConfig.general.apps.explorer, <recording path>]` | Configured explorer prefix; closes panels, no result/fallback. |
| `shell/services/VPN.qml:384` | Built-in/custom connect command | Built-ins: `pkexec wg-quick up <iface>`, `warp-cli connect`, `netbird up --no-browser`, `tailscale up`, or `<provider> up`; custom config may replace all argv. Parser handles auth URLs and selected provider errors; nonzero otherwise returns without generic refresh. |
| `shell/services/VPN.qml:447` | Built-in/custom disconnect command | Built-ins mirror provider down/disconnect commands; custom config may replace all argv. Every exit schedules status check; no alternate command. |

### Desktop entries and URLs

| Execution site | Operation | Observable behavior |
|---|---|---|
| `shell/modules/launcher/services/Apps.qml:15` | Terminal desktop entry uses detached object `{ command: [...GlobalConfig.general.apps.terminal, <shellDir>/assets/wrap_term_launch.sh, ...entry.command], workingDirectory }`. | Terminal prefix, entry-expanded argv, and working directory are dynamic. Frequency increments first; no completion/error fallback. |
| `shell/modules/launcher/services/Apps.qml:20` | `entry.execute()` for a non-terminal `DesktopEntry`. | Host-owned argv/action resolution; no observed return/failure. |
| `shell/modules/notifications/Notification.qml:437` | `Qt.openUrlExternally(link)` for an expanded popup’s Markdown link. | Notification-provided URL; return/failure ignored, popup flag cleared. |
| `shell/modules/sidebar/Notif.qml:143` | `Qt.openUrlExternally(link)` for an expanded sidebar notification. | Notification-provided URL; return/failure ignored, sidebar closes. |

The direct configured command families are therefore `GlobalConfig.general.apps.terminal`, `.playback`, and `.explorer`; `GlobalConfig.launcher.actions[*].command`; configured session commands; idle/return actions; and custom VPN connect/disconnect commands. `DesktopEntry.execute` remains host-owned and non-enumerable. A detached call is treated above according to feature impact, not presumed optional.

## System and remote services

| Service/interface | Observed contract | Failure, fallback, and evidence boundary | Source anchors |
|---|---|---|---|
| Notification server | `Quickshell.Services.Notifications.NotificationServer` advertises actions, hyperlinks, images, markup, and persistence; incoming notifications are tracked. DND/sidebar/fullscreen suppress popup display, not receipt/history. | Missing history initializes `[]`; actions invoke notification-supplied actions; final close calls `dismiss()`. `[INFERENCE]` This is conventionally the freedesktop Notifications service, but no bus name/interface literal appears in active QML. | `shell/services/Notifs.qml:20-37,67-130`; `shell/services/NotifData.qml:203-243` |
| System tray | `Quickshell.Services.SystemTray` enumerates `SystemTray.items`; left/right clicks activate/secondary-activate items. | Missing items yield an empty tray. `[INFERENCE]` StatusNotifier/DBusMenu are likely standardized backends, but names are not literal. | `shell/modules/bar/components/Tray.qml:65-78`; `shell/modules/bar/components/TrayItem.qml:10-24` |
| MPRIS | Quickshell MPRIS supplies players, metadata, controls, art URL, capability and position. Selection falls through manual-playing, any playing, configured identity, first, then null. | No player yields null/empty states and disabled controls. `[INFERENCE]` `org.mpris.MediaPlayer2.*` is conventional, not a literal observed bus name. | `shell/services/Players.qml:1-46,64-157`; `shell/modules/dashboard/media/Details.qml:25-111` |
| Remote media art | Track art uses MPRIS `trackArtUrl`; otherwise a YouTube watch URL is converted to `https://img.youtube.com/vi/<id>/hqdefault.jpg`. | Missing/invalid metadata yields empty art URL; no alternate remote provider. | `shell/services/Players.qml:29-44` |
| PipeWire/audio | `Quickshell.Services.Pipewire` exposes default sink/source, nodes, streams, volume/mute and preferred defaults. Native `CavaProvider`/`BeatTracker` add visualizer/beat data. | Null/not-ready nodes are guarded. Cava provider is reference-count gated. Reference CMake proves module-wide PipeWire/Aubio/Cava links, not that they back Quickshell’s own PipeWire singleton. | `shell/services/Audio.qml:1-40,44-114,145-200`; `references/repos/caelestia/plugin/src/Caelestia/Services/CMakeLists.txt:21-29` |
| UPower / power profiles | `Quickshell.Services.UPower` exposes battery state/times; native `PowerProfiles` exposes profile and degradation controls. Critical battery calls `SessionManager.hibernate()` after five seconds. | No-battery display is explicit. Hibernate has no caller fallback. `[INFERENCE]` UPower and power-profiles-daemon are conventional transports; no bus names are literal. | `shell/modules/bar/popouts/Battery.qml:1-44,89-106,154-205`; `shell/modules/BatteryMonitor.qml:29-55` |
| Bluetooth | `Quickshell.Bluetooth` enumerates adapter/devices and controls enabled, discovery, connection, pairing, and forgetting. | Optional adapter accesses are guarded; missing adapter renders off/disabled; transitional states disable controls. `[INFERENCE]` BlueZ is the likely standardized backend, but `org.bluez` is not literal. | `shell/modules/bar/popouts/Bluetooth.qml:27-72,127-169`; `shell/modules/nexus/pages/bluetooth/BluetoothPairing.qml:76-115` |
| NetworkManager | Active integration is explicitly through `nmcli`: query/control Wi-Fi, Ethernet, saved profiles, radios, monitoring and password/error flows. | List failures can return `[]`; Wi-Fi-status failure can preserve current state; password-like stderr is classified; persistent main monitor restarts after two seconds. `[INFERENCE]` `nmcli` normally communicates with NetworkManager, but no NetworkManager D-Bus name is observed. | `shell/services/Nmcli.qml:41-82,186-206,423-466,752-810,1260-1313,1490-1605` |
| PAM | Password uses `PamContext`; fingerprint/Howdy use manual contexts and shipped PAM stacks. | Only `PamResult.Success` unlocks; Error/MaxTries/Failed are explicit states. Availability probes determine whether fingerprint/Howdy paths activate. | `shell/modules/lock/Pam.qml:60-106,117-158,209-230,283-288`; `shell/assets/pam.d/passwd:1-6`; `shell/assets/pam.d/fprint:1-3`; `shell/assets/pam.d/howdy:1-3` |
| Session management | Native `SessionManager` emits sleep/lock/unlock/resume signals, executes configured commands, and exposes hibernate. | Backing service/transport is opaque. Reference CMake lists `sessionmanager.cpp` and a module-wide Qt DBus link, but this does **not** establish logind/login1 or any bus/object/interface. `exec()` false alone triggers detached fallback. | `shell/modules/IdleMonitors.qml:25-55`; `shell/modules/lock/Pam.qml:143-151`; `shell/modules/session/Content.qml:76-103`; `references/repos/caelestia/plugin/src/Caelestia/Services/CMakeLists.txt:1-29` |
| Weather/geolocation | Native `Requests` calls ipinfo for IP location, Open-Meteo geocoding/forecast, Nominatim reverse geocoding, and BigDataCloud reverse-geocode fallback. | Invalid/missing IP `loc` prevents forecast. Reverse geocoding has the explicit BigDataCloud alternate; other calls have no explicit failure callback. | `shell/services/Weather.qml:29-51,104-157,159-225,271-280` |
| Lyrics | Native `Lyrics` consumes active MPRIS artist/title/album/length and exposes timed lyric lookup/seek. UI names Auto, Local, LRCLIB, and NetEase backends. | Loading/lyrics/no-lyrics states are explicit. URLs/transports for LRCLIB and NetEase are opaque; no endpoint is invented. | `shell/modules/dashboard/media/LyricList.qml:17-34,72-105,249-254,301-305`; `shell/modules/nexus/pages/ServicesPage.qml:12-27,137-143` |
| VPN providers | The service invokes Tailscale, NetBird, Cloudflare WARP, WireGuard, generic/custom providers and uses `nmcli monitor` to trigger checks. | Availability and errors are provider/command specific; there is no universal VPN backend or fallback. | `shell/services/VPN.qml:26-119,307-381,384-468` |
| Brightness/display control | `asdbctl`, `ddcutil`, and `brightnessctl` provide Apple, external DDC, and ordinary display control. | Detection chooses a backend. Writes are optimistic and unobserved; DDC writes are throttled. | `shell/services/Brightness.qml:62-92,177-238` |

No active QML contains a literal D-Bus bus name, object path, or interface name for notifications, MPRIS, UPower, power profiles, Bluetooth, tray, NetworkManager, or session management. Standard names above are deliberately `[INFERENCE]`. In particular, native `SessionManager` is not described as logind-backed.

## Environment variables

| Variable | Exact active value/default and consumer | Source anchors |
|---|---|---|
| `QS_CRASHREPORT_URL` | Forced to `https://github.com/caelestia-dots/shell/issues/new?template=crash.yml`. | `shell/shell.qml:1` |
| `QS_NO_RELOAD_POPUP` | Default `1`. | `shell/shell.qml:2` |
| `QS_DROP_EXPENSIVE_FONTS` | Default `1`. | `shell/shell.qml:3` |
| `QSG_RENDER_LOOP` | Default `threaded`. | `shell/shell.qml:4` |
| `QT_QUICK_FLICKABLE_WHEEL_DECELERATION` | Default `10000`. | `shell/shell.qml:5` |
| `HOME` | No fallback; base for all home/XDG defaults, `.face`, and three fork-specific scripts. | `shell/utils/Paths.qml:11-18`; `shell/services/Mono.qml:19,24,27`; `shell/services/STT.qml:19`; `shell/services/TTS.qml:19` |
| `XDG_PICTURES_DIR` | Value or `$HOME/Pictures`; exposed as `Paths.pictures`, with no direct active member consumer observed. | `shell/utils/Paths.qml:12` |
| `XDG_VIDEOS_DIR` | Value or `$HOME/Videos`; base for default recordings root. | `shell/utils/Paths.qml:13,23` |
| `XDG_DATA_HOME` | `(value or $HOME/.local/share)/caelestia`; no direct active `Paths.data` consumer observed. | `shell/utils/Paths.qml:15` |
| `XDG_STATE_HOME` | `(value or $HOME/.local/state)/caelestia`; base for scheme, notifications, wallpaper pointer, and app DB. | `shell/utils/Paths.qml:16`; `shell/services/Colours.qml:52-69`; `shell/services/Notifs.qml:55-70`; `shell/services/Wallpapers.qml:14`; `shell/modules/launcher/services/Apps.qml:68-73` |
| `XDG_CACHE_HOME` | `(value or $HOME/.cache)/caelestia`; base for notification image cache. | `shell/utils/Paths.qml:17,20-21`; `shell/services/NotifData.qml:73-95` |
| `XDG_CONFIG_HOME` | `(value or $HOME/.config)/caelestia`; active QML uses it for `bar-extras.json`. | `shell/utils/Paths.qml:18`; `shell/services/BarConfig.qml:16-30` |
| `CAELESTIA_WALLPAPERS_DIR` | Value or `Paths.absolutePath(GlobalConfig.paths.wallpaperDir)`; recursive wallpaper root. | `shell/utils/Paths.qml:22`; `shell/services/Wallpapers.qml:25-29,106-112` |
| `CAELESTIA_RECORDINGS_DIR` | Value or `${Paths.videos}/Recordings`; recording browser root. | `shell/utils/Paths.qml:23`; `shell/modules/utilities/cards/RecordingList.qml:57-60` |
| `CAELESTIA_LIB_DIR` | Value or `/usr/lib/caelestia`; defined as `Paths.libdir`, with no direct active consumer observed. | `shell/utils/Paths.qml:24` |
| `CAELESTIA_XKB_RULES_PATH` | Value or `/usr/share/X11/xkb/rules/base.lst`; keyboard description parser. | `shell/services/Hypr.qml:211-240` |
| `USER` | No fallback; displayed by system info and shell-expanded in the fingerprint probe. | `shell/utils/SysInfo.qml:20`; `shell/modules/lock/Pam.qml:129,283` |
| `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP` | First nonempty value is displayed as window manager/desktop. | `shell/utils/SysInfo.qml:21` |
| `SHELL` | Final slash-separated segment is displayed as shell name. | `shell/utils/SysInfo.qml:22` |
| `LANG`, `LC_ALL` | The main `nmcli monitor` child explicitly receives `C.UTF-8`. | `shell/services/Nmcli.qml:1497-1503` |

`settings.watchFiles` is explicitly disabled independently of the reload-popup environment default (`shell/shell.qml:18`). Environment path overrides are accepted as supplied; `Paths.qml` does not trim or normalize them (`shell/utils/Paths.qml:11-24`).

## Configuration and state paths

### Canonical roots and files

| Path/formula | Producer/consumer | Observed failure/fallback behavior | Source anchors |
|---|---|---|---|
| `${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/bar-extras.json` | Blocking `FileView`/JSON adapter for `showCpu`, `showRam`, `showUpload`, `showDownload`, and `showLyrics`, all defaulting true; adapter updates write. | `printErrors: false`; no local load-failure branch, so exact missing/malformed handling is opaque. | `shell/utils/Paths.qml:18`; `shell/services/BarConfig.qml:10-30` |
| `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json` | Watched colour scheme JSON with name/flavour/mode/colours. | Parsing is unguarded; no local load-failure recovery. | `shell/services/Colours.qml:52-69,116-120` |
| `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/notifs.json` | Debounced notification-history serialization. | Missing file marks loaded and schedules `[]`; other load/parse failures have no local recovery. | `shell/services/Notifs.qml:55-70,105-130` |
| `${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/imagecache/notifs/<hash>.png` | Cached non-icon notification images. | QML supplies no save-failure callback; original image state remains, with no feature-local retry. | `shell/utils/Paths.qml:17,20-21`; `shell/services/NotifData.qml:73-95,195-197` |
| `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/wallpaper/path.txt` | Watched pointer to actual current wallpaper. | Empty content or load failure selects packaged fallback and invokes the wallpaper CLI with `-f`. | `shell/services/Wallpapers.qml:14,85-104` |
| `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/apps.sqlite` | `AppDb` launcher-frequency database. | QML exposes no open/schema failure path; persistence failure behavior is opaque. | `shell/modules/launcher/services/Apps.qml:10-12,68-73` |
| `$HOME/.face` | Dashboard and lock profile picture; dashboard picker overwrites with `CUtils.copyFile`. | Success/failure controls separate `notify-send` branches. | `shell/modules/dashboard/dash/User.qml:90-92`; `shell/modules/lock/center/ProfilePic.qml:48-50`; `shell/modules/dashboard/Wrapper.qml:13-23` |
| `$CAELESTIA_WALLPAPERS_DIR` or `absolutePath(GlobalConfig.paths.wallpaperDir)` | Recursive wallpaper/image categories. | Empty model displays no images; backing config path itself is opaque. | `shell/utils/Paths.qml:22`; `shell/services/Wallpapers.qml:25-29,106-112` |
| `$CAELESTIA_RECORDINGS_DIR` or `${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings` | Recording list filters `recording_*.mp4`. | The recorder CLI is not passed this path. Correspondence between CLI output and browser root is opaque. | `shell/utils/Paths.qml:13,23`; `shell/modules/utilities/cards/RecordingList.qml:57-60`; `shell/services/Recorder.qml:44-63` |
| `~/.local/state/caelestia/sequences.txt` | Terminal launcher wrapper prints stored sequences, then `exec`s its target. | Fixed tilde path ignores `XDG_STATE_HOME`; missing/unreadable file is silenced and target still executes. | `shell/assets/wrap_term_launch.sh:1-5`; `shell/modules/launcher/services/Apps.qml:14-17` |
| `/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png` | Area-picker screenshot temporary; then `wl-copy`/`notify-send` or `swappy`. | QML supplies no save-failure callback and contains no deletion. Cleanup/lifetime outside QML is opaque. | `shell/modules/areapicker/Picker.qml:74-84` |

`Paths.toLocalFile` resolves a URL and delegates local-file conversion; `absolutePath` expands the first `~`, `$HOME`, or `${HOME}` match; `shortenHome` replaces the first home occurrence with `~` (`shell/utils/Paths.qml:26-36`). Quickshell `root:/` resolution and non-local URL behavior beyond these calls are opaque in the inspected source.

### PersistentProperties and plugin configuration boundary

Active QML does not expose a backing directory or filename for Quickshell `PersistentProperties`. Its reload IDs are identifiers, not filenames:

| Feature | Persisted fields | Exact reload ID | Source anchor |
|---|---|---|---|
| Game mode | `enabled` | `gameMode` | `shell/services/GameMode.qml:32-38` |
| Idle inhibitor | `enabled`, `enabledSince`, `enabledOnBattery` | `idleInhibitor` | `shell/services/IdleInhibitor.qml:32-40` |
| Notifications | `dnd` | `notifs` | `shell/services/Notifs.qml:75-80` |
| Player selection | `manualActive` | `players` | `shell/services/Players.qml:60-66` |
| Recorder | `running`, `paused`, `elapsed` | `recorder` | `shell/services/Recorder.qml:34-41` |
| Sidebar | `expandedNotifs` | `sidebar` | `shell/modules/sidebar/Props.qml:3-6` |
| Utilities | recording-list/confirmation/mode state | `utilities` | `shell/modules/utilities/Wrapper.qml:20-25` |
| Per-screen UI | visibility and dashboard state | no explicit ID | `shell/components/ScreenState.qml:3-17` |

`GlobalConfig`, `TokenConfig`, and per-monitor overlays are native `Caelestia.Config` objects, but active QML does not expose their backing paths. The native-module table above uses CMake only to establish the `Caelestia.Config` URI/types and link graph (`references/repos/caelestia/plugin/src/Caelestia/Config/CMakeLists.txt:1-33`). Therefore no `$XDG_CONFIG_HOME/caelestia/shell.json`, token file, or monitor-overlay filename is asserted as an active-shell fact.

The compiled **reference-plugin contract**, not an active-QML path claim, is more specific: its global config and token backends are `QStandardPaths::GenericConfigLocation/caelestia/shell.json` and `.../shell-tokens.json` (`references/repos/caelestia/plugin/src/Caelestia/Config/config.cpp:29-30,53-54`; `references/repos/caelestia/plugin/src/Caelestia/Config/tokens.cpp:10-12,20-21`). Per-monitor overlays are `QStandardPaths::GenericConfigLocation/caelestia/monitors/<screen>/shell.json` and `.../shell-tokens.json` (`references/repos/caelestia/plugin/src/Caelestia/Config/monitorconfigmanager.cpp:11-13,31-35,47-52`). `[INFERENCE]` On an XDG-configured Linux host, those formulas conventionally correspond to `$XDG_CONFIG_HOME/caelestia/{shell.json,shell-tokens.json}` and `$XDG_CONFIG_HOME/caelestia/monitors/<screen>/{shell.json,shell-tokens.json}`; the active QML does not itself expose or validate that mapping.

### Assets, personal scripts, and system inputs

| Path | Active use and behavior | Source anchors |
|---|---|---|
| `${Quickshell.shellDir}/assets/logo.svg` | Default/Caelestia logo. | `shell/utils/SysInfo.qml:16,61-63` |
| `Quickshell.shellPath("assets/wallpaper.webp")` | Wallpaper state/CLI fallback and featured Nexus wallpaper. | `shell/services/Wallpapers.qml:16`; `shell/modules/nexus/pages/wallandstyle/WallpaperSelect.qml:74-80` |
| `assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf` | Shell font loader. | `shell/modules/GSFLoader.qml:4-5` |
| `${Quickshell.shellDir}/assets/wrap_term_launch.sh` | Terminal desktop-entry wrapper. | `shell/modules/launcher/services/Apps.qml:14-17` |
| `Quickshell.shellPath("assets/pam.d")` | Password, fingerprint, and Howdy PAM configurations. | `shell/modules/lock/Pam.qml:79-80,229-230` |
| `$HOME/.config/dusky/settings/mono_audio` | Fork-specific mono state; `True` means active. | `shell/services/Mono.qml:16-21` |
| `$HOME/user_scripts/audio/mono_audio_pipewire.py` | Fork-specific mono toggle. | `shell/services/Mono.qml:24-28` |
| `$HOME/user_scripts/tts_stt/stt_record.sh` | Fork-specific speech-to-text toggle. | `shell/services/STT.qml:16-20` |
| `$HOME/user_scripts/tts_stt/tts_speak.sh` | Fork-specific text-to-speech toggle. | `shell/services/TTS.qml:16-20` |
| `/home/tony/user_scripts/music/music_recognition.sh` | Machine-specific music recognition; unlike adjacent scripts, it does not follow `HOME`. | `shell/services/Shazam.qml:16-20` |
| `/etc/os-release` | OS identity and icon lookup; no local load-failure branch. | `shell/utils/SysInfo.qml:46-68` |
| `/proc/sys/kernel/osrelease`, `/proc/sys/kernel/hostname`, `/proc/uptime` | Kernel, hostname, and 15-second uptime refresh. | `shell/utils/SysInfo.qml:82-120` |
| `/sys/class/dmi/id/sys_vendor`, `product_name`, `bios_version` | Board/firmware metadata with suppressed errors. | `shell/utils/SysInfo.qml:92-107` |
| `/proc/net/dev` | Aggregate network byte parsing; empty content leaves prior state. | `shell/services/NetworkUsage.qml:151-167` |
| `/sys/class/hwmon/hwmon*/fan*_input` and sibling `fan*_label` | First CPU/GPU-labelled fan sensors; missing sensors remain `-1`. | `shell/services/FanSpeeds.qml:10-15,23-79` |
| `/sys/class/net/${interfaceName}/speed` | Ethernet speed; read errors suppressed, invalid/nonpositive output clears value. | `shell/services/Nmcli.qml:1103-1113,1471-1487` |
| `/sys/class/net/${interfaceName}/statistics/{rx_bytes,tx_bytes}` | Since-boot interface bytes; insufficient output returns empty string. | `shell/services/Nmcli.qml:1116-1125,1449-1469` |
| `$CAELESTIA_XKB_RULES_PATH` or `/usr/share/X11/xkb/rules/base.lst` | Hypr keyboard description map. | `shell/services/Hypr.qml:211-240` |
| `/usr/share/X11/xkb/rules/base.xml`, then `/usr/share/X11/xkb/rules/evdev.xml` | Bar keyboard-layout descriptions through `xmllint`; evdev is the one fallback. | `shell/modules/bar/popouts/kblayout/KbLayoutModel.qml:128-151` |

The personal scripts are runtime dependencies of their individual fork-specific features and are opaque here. Missing Mono/STT/TTS/Shazam executables have no local user-facing error branch; Mono merely reloads its state file when its process stops (`shell/services/Mono.qml:24-28`).
