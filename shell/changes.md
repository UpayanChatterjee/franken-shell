# Caelestia Shell — Hyprland 0.55 Lua Migration

## 2026-07-14: Upstream merge — 18 commits up to `aa836f2` (2.1.0.r18)

**Repo:** `~/projects/caelestia-merge`, branch `local`; merge commit/baseline `d4c1e4e7`. Merged upstream text-control redesign, per-screen `ShellState`/component hooks, Howdy lock support, `lock.enabled`, inhibit-idle-while-charging, compact tray improvements, and assorted bar/calendar/menu/lock/Nexus fixes. Deployed only runtime paths (`assets components modules services utils shell.qml LICENSE`); package-owned plugin/build files were left to the package installation.

**Conflict handling:** Ported the custom Media/Performance/Weather dashboard shortcuts from deleted global `DashboardState`/`Visibilities` to upstream's per-screen `ShellState.forActive()` and `dashboardTab`; adopted `ScreenState` and removed obsolete `DashboardState`. Preserved `settings.watchFiles: false`, `VicinaeBridge`, always-overlay-over-fullscreen behavior, Caps/Num polling, and all custom services/popouts/assets.

**Verified:** 72 changed QML files produced no `qmllint` diagnostics; clean shell restart reached `Configuration Loaded`; dashboard shortcuts, drawers/OSD, bar, launcher and lock screen confirmed working. `mine-base` advanced to `d4c1e4e7`.

## 2026-06-27: Upstream merge — 2.0.3 → **2.1.0**, 17 commits up to `90a1b46` (via caelestia-merge)

**Repo:** `~/projects/caelestia-merge`, branch `local`. Merge commit `4b855796` (parents: prior baseline `6d45d90d` + upstream `90a1b466`, merge-base `c488b8e`). 53 files changed, +1644/−1274. Deployed runtime QML to `~/.config` via `rsync -ac --delete` over `assets components modules services utils` + `shell.qml LICENSE` (infra dirs `plugin/ nix/ scripts/ extras/ flake.* CMakeLists.txt README .github` and keepers `changes.md`, `.claude/`, `.qmlls.ini` excluded).

**Baseline repair first:** the `mine-base` tag was stale — it pointed at `7dd12cba` (pre-dating the 2026-06-24 merge) instead of `local`@`6d45d90d`. Confirmed live `~/.config` was byte-identical to the `local` worktree (so the true deployed baseline was `6d45d90d`) and reset `git tag -f mine-base local` **before** merging, so the deploy-diff `mine-base..local` captured exactly the 2.1.0 delta and not a re-application of the last merge.

**Upstream 2.1.0 highlights pulled in:** new **nexus Ethernet section** (#1602 — `modules/nexus/common/EthernetSection.qml`, `modules/nexus/pages/network/EthernetDetailPage.qml`) + nexus/network refactor; sidebar `showOnHover` + drawers `isOpen` IPC (#1505); click-to-seek on sliders (#1539); improved bar clock date; localized geocoding + city-name formatting (#1593); `M3TextField` control; GPU-detection without chained procs; layer-transparency/blur clamps; `wrap_term_launch.sh` asset; misc fixes (wallpaper launcher crash, power-button centering, window-pid→string).

**Components refactor — 14 upstream deletions handled by 3-way merge:** upstream removed unused controls/components (#1625): `components/{ConnectionHeader,ConnectionInfoSection,PropertyRow,SectionContainer,SectionHeader}.qml`, `components/controls/{CollapsibleSection,SpinBoxRow,SplitButtonRow,StyledInputField,SwitchRow,ToggleButton,ToggleRow}.qml`, `components/effects/InnerBorder.qml`, and `services/Network.qml`. **Verified none were fork-modified** (`git diff c488b8e..6d45d90d` empty for all 14) and **no surviving file references them** — the `SectionHeader`/`ToggleRow` still used by nexus pages resolve to the separate `modules/nexus/common/` copies (imported via `qs.modules.nexus.common`), not the deleted `components/` ones. A naive rsync-of-`/etc/xdg` would have wrongly kept these; the git merge against base `c488b8e` deleted them correctly.

**Conflicts:** none — git auto-merged cleanly. Only **3 files** had genuine fork∩upstream overlap (`modules/bar/Bar.qml`, `modules/Shortcuts.qml`, `modules/bar/popouts/Network.qml`); verified BOTH sides survived: fork's sysmon/netspeed hit-testing + upstream's `id→entryId`/`modelData` refactor in Bar.qml; fork's dashboard shortcuts + upstream's `isOpen` IPC in Shortcuts.qml; fork's WiFi signal-% + upstream's `interface→iface` rename in Network.qml. All 13 fork keepers present (VicinaeBridge, BarConfig, FanSpeeds, Mono, Shazam, STT, TTS, NetworkSpeed, SystemMonitor popout, xdm.png, portal gif). Hypr.qml Timer-only Caps/Num + `dispatch()` Lua translation intact; IdleMonitors on `SessionManager`; `shell.qml` keeps `VicinaeBridge {}`. qmllint clean on all merge-touched + new files.

**Cross-check:** `diff -rq /etc/xdg/quickshell/caelestia ~/.config` shows **0 upstream files missing** from live, 13 fork-only extras, 26 fork-modified upstream files — exactly as expected.

**Verified (2026-06-27):** clean `caelestia shell -d` restart → `Configuration Loaded`, stable single instance, holds `org.freedesktop.Notifications` seat (not mako), fork IPC targets (`hypr.refreshDevices`, `gameMode`) registered. Only benign warnings remain (missing KDE icon themes, `Config.bar accessed without a screen` init-timing — both pre-existing). Earlier CoverVisualiser/Notification null-property warnings were transient artifacts of the old instance hot-reloading mid-rsync, absent on clean load. Backup of pre-deploy `~/.config` at `~/.cache/caelestia-config-backup-20260627-221313.tar.gz`. `mine-base` advanced to `4b855796`.

## 2026-06-24: Upstream merge — 7 commits up to `c488b8e` (via caelestia-merge)

**Repo:** `~/projects/caelestia-merge`, branch `local`. Merge commit `6d45d90d` (parents: reconcile `b98da63c` + upstream `c488b8e`). Deployed runtime QML to `~/.config` via `rsync` (infra dirs `plugin/ nix/ scripts/ extras/` and keepers `changes.md`, `.claude/` excluded).

**Reconcile first:** `~/.config` had drifted from the `local` branch — folded the live edits in before merging: `shell.qml` (`VicinaeBridge {}`), `modules/VicinaeBridge.qml` (fork-only), and the `IdleMonitors` SessionManager fix below.

**Upstream changes pulled in:** round + animated dash calendar; non-systemd support (#1607); blobs-gaining-energy-on-slow-frames fix; nexus **Apps page** + **Notification settings** (#1597, new files `AppsPage.qml`, `apps/AllApps.qml`, `apps/AppInfo.qml`, `services/NotificationsPage.qml`, `common/BlobPopup.qml`, `common/PopupRow.qml`, `containers/VerticalFadeListView.qml`); don't reload on unrelated file events.

**Conflicts:** none — git auto-merged all 65 changed files against merge-base `067938d6`. Verified post-merge: all 10 fork-only files present (VicinaeBridge, BarConfig, FanSpeeds, Mono, Shazam, STT, TTS, NetworkSpeed, SystemMonitor, xdm asset); Hypr.qml Timer customizations intact; SessionManager (not LogindManager); braces balanced.

**Verified (2026-06-24):** `caelestia shell -d` loads clean (234 MB PSS, no errors in qslog). Backup of pre-deploy `~/.config` at `~/.cache/caelestia-config-backup-20260624-090745.tar.gz`.

## 2026-06-24: Migrate `IdleMonitors` from `LogindManager` to `SessionManager`

**File:** `modules/IdleMonitors.qml` (brought in line with packaged upstream).

**Symptom:** A fresh `caelestia shell -d` fails to load: `Type IdleMonitors unavailable` → `caused by @modules/IdleMonitors.qml[30:5]: LogindManager is not a type`. The bar had survived 2.6 days only because the old `qs` process held a compatible plugin in memory; any restart/reboot would have hit this.

**Root cause:** `LogindManager` was a Caelestia C++ **plugin** type (`Caelestia.Internal.logindmanager`), *not* a quickshell type. Upstream caelestia (`caelestia-shell-git 2.0.3.r8.gc488b8e`) refactored it into `Caelestia.Services.SessionManager`. The installed plugin (`/usr/lib/qt6/qml/Caelestia/`) no longer registers `LogindManager` under `Caelestia.Internal`; our forked QML still referenced the old name, so the config failed to load. (Unrelated to quickshell — installed quickshell-git was fine.)

**Fix:** Adopted the packaged `IdleMonitors.qml`:
- imports: drop `Caelestia.Internal`, add `import QtQuick` + `import Caelestia.Services`.
- `handleIdleAction` non-string branch: `else if (!SessionManager.exec(action)) Quickshell.execDetached(action);`.
- replace `LogindManager {}` with `Connections { target: SessionManager; onAboutToSleep/onLockRequested/onUnlockRequested }`.

This restores lock-on-sleep and lock/unlock-on-request with the installed plugin. Our fork's copy of this file had no local modifications (it was just stale upstream), so this is a clean adoption. Other files still use `Caelestia.Internal` for unrelated types — left untouched.

**Verified (2026-06-24):** `caelestia shell -d` loads with no errors in the qslog; `pgrep -f 'qs -c caelestia'` shows the bar at ~242 MB PSS. Also noted the bar leaks ~140 MB/day (PSS 260 MB fresh → 628 MB after 2.6 days uptime) — worth watching after the pending upstream merge.

## 2026-06-21: Fix mako hijacking the notification seat (startup race)

**File:** `~/.config/systemd/user/mako.service.d/override.conf` (new). No edits to the packaged `mako.service`, the `caelestia-shell` wrapper, or `execs.conf`.

**Symptom:** Notifications stopped appearing in the caelestia shell — mako was rendering all of them, despite the shell running fine.

**Root cause:** Completes the `2026-06-11` seat-handover fix below. The `caelestia-shell` wrapper stops mako then `exec`s quickshell, but quickshell's `NotificationServer` (`services/Notifs.qml:83`) only registers the `org.freedesktop.Notifications` D-Bus name *after* QML finishes loading — a multi-second window. Any notification emitted during that window re-activates mako via its D-Bus activation file (`/usr/share/dbus-1/services/fr.emersion.mako.service`), mako grabs the free seat, and quickshell can never reclaim it (mako doesn't allow D-Bus name replacement). The wrapper's `systemctl --user stop mako` cannot win this race reliably.

**Fix:** A systemd drop-in gates mako's D-Bus activation behind `ExecCondition`s so it only ever starts when **no** higher-priority handler is alive — making mako the lowest-priority, last-resort daemon:

```ini
[Service]
ExecCondition=/bin/sh -c '! pgrep -f "[q]s -c caelestia" >/dev/null'
ExecCondition=/bin/sh -c '! pgrep -x plasmashell >/dev/null'
```

All `ExecCondition=` must pass for mako to start. While `qs -c caelestia` (Hyprland) or `plasmashell` (KDE Plasma) is running, mako is blocked → the seat stays free for the real handler. When both are gone, the conditions pass and mako D-Bus-activates as the fallback (the reverse-direction behavior from `2026-06-11` is preserved). The `[q]s` bracket trick keeps `pgrep` from matching the `ExecCondition`'s own `sh`. Extend with one more line per process for any future DE/daemon.

**Recovery after install:** `systemctl --user daemon-reload` → `systemctl --user stop mako` → `caelestia shell -k` → relaunch via `caelestia-shell -d` so the shell claims the freed seat.

**Verified (2026-06-21):** after recovery, `busctl --user status org.freedesktop.Notifications` reports the `qs -c caelestia` PID (not mako); `notify-send` renders in caelestia and mako does **not** reactivate while the shell is up; `ExecCondition` exit codes confirmed (caelestia up → exit 1 = blocked; shell absent → exit 0 = fallback open).

## 2026-06-17: New `anime` special workspace for Seanime Denshi (Super+A)

**Files:** `~/.config/hypr/variables.lua`, `~/.config/hypr/hyprland/keybinds.lua`, `~/.config/hypr/hyprland/rules.lua`, `~/.config/caelestia/cli.json`, `~/.config/caelestia/shell.json`.

**What:** Added an `anime` special workspace toggled with **Super+A**, housing **Seanime Denshi** (window class `seanime-denshi`). Behaves exactly like Cider/`music`: the app is **not** spawned by the toggle — it auto-places onto `special:anime` when launched independently, and the toggle just reveals the workspace and tidies any open window onto it.

**How (mirrors the Cider/music pattern):**
- `rules.lua` — window rule `class = "seanime-denshi"` → `workspace = "special:anime"` handles auto-placement on launch (the Cider-equivalent).
- `cli.json` — new `toggles.anime.seanime` block with `match` + `move:true` and **no** `command`, so `caelestia toggle anime` toggles visibility and moves a stray window on, but never launches the app (identical to `music.cider`).
- `keybinds.lua` / `variables.lua` — new `vars.kbAnime = "SUPER + A"` bound to `caelestia toggle anime`, alongside the other special-ws toggles.
- `shell.json` — added `{ "icon": "smart_display", "name": "anime" }` to `bar.workspaces.specialWorkspaceIcons`. Without this, `Icons.getSpecialWsIcon` (`utils/Icons.qml`) falls back to `name[0].toUpperCase()` = a plain "A" letter glyph; the Material Symbol gives a bespoke streaming/video icon instead.

**Trade-off:** Super+A previously bound `caelestia:showall` (show all panels). Per request that bind was **dropped entirely** (`vars.kbShowPanels` removed) to free Super+A for the anime workspace; showall now has no keybind.

**Verified (2026-06-17, user-confirmed):** `hyprctl reload` clean; Super+A is the only `A` bind (no `showall` left); `caelestia toggle anime` reveals/hides `special:anime` without spawning Seanime Denshi; launching Seanime Denshi auto-places it on `special:anime` with the `smart_display` bar icon.

**Update (2026-06-17): Stremio added to the same `anime` workspace.** Stremio (class `com.stremio.stremio`) now gets the same treatment as Seanime Denshi — auto-place on launch + tidy-on-toggle, never spawned by the toggle. `rules.lua` anime rule class is now the alternation `seanime-denshi|com\.stremio\.stremio`; `cli.json` `toggles.anime.seanime.match` gained a second `{ "class": "com.stremio.stremio" }` entry (matches are OR'd, `move:true`, no command). Verified: `caelestia toggle anime` moved a running Stremio from a normal workspace onto `special:anime` without spawning a new instance.

---

## 2026-06-16: Sioyek PDF pages — switched custom-colour → dark mode (follow scheme, no blue cast)

**Files:** `~/.config/caelestia/templates/sioyek.config`, `~/.config/sioyek/prefs_user.config`, `~/.config/caelestia/post-theme-hook.sh`.

**What:** The dynamic sioyek theme (template → `~/.local/state/caelestia/theme/sioyek.config`, symlinked as `~/.config/sioyek/caelestia.config` and `source`d from `prefs_user.config`) was generating wallpaper colours correctly all along — but the **PDF pages** looked unchanged ("everforest"). Switched the page rendering from `toggle_custom_color` to `toggle_dark_mode`, with `dark_mode_background_color = surface`. Pages now render as a clean, neutral, surface-coloured dark background that follows the wallpaper (no blue cast). The canvas around pages is near-black (≈ surface).

**Why it looked broken (verified empirically by rendering the actual PDF under sandboxed instances):**
- The config *was* loading: `source`, `~` expansion and `#rrggbb` hex all work in sioyek 2.0 `g552008ac`; forcing neon green/red custom colours rendered the page green/red, proving caelestia's values reach the renderer.
- `toggle_custom_color` is **not a flat recolour** — it's a contrast-based matrix transform (`get_custom_color_transform_matrix`, pdf_view_opengl_widget.cpp:2755; `custom_color_contrast` 0.5). For *near-neutral* dark/light colours like caelestia's `surface`/`onSurface`, it washes the hue out to a fixed bluish-slate (~`#181a21`) that's almost identical to sioyek's *default* custom colours (`#2e3440`/`#d8dee9`) — hence "still everforest." Tested dark rose, medium rose, dark/medium sepia and a swap: all rendered bluish (R−B −1…−16). Only fully-saturated neon transfers hue (useless for reading). The old "everforest" was never a real config — an earlier commit only added `startup_commands toggle_custom_color` and never set colours, so the default bluish custom page had been showing ever since.
- `toggle_dark_mode` instead renders the page as `dark_mode_background_color` directly (no transform), which is **neutral** (measured R−B ≈ 0) and can be set to `surface` so it follows the wallpaper.

**Also:** `post-theme-hook.sh` now runs `sioyek --execute-command reload_config --nofocus` (guarded by `command -v sioyek` + `pgrep -x sioyek`) after regenerating colours. sioyek is single-instance (`use_single_instance = !SHOULD_LAUNCH_NEW_INSTANCE`, main.cpp:742) and its config watcher (`on_config_file_changed`, main_widget.cpp:1883) doesn't watch `source`d files, so without this a running instance never picks up scheme changes. Note `startup_commands` only runs at process start, so an *already-running* sioyek needs a real restart to switch custom→dark mode; reload only refreshes colour values.

---

## 2026-06-15: Upstream-merge workflow + first catch-up merge (a1124c82 → 067938d)

**What:** A repeatable way to pull upstream caelestia-shell updates into this customized fork without clobbering local mods, plus the first merge executed through it.

**The workspace:** `~/projects/caelestia-merge` — a clone of `github.com/caelestia-dots/shell` with branches `main` (pristine upstream) and `local` (upstream fork-point + my customizations), and tag `mine-base` = last-synced baseline. The live shell dir (`~/.config/quickshell/caelestia`, tracked in the `~/.config` dotfiles repo) is **not** itself a git repo and stays untouched as a workflow.

**Fork point:** Found by *content* (not file mtimes, which are misleading — they carry the old package's build date). The true base is upstream **`a1124c82`** (Jun 9): my pristine files match it exactly, and choosing the later `f86c359c` would have silently dropped real upstream fixes. Current upstream = **`067938d`** (package `caelestia-shell-git 2.0.3.r1.g067938d`). Real divergence was small: 27 edits + 12 added files, 12 commits to merge, only 2 true conflicts.

**Recurring workflow (each package update):**
1. `cd ~/projects/caelestia-merge`
2. import any live edits: `rsync -a --exclude=.git --exclude=changes.md --exclude=.claude --exclude=.qmlls.ini ~/.config/quickshell/caelestia/ ./ && git add -A && git commit -m "live edits" || true`
3. `git checkout main && git pull` ; `git checkout local && git merge main` (resolve conflicts)
4. mirror shipped paths back: `git diff mine-base..local -- assets components modules services utils shell.qml LICENSE > /tmp/cael.patch` then `patch -p1 -d ~/.config/quickshell/caelestia < /tmp/cael.patch`
5. reload + verify, then `git tag -f mine-base local`. **Discipline:** any fix made in the live dir must also be committed on `local`, or the next merge reverts it.
6. `plugin/` C++, `flake.*`, `CMakeLists.txt`, `README`, `.github` are excluded from the mirror — they're not in the runtime copy; the compiled plugin ships in the package.

**Conflicts resolved this round:**
- `modules/drawers/ContentWindow.qml` — kept my "always overlay over fullscreen" gate-removal AND gained upstream's new `hasSpecialWorkspace && hasFullscreenOnNormalWs` case → `fsTransitionProg > 0 || (hasSpecialWorkspace && hasFullscreenOnNormalWs)`.
- `services/Hypr.qml` — see below.

**Caps/Num-lock toasts — upstream's event method rejected (kept the poll):** Upstream rewrote `reloadDynamicConfs()` to bind `Caps_Lock`/`Num_Lock` via Lua `hl.bind(... hl.dsp.global("caelestia:refreshDevices") ...)`. **Proven not to work on Hyprland 0.55.4:** the bind registers and survives reload, but the keypress never *fires* the dispatcher (verified by binding Caps_Lock to a `notify-send` test — no notification on toggle). Worse, `hl.bind` is non-idempotent, so re-running it on every `configreloaded` accumulates dead binds. So `Hypr.qml` keeps my **Timer-only** design (`Timer { interval: 500; onTriggered: extras.refreshDevices() }`), `reloadDynamicConfs` removed entirely. Toasts now feel near-instant anyway — the package's plugin rework (`hyprextras.cpp/.hpp`: `usingLua` + event-socket handling) makes the same poll round-trip much faster. `keybinds.lua` comment updated to record the register-but-doesn't-fire finding.

---

## 2026-06-14: Cider dynamic theming (full wallpaper theme, live via CDP)

**Files:** `~/.config/caelestia/cider-theme.py` (NEW), `~/.config/caelestia/post-theme-hook.sh`, `~/.local/bin/cider-themed` (NEW), `~/.local/share/applications/cider.desktop` (NEW, user override), `~/.config/sh.cider.genten/client-options.yml`, plus `~/.config/sh.cider.genten/plugins/.disabled/` (moved-aside plugins).

**What:** Cider (native Electron Apple-Music client, config dir `~/.config/sh.cider.genten/`) re-colors backgrounds, surfaces, text AND accent from the wallpaper palette, regenerated on every scheme change, **live with no restart** (playback uninterrupted).

**Why CDP, not customCSS:** Cider's `visual.customCSS` is only read at startup, and Cider rewrites `spa-config.yml` on exit — so editing the config live gets clobbered and can't hot-reload. Cider is Electron/Chromium, so instead we open its DevTools port and inject a `<style>` + inline vars at runtime. Same family as the ZapZap CDP work, but here CDP is the *apply* path, not just investigation.

**How:**
- `cider-theme.py` reads `SCHEME_COLOURS` (from the hook) or `scheme.json`, maps Material You → Cider's CSS vocabulary (proven via `themes/12` Catppuccin): backgrounds `--base`←surface, `--mantle`←surfaceContainerLow, `--crust`←surfaceContainerLowest; surfaces `--surface0`←surfaceContainer, `--tracklistAltRowColor`←surfaceContainerHigh, `--selection-bg`←secondaryContainer; text `--text`/`--textDefault`/`--systemPrimary`←onSurface, `--subtext1`/`--systemSecondary`←onSurfaceVariant, `--subtext0`/`--overlay*`/`--systemTertiary…Quinary`←outline/outlineVariant; accent `--accent`/`--keyColor`/`--musicKeyColor`/`--q-primary`/`--progressColor`/`--gradientColor`/`--defaultColor`/`--buttonColor`←primary, `--buttonTextColor`←onPrimary (+ `-rgb` companions). Writes `~/.local/state/caelestia/theme/cider.css`.
- Live inject over CDP (`http://127.0.0.1:9223`): upserts `<style id="caelestia-cider">` AND sets every var inline with `!important` on **both** `<html>` and `<body>`. Body is required because Cider's `customAccentColor` sets `--keyColor` inline on `<body>`, and a child's own declaration beats an inherited `!important`.
- CDP gotcha: modern Electron returns **403** on CDP WebSocket handshakes carrying an `Origin` header — connect with `suppress_origin=True` (no relaunch/flag needed). `--remote-allow-origins=*` would be the flag-based alternative.
- **No `@property`/CSS transition of our own:** registering these vars via `@property` conflicts with Cider's *own* `@property`+transition on the same names and **freezes** them at the old value (computed never follows the inline change). Cider already declares ~1s `cubic-bezier(0.45,-0.05,0.15,1.05)` transitions on its color vars, so plain values cross-fade smoothly on their own.
- Trigger: a Cider block appended to `post-theme-hook.sh` runs the script when `$SCHEME_COLOURS` is set (no-ops silently if Cider/the port isn't up).
- Cold start: `cider-themed` wrapper launches `cider --remote-debugging-port=9223`, waits for the port, then injects **twice** (immediately + after ~4 s) to win the race against Cider setting its own accent during Vue mount. The user `cider.desktop` override (Exec → `cider-themed`) makes the app launcher use it. `client-options.yml` `chromeFlags: ["--remote-debugging-port=9223"]` is a backstop so even a plain `cider` launch opens the port for the wallpaper-change hook.
- Disabled the album-art accent plugins `cidr.techyt.adaptivecolors` and `cidr.amaru8.adaptiveaccentseverywhere` (moved to `plugins/.disabled/`, reversible) so the accent follows the wallpaper, not the current track.

**Verified (2026-06-14, user-confirmed):** test-palette injected via `SCHEME_COLOURS` recolored Cider live (green → restored) through the exact hook path; cold start auto-themed on relaunch with no manual step; adaptive plugins confirmed not loaded (`--adaptiveAccent` absent); all background/surface/text/accent vars compute to the wallpaper palette.

**Caveat:** cold-start auto-theming only fires when Cider is launched via the app launcher (now using the `cider.desktop` override → `cider-themed`). Launched any other way, the first paint is unthemed until the next wallpaper-change hook re-themes it live. To re-enable an adaptive plugin, move its folder back out of `plugins/.disabled/`.

---

## 2026-06-14: Stop cursor warping to center on tray-icon activation

**File:** `~/.config/hypr/hyprland/input.lua`

**What:** Clicking a system-tray icon for an app on a special workspace (ZapZap, Cider) reveals the app on its special workspace without yanking the mouse pointer to the center of the screen.

**Why:** Default Hyprland behavior warps the cursor to the focused window's center. The tray click sends SNI `Activate`; with `misc:focus_on_activate = true` Hyprland focuses the now-shown special-workspace window and warps to it (window fills the workspace ⇒ ≈screen center). See Hyprland issue #7523. `warp_on_toggle_special` doesn't apply (the reveal goes through the focus/activate path, not the special-toggle path), and there's no per-window warp-disable rule.

**How:** Added `no_warps = true` to the `cursor` block in `input.lua`. `focus_on_activate` left `true` so tray clicks still reveal/focus the app.

**Scope/tradeoff:** Global — the cursor also no longer follows keyboard focus changes (Super+arrows) or newly-focused windows. Known multi-monitor caveat with sloppy focus (`follow_mouse = 2`): focusing a window on a monitor the cursor isn't on can bounce back (Hyprland #2967); not an issue on the single laptop screen.

**Verified (2026-06-14, user-confirmed):** `hyprctl reload` clean; `hyprctl getoption cursor:no_warps` → `bool: true; set: true`; tray-click pointer-stays-put confirmed working. User is single-monitor for now — revisit the #2967 sloppy-focus caveat if/when a second monitor is added.

---

## 2026-06-14: Fix special-workspace toggling (revert to official `caelestia toggle`)

**Files:** `~/.config/hypr/hyprland/keybinds.lua`, `~/.config/hypr/hyprland/gestures.lua`, `~/.config/hypr/hyprland/rules.lua`, `~/.config/caelestia/cli.json`

**What:** Super+B (books+Readest), Super+D (comms+ZapZap), Super+M (toggle music only, no Cider spawn), and Cider auto-placing on the music workspace all work again after the Lua migration.

**Why it broke:** During the hyprlang→Lua port, an agent wrongly assumed `hyprctl dispatch` needs Lua-syntax expressions and wrote a custom wrapper `~/.local/bin/caelestia-toggle` that the keybinds called. The official `caelestia` CLI already detects Lua configs natively — `caelestia/utils/hypr.py` `is_lua_config()` reads `hyprctl systeminfo` `configProvider: lua` and translates dispatchers via `DISPATCHER_MAP_LUA` (`togglespecialworkspace`→`hl.dsp.workspace.toggle_special`, etc.). The wrapper was redundant and buggy.

**How:**
- keybinds.lua (5 special-ws binds) + gestures.lua (specialws gesture): `caelestia-toggle X` → `caelestia toggle X`. Wrapper file left in place but now unused.
- cli.json `toggles.music.cider`: removed `"command": ["cider"]` so Super+M never spawns Cider (kept `match` + `move:true` — toggle just tidies an open Cider onto the ws). Auto-placement of a freshly launched Cider is handled by the window rule, not the toggle.
- rules.lua `special:music` rule: added lowercase `cider` to the class regex (Hyprland class regex is case-sensitive; rule had `Cider`, cli.json had `cider`).

**Verified (2026-06-14, user-confirmed):** `hyprctl reload` clean; `caelestia toggle todo` shows/hides via the Lua dispatch path; Super+B/M/D and Cider auto-placement onto `special:music` all work, with Super+M no longer spawning Cider.

---

## 2026-06-12: Hyprland session restore (macOS-style reopen windows)

**Files:** `~/.config/hypr/scripts/session-manager.py` (NEW), `~/.config/hypr/hyprland/execs.lua`, `~/.config/caelestia/shell.json`

**What:** After logout/reboot/shutdown, all previously open windows reopen on their original workspaces silently — focus stays on the current workspace, floating windows get exact position/size, pinned/fullscreen state restored, scratchpad apps (special:\*) included. App-internal state rides on the apps' own persistence (sioyek/okular last page, obsidian vaults, zen session restore); kitty windows reopen in their old cwd, and if yazi/nvim/btop/htop was running inside, it's relaunched in its directory. NOT restored: exact dwindle split tree (windows re-tile in saved left-to-right order), terminal scrollback, unsaved in-app state.

**How:**
- `session-manager.py save`: `hyprctl clients -j` → per mapped window record class/title/workspace/at/size/floating/pinned/fullscreen + relaunch command from `/proc/<pid>/cmdline` + `/proc/<pid>/cwd` (kitty: BFS `/proc/*/task/*/children` for a known TUI, strip `--cwd-file=` args). Skips empty-class windows and `EXCLUDE_CLASSES` (quickshell, xdm, clipse, vicinae, xembedsniproxy — things execs.lua already autostarts). Atomic write to `~/.local/state/caelestia/session.json`. One spawn per pid; extra same-pid windows are sweep-only records.
- `restore`: for each saved window, `hyprctl dispatch "hl.dsp.exec_cmd([[cmd]], { workspace = 'N silent', float = true, move = {x,y}, size = {w,h}, pin = true })"` — exec rules are PID-tracked (0.55 wiki: forks escape), so a ~20s sweep pass then matches stray new clients by class and fixes them via `hl.dsp.window.move({ workspace, follow = false, window = 'address:0x…' })` + float/move/resize/fullscreen dispatchers. Guards: skips if `~/.local/state/caelestia/session-restore-disabled` exists, or if >3 non-excluded clients already open.
- `daemon`: saves every 60s (90s initial delay so a half-restored session doesn't clobber the snapshot) — covers power-button/terminal shutdowns and crashes.
- `execs.lua`: added `sleep 2 && …session-manager.py restore` + `…session-manager.py daemon` to `hl.on("hyprland.start", …)`.
- `shell.json`: session-menu logout/reboot/shutdown commands (and matching launcher entries) now run `session-manager.py save;` first. Hibernate untouched (resumes natively).

**Verified:** `save` produces correct JSON (yazi-in-kitty → `kitty -d ~/Downloads yazi`); live dispatch test: `exec_cmd` with `workspace = '4 silent'` spawned on ws 4 with focus staying on ws 2; floating rule landed pixel-exact at global coords `{200,150} 700x400`; restore guard aborts on populated session; full logout→login cycle confirmed working by user (2026-06-12).

**Notes:** Dolphin tab restore needs its own setting enabled (Settings → Startup → "Show on startup: same locations as when Dolphin was closed last"). Single-instance/forking apps (obsidian, electron) are placed by the sweep's class-matching, best-effort for multiple same-class windows.

---

## 2026-06-12: Keep Awake auto-off on charger unplug + toggle toasts

**File:** `services/IdleInhibitor.qml`

**What:** The "Keep Awake" card (utilities panel, `modules/utilities/cards/IdleInhibit.qml`) now reacts to power events:
- If keep-awake was enabled **while plugged in**, unplugging the charger auto-disables it with a toast ("Keep awake disabled / Charger was unplugged", icon `power_off`).
- If it was enabled **while on battery**, it is exempt — no unplug ever auto-disables it (exemption sticks through plug/unplug cycles until manually turned off). Tracked via new `enabledOnBattery` bool in the `PersistentProperties` block, stamped with `UPower.onBattery` at enable time.
- Manual toggling now toasts: "Keep awake enabled / The screen will stay on" and "Keep awake disabled / Normal power management restored" (icon `coffee`).

**How:** Added imports `QtQuick`, `Quickshell.Services.UPower`, `Caelestia`; a `Connections { target: UPower }` on `onOnBatteryChanged` (same pattern as `modules/BatteryMonitor.qml`) that, when going on battery with `enabled && !enabledOnBattery`, sets a transient `autoDisabling` flag and disables; `onEnabledChanged` picks the toast based on that flag. Plug-in events do nothing.

**Notes:** Toasts are unconditional — the `GlobalConfig.utilities.toasts.*` gate keys are a fixed compiled C++ schema (`UtilitiesToasts` in `libcaelestia-config.so`), so no new gate key can be added without rebuilding the plugin. On unplug, the existing BatteryMonitor "Charger unplugged" toast (gated by `toasts.chargingChanged`) appears alongside the new one. Known quirk (same as GameMode): a shell config reload that restores `enabled: true` re-fires the toast and re-stamps `enabledOnBattery`.

---

## 2026-06-12: Fixed game mode quick toggle (keyword IPC → eval)

**File:** `services/GameMode.qml`

**Root cause:** `setDynamicConfs()` used `Hypr.extras.applyOptions({...})`, which sends `[[BATCH]]keyword <option> <value>;...` over the Hyprland IPC socket. Hyprland 0.55's Lua (non-legacy) config parser rejects every `keyword` request with `keyword can't work with non-legacy parsers. Use eval.` The failure is silent — the toggle flipped and the toast showed, but no options were applied. Same breakage class as the `Hyprland.dispatch()` fix (2026-06-09).

**Fix:** Replaced the `applyOptions()` call with a single eval message via the existing socket path:
```qml
Hypr.extras.message("eval hl.config({ animations = { enabled = false }, decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } }, general = { gaps_in = 0, gaps_out = 0, border_size = 1, allow_tearing = true } })");
```
The disable path (`Hypr.extras.message("reload")`) was already working (re-runs the Lua config tree) and is unchanged.

**Verified:** `qs -c caelestia ipc call gameMode toggle` → `hyprctl getoption` shows animations false, gaps 0, blur false, border 1; toggle off restores config values. Note: the gameMode IPC target only registers once the utilities drawer (or DesktopClock) first instantiates the singleton.

**Known wart (intentionally untouched):** the cold-start state binding `Hypr.options["animations:enabled"] === 0` reads `descriptions` IPC data, which on 0.55 reports booleans and is desynced from `getoption`; it harmlessly evaluates false. Persistent state across reloads comes from `PersistentProperties` anyway.

---

## 2026-06-11: ZapZap dynamic theming (backgrounds + accent)

Replaces WhatsApp Web's stock green with the wallpaper accent and themes its
backgrounds, regenerated on every scheme change. Verified end-to-end via
QtWebEngine remote debugging (`QTWEBENGINE_REMOTE_DEBUGGING=9222 zapzap` + CDP).

**How modern WhatsApp Web (the `color-refresh` UI) is themed:**
- Two layers. (1) WDS palette primitives on `:root`: `--WDS-neutral-gray-*`,
  `--WDS-green-*`, `--WDS-emerald-*`. (2) Semantic system tokens
  (`--WDS-surface-default`, `--WDS-systems-bubble-surface-outgoing/incoming`,
  `--WDS-background-wash-*`, `--WDS-persistent-always-branded`, …) which the
  per-chat-theme classes (obfuscated, e.g. `.x1umy8rd.x1umy8rd`) redeclare with
  LITERAL hex values on a wrapper element *below* `<html>`.
- Critical gotcha: a `:root { … !important }` override does NOT propagate past
  that wrapper — descendants inherit each custom property from the *nearest
  declaring ancestor*, and `!important` only wins cascade fights on the same
  element. The override selector must be `*` so it lands on the wrapper itself.
- So the generated CSS is `* { …all overrides… !important }` covering BOTH the
  primitives and the semantic tokens. The old `--background-default`, `--teal`,
  `._amk6` etc. are legacy and unused by `color-refresh`.

**Why CSS, not JS:** ZapZap injects user JS as an inline `<script>` node, which
WhatsApp Web's CSP blocks (never executes). CSS (`<style>` node) is not blocked.

**Implementation:**
- Generated in `~/.config/caelestia/post-theme-hook.sh` (Python block, reads
  `SCHEME_COLOURS`) rather than the template engine, because the WDS `*-RGB`
  alpha channels need bare `r,g,b` values the engine can't emit. Writes
  `~/.local/state/caelestia/theme/zapzap.css`.
- Mapping: gray-900/850/800/700 ← surface / surfaceContainerLow / Container /
  ContainerHigh; bright green+emerald shades ← primary; dark green/emerald
  shades ← primaryContainer (the dark accent surface in dark schemes, so light
  text stays readable — do NOT use onPrimaryContainer, it's light in normal
  dark schemes). Semantic tokens: surface-default / wash-plain|inset /
  chat-background-wallpaper / chat-surface-tray ← surface; elevated washes /
  nav-bar / chat-surface-composer / surface-elevated-default ←
  surfaceContainerLow; surface-emphasized / bubble-surface-incoming ←
  surfaceContainer; bubble-surface-outgoing ← primaryContainer;
  persistent-always-branded (status dot green) ← primary.
- Verified clean via rendered-color census over `#app *`: zero stock WhatsApp
  colors remain (left pane, chat panel, both bubble directions, accent).
- Wallpaper-colour tinting: all surfaces are blended towards primaryContainer
  via `mix()` in the hook — `TINT = 0.14` for general surfaces, `0.35` for the
  chat-area background (`systems-chat-background-wallpaper`), and the doodle
  pattern (`systems-chat-foreground-wallpaper`) is `rgba(primary, .12)`.
  Tune TINT in the hook to taste; 0 restores plain scheme surfaces.
- Note: injection happens only at page load, so toggling things in ZapZap's
  Customizations UI mid-session can leave the page unthemed until the next
  app restart. With dark wallpapers the background change is subtle by design —
  the accent (chips, badges, buttons) is the visible tell.
- Symlinked to
  `~/.local/share/ZapZap/customizations/accounts/storage-whats/css/zapzap.css`.
- `~/.config/ZapZap/ZapZap.conf`: `accounts\storage-whats\css\enabled=true`,
  `inherit=false`, empty `css\disabled_files`. (JS left disabled — CSP blocks it.)

To re-add a green token if some element is missed: open WhatsApp in
`QTWEBENGINE_REMOTE_DEBUGGING=9222 zapzap`, scan stylesheets for the offending
var, and add it to the post-hook mapping.

## 2026-06-11: Fixed apps/screenshots opening on the wrong workspace

**File:** `~/.config/hypr/hyprland/misc.lua` — added `initial_workspace_tracking = 0` to the `hl.config({ misc = {...} })` block.

**Problem:** Apps launched from the quickshell launcher, and screenshot previews (swappy), would intermittently open on a workspace other than the active one.

**Root cause:** Hyprland's `misc:initial_workspace_tracking` (default `1`) pins a newly-mapped window to the workspace recorded in the spawning process's `HL_INITIAL_WORKSPACE_TOKEN` env var, not the currently-active workspace. The long-running shells (`qs -c caelestia`, `qs -c overview`) carry a stale token from when they were launched at session start, and every child they spawn inherits it — launcher uses `execDetached(["app2unit", ...])` (`modules/launcher/services/Apps.qml`), screenshot preview uses `execDetached(["swappy", "-f", path])` (`modules/areapicker/Picker.qml`). So those windows landed on the shell's startup workspace. Intermittent because the token is consumed/expires after use.

**Fix:** Setting `initial_workspace_tracking = 0` disables the feature entirely — windows always open on the active workspace. Chosen over surgically stripping the token from shell launches because it's a one-line, bulletproof fix that matches the desired behavior, with no coverage gaps.

**IMPORTANT — config location:** This setup's *live* Hyprland config is the **Lua tree** (`~/.config/hypr/hyprland.lua` → `require("hyprland.misc")` etc.), NOT the `.conf` files. The `.conf` twins (`misc.conf`, `input.conf`, ...) are stale leftovers from before the 0.55 Lua migration and are not loaded. Editing `misc.conf` had no effect; `hyprctl reload` re-runs the Lua config only. Always edit the `.lua` files. Verify with `hyprctl getoption misc:initial_workspace_tracking` (expect `set: true`).

---

## 2026-06-11: Mako/quickshell notification seat handover

**Files:**
- `~/.local/bin/caelestia-shell` (new) — wrapper script that stops mako before starting quickshell, so quickshell can claim `org.freedesktop.Notifications` cleanly
- `~/.config/hypr/hyprland/execs.conf` — changed `caelestia shell -d` to `caelestia-shell -d`

**Problem:** Mako has a D-Bus activation file (`/usr/share/dbus-1/services/fr.emersion.mako.service`) that registers it as `org.freedesktop.Notifications`. When quickshell crashes, the next outgoing notification auto-activates mako via D-Bus. When quickshell restarts, it can't reclaim the seat because mako is already holding it.

**Fix:** The wrapper calls `systemctl --user stop mako` (synchronous) before `exec caelestia shell "$@"`. The seat is free by the time quickshell registers. The reverse direction (quickshell dies → mako auto-activates) already works via D-Bus activation with no changes needed.

---

## 2026-06-09: Removed `keyword bindlni` from Hypr.qml

**File:** `services/Hypr.qml`

**What:** Removed `reloadDynamicConfs()` function and all its call sites. This function used `hyprctl keyword bindlni` to dynamically register CapsLock/NumLock keybinds at runtime.

**Why:** Hyprland 0.55 deprecated `hyprctl keyword` for keybinds. CapsLock/NumLock detection was later moved to a polling approach (see next section).

**Removed:**
- `reloadDynamicConfs()` function (was `keyword bindlni ,Caps_Lock,...` and `keyword bindlni ,Num_Lock,...`)
- `Component.onCompleted: reloadDynamicConfs()`
- `root.reloadDynamicConfs()` call from the `configreloaded` event handler

---

## 2026-06-09: CapsLock/NumLock fix for Hyprland 0.55

**Root cause:** Hyprland 0.55 cannot bind modifier-only keys (CapsLock, NumLock, Shift, Ctrl, Alt) as standalone bind targets. `hl.bind("Caps_Lock", ...)` simply never fires, regardless of dispatcher type (global, exec_cmd, or pure Lua callback).

Note: `hl.dsp.global()` works fine in 0.55 — all existing `caelestia:*` global keybinds (launcher, session, media, brightness, screenshots, volume, lock, etc.) continue to work. The CapsLock/NumLock problem is specific to binding modifier-only keys, not to the IPC mechanism.

**Fix:** Use a polling `Timer` in `services/Hypr.qml` that calls `extras.refreshDevices()` every 500ms. This detects lock state changes without needing a Hyprland keybind. The existing `onCapsLockChanged`/`onNumLockChanged` handlers then fire and show the toast.

**Modified file:** `~/.config/hypr/hyprland/keybinds.lua`
- Removed CapsLock/NumLock binds entirely (can't work in 0.55)
- Added comment explaining the polling approach

**Modified file:** `services/Hypr.qml`
- Added `Timer { interval: 500; running: true; repeat: true; onTriggered: extras.refreshDevices() }`
- The `IpcHandler { target: "hypr", function refreshDevices() }` and `CustomShortcut { name: "refreshDevices" }` remain for manual/other use

**New file:** `~/.local/bin/caelestia-ipc`
- Fast IPC helper for Quickshell socket (built during investigation, available for future use)
- Not actually needed — polling approach was the correct fix

---

## 2026-06-09: Restored missing volume key handlers in Audio.qml

**File:** `services/Audio.qml`

**What:** Restored four `CustomShortcut` entries (`volumeUp`, `volumeDown`, `volumeMute`, `micMute`) and their helper functions (`toggleMute()`, `toggleSourceMute()`) that were missing from the current version but present in the backup. Also restored `volumeAdjustAttempted()`/`sourceVolumeAdjustAttempted()` signals used by the OSD popout.

**Added:**
- `import qs.components.misc` (required for CustomShortcut)
- `signal volumeAdjustAttempted()` and `signal sourceVolumeAdjustAttempted()`
- `toggleMute()` and `toggleSourceMute()` functions
- Signal emissions in `setVolume()` and `setSourceVolume()`
- Four `CustomShortcut` entries: `volumeUp`, `volumeDown`, `volumeMute`, `micMute`

**To apply:** Restart Quickshell (`qs -c caelestia kill && caelestia shell -d`). The Timer starts running when the service loads.

---

## 2026-06-09: Changed volume step from 10% to 5%

**File:** `~/.config/caelestia/shell.json`

**What:** Changed `services.audioIncrement` from `0.1` to `0.05`.

**Why:** The user had set `vars.volumeStep = 5` in `~/.config/hypr/hyprland/variables.lua`, but that variable only affects volume steps for Hyprland's internal dispatcher (`hl.dsp.audio.volume`), not Caelestia. Caelestia reads its volume increment from `GlobalConfig.services.audioIncrement` (which maps to `shell.json` → `services.audioIncrement`). The volume keybinds call `hl.dsp.global("caelestia:volumeUp")` → `CustomShortcut` in `Audio.qml` → `root.incrementVolume()` → `setVolume(volume + GlobalConfig.services.audioIncrement)`.

---

## 2026-06-09: Replaced `Hyprland.dispatch()` with Lua-translated `hyprctl dispatch`

**File:** `services/Hypr.qml`

**What:** Replaced `Hypr.dispatch()` — originally `Hyprland.dispatch(request)` — with a translation function that converts old-style dispatch strings to Lua expressions and calls `hyprctl dispatch`:

```qml
function dispatch(request: string): void {
    // Translates e.g. "workspace 2" → "hl.dsp.focus({ workspace = 2 })"
    //                    "togglespecialworkspace special" → 'hl.dsp.workspace.toggle_special("special")'
    //                    "movetoworkspace 5,address:0xABC" → 'hl.dsp.window.move({ workspace = 5, address = "0xABC" })'
    // etc.
    Quickshell.execDetached(["hyprctl", "dispatch", lua]);
}
```

**Why:** Two problems stacked:
1. Quickshell's `Hyprland.dispatch()` IPC is broken with Hyprland 0.55 (fails silently).
2. `hyprctl dispatch` in 0.55 evaluates its argument as Lua, so the old syntax (`hyprctl dispatch workspace 2`) generates invalid Lua: `hl.dispatch(workspace 2)` — "workspace" is treated as a variable, not a dispatcher.

The fix translates old dispatch commands to their Lua equivalents (e.g., `hl.dsp.focus({ workspace = 2 })`) and passes them to `hyprctl dispatch` as a single argument, bypassing shell quoting issues via `execDetached`'s argv interface.

**Affected call sites (all fixed by this single change):**
- `Modules/bar/Bar.qml` — scroll-to-switch workspace
- `Modules/bar/components/workspaces/Workspaces.qml` — click-to-switch workspace
- `Modules/bar/components/workspaces/SpecialWorkspaces.qml` — special workspace toggles
- `Modules/windowinfo/Buttons.qml` — move, float, pin, kill buttons
- `Modules/IdleMonitors.qml` — dpms on/off

---

## 2026-06-09: Replaced battery icon with percentage + charging bolt

**File:** `modules/bar/components/StatusIcons.qml`

**What:** Replaced the dynamic battery `MaterialIcon` with a `ColumnLayout` containing:
- A `StyledText` showing the numeric battery percentage (e.g. `85`), using `Tokens.font.body.small`
- A small filled `bolt` icon below, visible only when charging/plugged in

**Why:** User preference — a number is more precise than a battery icon, and the charging bolt provides a compact plugged-in indicator without duplicating the percentage.

---

## 2026-06-09: Added network speed to bar status icons with hover popout

**Files:**
- `modules/bar/components/StatusIcons.qml` — added network speed display (download speed value + unit, two-line layout)
- `modules/bar/popouts/NetworkSpeed.qml` (new) — popout showing download/upload rates and session totals
- `modules/bar/popouts/Content.qml` — registered `"netspeed"` popout

**What:** The status icons column now shows current download speed (e.g. "1.2" on the first line, "MB/s" on the second line in smaller text). Hovering reveals a popout with download speed (arrow_downward), upload speed (arrow_upward), and session totals (history icon).

**Data source:** `NetworkUsage` singleton service (reads `/proc/net/dev`), same as the dashboard performance `NetworkCard`.

**Note:** No settings toggle was added. The `Caelestia.Config` module is a compiled C++ plugin at `/usr/lib/qt6/qml/Caelestia/Config/` — adding a `showNetworkSpeed` property would require modifying that C++ source and recompiling. For now, the network speed is always visible when `Config.bar.status.showNetwork` is true.

---

## 2026-06-09: Redesigned network speed display in status icons

**Files:**
- `modules/bar/components/StatusIcons.qml` — pulled network speed outside the pill, redesigned layout
- `modules/bar/Bar.qml` — added netspeed popout hit-testing fallback
- `modules/bar/popouts/NetworkSpeed.qml` — swapped upload/download order to match bar

**What:** Complete redesign of the network speed display:
- **Moved outside the pill background** — network speed sits bare on the taskbar; the `StyledRect` pill only wraps the remaining status icons (lock keys, audio, mic, kb layout, network, ethernet, bluetooth, battery). When `showNetwork` is false, the pill slides up seamlessly.
- Root changed from `StyledRect` to `Item` with explicit `implicitHeight` accounting for both netspeed loader and pill
- **Upload above, download below** (swapped order in both bar and popout)
- Format: `↑3M` / `↓12K` — arrow, whole number, single-letter unit, no spaces
- Numbers use `Math.round()` — no decimals; below 1 KB/s shows `0`
- Numbers rendered in **JetBrainsMono Nerd Font** at 11px, **bold**
- Arrows keep the default font at normal size and weight; upload arrow at 70% opacity
- Rows center-aligned, content-sized — no layout shifting when values change width
- Removed `animate: true` from value texts — no fade-out/fade-in blink on update
- **Popout fix:** Bar.qml `checkPopout()` falls back to checking the `netspeed` loader directly since it's no longer a child of `iconColumn`
- Exposed `netspeed` alias on StatusIcons root for Bar.qml hit-testing

**Why:** User wanted a compact, monospace, glanceable speed indicator that's visually separated from the other status icons.

---

## 2026-06-09: OSD now shows in fullscreen and at volume/brightness limits

**Files:**
- `modules/drawers/ContentWindow.qml` — always use `WlrLayer.Overlay` when fullscreen
- `modules/osd/Wrapper.qml` — listen to `volumeAdjustAttempted`/`sourceVolumeAdjustAttempted`/`brightnessAdjustAttempted` signals
- `services/Brightness.qml` — added `brightnessAdjustAttempted` signal to Monitor component

**What:** Three fixes:

1. **OSD now appears over fullscreen apps.** The drawers window layer was gated on `Config.general.showOverFullscreen` (default `false`), keeping it on `WlrLayer.Top` where the fullscreen app rendered above it. Removed the gate — the window always moves to `WlrLayer.Overlay` in fullscreen. The `emptyRegion` mask already restricts visibility to only OSD and notification cutouts, so other drawers won't leak.

2. **OSD now shows when volume is at min (0) or max.** `Wrapper.qml` only listened to `onVolumeChanged` (a property-change signal that doesn't fire when the value is clamped to the same boundary). Added handlers for `onVolumeAdjustAttempted` and `onSourceVolumeAdjustAttempted` — signals `Audio.qml` already emitted on every adjustment attempt regardless of whether the value changed.

3. **OSD now shows when brightness is at min (0%) or max (100%).** `Brightness.qml`'s `setBrightness()` returned early when the rounded value matched current brightness, preventing `brightnessChanged` from firing. Added a `brightnessAdjustAttempted` signal emitted at the very start of `setBrightness()`, before the early return, and connected `Wrapper.qml` to it.

---

## 2026-06-10: Vicinae dynamic theme support

**Files:**
- `~/.config/caelestia/templates/vicinae.toml` (new) — theme template using `{{ name.hex }}` placeholders
- `~/.local/share/vicinae/themes/caelestia.toml` — symlink → `~/.local/state/caelestia/theme/vicinae.toml`
- `~/.config/vicinae/settings.json` — changed theme from `dracula` to `caelestia` for both dark/light
- `~/.config/caelestia/post-theme-hook.sh` — added `vicinae theme set caelestia` for live reload

**What:** Added dynamic Vicinae theming that regenerates on every wallpaper change, following the same pattern as kitty, yazi, and the other apps. The template maps caelestia Material Design 3 colours to Vicinae's theme structure (core colours, eight accent hues, text, input, button, list, grid, scrollbar, and loading colours). Both dark and light variants are supported through the `{{ mode }}` placeholder.

**How it works:** The existing `apply_user_templates` in caelestia's `theme.py` processes `~/.config/caelestia/templates/*` on every wallpaper change and writes output to `~/.local/state/caelestia/theme/`. A symlink from Vicinae's themes directory points to the generated file. The post-hook calls `vicinae theme set caelestia` so the running instance picks up changes immediately.

**Template colour mapping:**
- `core.accent` → primary, `core.background` → surface, `core.foreground` → onSurface
- `core.secondary_background` → surfaceContainer, `core.border` → outlineVariant
- `accents`: blue→blue, green→green, magenta→mauve, orange→peach, red→red, yellow→yellow, cyan→teal, purple→lavender
- `text.danger` → error, `text.success` → success, `text.muted` → onSurfaceVariant
- `input.border_focus` → primary, `input.border_error` → error
- `button.primary.background` → primary, `.foreground` → onPrimary, `.hover` → primaryContainer

---

## 2026-06-10: Fixed dashboard tab shortcuts (Super+Ctrl+P/M/W)

**Files:**
- `modules/Shortcuts.qml` — added three new `CustomShortcut` definitions
- `components/DashboardState.qml` — converted to proper singleton

**Root cause:** Hyprland `keybinds.conf` dispatched `caelestia:dashboardMedia`, `caelestia:dashboardPerformance`, `caelestia:dashboardWeather` (bound to Ctrl+Super+M/P/W), but no matching `CustomShortcut` definitions existed in the QML code. Additionally, `DashboardState` was a regular component — accessing `DashboardState.currentTab` from `Shortcuts.qml` created a different instance than the one the dashboard used, so tab switching and close-on-repress never worked.

**Fix — Shortcuts.qml:** Added three `CustomShortcut` blocks (lines 51-127):
- Each computes the correct filtered tab index (accounting for enabled/disabled tabs via `Config.dashboard.showDashboard`, `showMedia`, etc.)
- If dashboard is hidden → shows it at the target tab
- If visible on a different tab → switches to the target tab
- If already on the target tab → hides the dashboard

**Fix — DashboardState.qml:** Added `pragma Singleton` and moved `reloadableId: "dashboardState"` inline. Updated `Wrapper.qml` to reference the singleton (`DashboardState`) instead of creating a new instance (`DashboardState { ... }`). This makes `DashboardState.currentTab` globally accessible.

---

## 2026-06-10: Added CPU/GPU fan speed display to performance dashboard

**Files:**
- `services/FanSpeeds.qml` (new) — singleton service for fan speed discovery and polling
- `modules/dashboard/performance/HeroCard.qml` — added `fanSpeed` property and display row
- `modules/dashboard/Performance.qml` — wired `FanSpeeds` to CPU/GPU `HeroCard` instances

**What:** The CPU and GPU performance cards now show fan RPM alongside temperature. Fan icon and speed appear on the right side of the temperature row (e.g. `🌡 51°C  fan 3100 RPM`), hidden when no fan sensor is detected.

**How it works:**
1. **Discovery** — `Process` runs `sh -c` to scan `/sys/class/hwmon/hwmon*/fan*_label` files, matching `*cpu*` and `*gpu*` (case-insensitive) to find sensor paths. Labels are stable (set by kernel drivers) so this survives hwmon renumbering across reboots.
2. **Polling** — `Timer` fires every `resourceUpdateInterval` ms, runs `cat` on discovered paths via a second `Process`, parses RPM values into `cpuFanRpm` / `gpuFanRpm`.
3. **Lifecycle** — `Ref { service: FanSpeeds }` in `HeroCard` manages the `refCount`, following the same pattern as `NetworkCard` / `NetworkUsage`.
4. **Display** — `HeroCard.fanSpeed` defaults to -1 (not shown). When >= 0, a fan icon and RPM text appear in the temperature row, right-aligned via a spacer.

**Robustness:**
- Fan labels (not hwmon indices) identify sensors — survives device renumbering
- No match → `fanSpeed` stays -1 → row stays hidden (graceful degradation)
- Discovery script uses regular JS string (not template literal) to prevent `$` interpolation
- `StdioCollector.text` used as property (not function) — matches Quickshell API
- Process-based `cat` reading avoids `FileView` dynamic-path-change concerns

---

## 2026-06-10: Repositioned fan speed to same row as temperature

**File:** `modules/dashboard/performance/HeroCard.qml`

**What:** Merged the separate fan speed `RowLayout` into the temperature `RowLayout`. Fan icon and RPM text sit on the right side of the row, with a `Layout.fillWidth` spacer between them and the temperature display. This puts both readings on one line: temperature (left) + fan speed (right), with the temperature progress bar below.

---

## 2026-06-10: Added CPU/RAM taskbar indicators with system monitor popout

**Files:**
- `modules/bar/components/StatusIcons.qml` — added `sysmonLoader` (CPU + RAM) and `netspeedLoader` above the pill
- `modules/bar/popouts/SystemMonitor.qml` (new) — hover popout with CPU/GPU temps and fan speeds
- `modules/bar/popouts/Content.qml` — registered `"sysmon"` popout
- `modules/bar/Bar.qml` — independent hit-testing for sysmon and netspeed within the statusIcons area

**What:**
- **Taskbar indicators** — Two small widgets stacked vertically above the status icon pill:
  - **RAM**: `CircularProgress` full circle (26×26, 2px stroke, tertiary colour) with percentage number centered (no % symbol)
  - **CPU**: `MaterialShape` (26×26) morphing with usage level (`Cookie4Sided` < 40%, `Sunny` 40–80%, `SoftBurst` > 80%), primary colour, with percentage number centered
- **Network speed** — Compact upload/download speeds below the sysmon indicators, same monospace format as before (`↑3M` / `↓12K`)

**Popout:** Hovering over the CPU/RAM indicators shows CPU and GPU rows, each with icon, label, temperature (with °F support), and fan speed (hidden when no fan detected). GPU row hidden entirely when `Gpu.type === Gpu.None`. `Ref { service: FanSpeeds }` keeps fan data alive while the popout is open.

**Hit-testing:** Each indicator (sysmon, netspeed) has its own independent `if` block with early `return` inside the `statusIcons` branch — checked in priority order: sysmon → netspeed → pill icons. No chaining or mutual dependency.

**Layout:** Both loaders sit bare on the taskbar above the pill (no background). The pill's top anchor and the root `implicitHeight` adjust dynamically based on which loaders are active. Since `StatusIcons` is positioned by the bar's entry order (typically near the bottom), the indicators appear between the clock and the status icon pill.

---

## 2026-06-11: Media player widget auto-switches to actively playing player

**File:** `services/Players.qml`

**What:** The `active` property now prefers whichever player is currently playing, rather than always sticking to the manually selected or first-in-list player. Logic:
1. If the manually selected player is playing → keep it (respects manual choice when active)
2. If any other player is playing → switch to it automatically
3. If nothing is playing → fall back to manual selection → default player config → first in list

**Why:** If you started a second player (e.g. YouTube in browser) while Spotify was paused, the dashboard media widget stayed on Spotify. Now it follows playback state.

**Changed:** Replaced the single-line `active` binding with a block expression that checks `p.isPlaying` on the manual player and then does `list.find(p => p.isPlaying)` before falling back to the old logic.

---

## 2026-06-11: Lyrics toggle in media dashboard tab

**Files:**
- `services/Players.qml` — added `property bool showLyrics: true` to existing `PersistentProperties` block; exposed as `property alias showLyrics: props.showLyrics`
- `modules/dashboard/media/LyricsAndSelector.qml` — added toggle button (`expand_less`/`expand_more`) in Lyrics header row; passes `lyricsEnabled: Players.showLyrics` to `LyricList`
- `modules/dashboard/media/LyricList.qml` — added `property bool lyricsEnabled: true`; `_` binding calls `Lyrics.clearTrack()` and returns early when disabled

**Why persistence was broken:** The previous attempt put `PersistentProperties` inside `LyricsAndSelector`, which lives inside a `Loader` with `active: opacity > 0`. When the dashboard closes, opacity goes to 0, the Loader destroys the component, and the value is lost. Moving the property into the `Players` singleton (which is always alive) fixes this.

**Behaviour:** Toggling off hides the lyric list and immediately stops any lyrics search (`Lyrics.clearTrack()`). Toggling on resumes fetching. State persists via `BarConfig` (see later entry — the original `PersistentProperties` approach was replaced).

---

## 2026-06-11: Nexus toggles for custom taskbar indicators (CPU, RAM, upload, download speed)

**Files:**
- `services/BarConfig.qml` (new) — singleton backed by `FileView` + `JsonAdapter` writing to `~/.config/caelestia/bar-extras.json`; exposes `showCpu`, `showRam`, `showUpload`, `showDownload`, `showLyrics`
- `modules/bar/components/StatusIcons.qml` — sysmon loader gated on `BarConfig.showCpu || BarConfig.showRam`; each indicator's visibility gated individually; netspeed loader gated on `BarConfig.showUpload || BarConfig.showDownload`; `NetworkUsage.refCount` binding updated accordingly
- `modules/nexus/pages/panels/taskbar/BarStatusIcons.qml` — four new `ToggleRow` entries (CPU usage, RAM usage, Upload speed, Download speed) added above existing icon toggles; imports `qs.services`
- `modules/dashboard/media/LyricsAndSelector.qml` — `showLyrics` toggle moved from `Players` to `BarConfig`
- `services/Players.qml` — removed `showLyrics`, `showCpu`, `showRam`, `showUpload`, `showDownload` (these never actually persisted across full restarts via `PersistentProperties`)

**Why `PersistentProperties` didn't work:** It only transfers state between old/new QML instances during a hot-reload within the same process. A full `qs kill + caelestia shell -d` restart has no old instance, so all values reset to defaults. `FileView` + `JsonAdapter` writes to disk on every change (`onAdapterUpdated: writeAdapter()`) and reads back synchronously on startup (`blockLoading: true`), surviving full restarts.

---

## 2026-06-11: Reduced font sizes in media dashboard tab

**Files:**
- `modules/dashboard/media/Details.qml` — track title `title.large` → `title.medium`; artist and album `title.medium` → `title.small`
- `modules/dashboard/media/LyricList.qml` — lyric lines `body.medium` → `body.small`

**Why:** Long track/artist/album names were being clipped; smaller fonts allow more text to fit before eliding.

---

## 2026-06-11: WiFi signal strength and Bluetooth battery percentage in popouts

**Files:**
- `modules/bar/popouts/Network.qml` — added signal strength % for active network
- `modules/bar/popouts/Bluetooth.qml` — added battery % for connected Bluetooth devices

**What:** In the WiFi popout, the currently connected network now shows its signal strength (e.g. `72%`) right-aligned between the SSID name and the disconnect button. In the Bluetooth popout, connected devices that support battery reporting show their battery percentage (e.g. `85%`) in the same position, to the left of the connect button. Percentage turns error-red when battery < 20%, matching the existing battery icon color logic. Both are invisible when not applicable (not connected / battery unavailable).

---

## 2026-06-11: Re-added Shazam, STT, TTS, Mono Audio toggles

**Files:**
- `services/Shazam.qml` (new) — singleton that runs `~/user_scripts/music/music_recognition.sh`; exposes `running` property and `toggle()`
- `services/STT.qml` (new) — singleton that runs `~/user_scripts/tts_stt/stt_record.sh`; exposes `recording` property and `toggle()`
- `services/TTS.qml` (new) — singleton that runs `~/user_scripts/tts_stt/tts_speak.sh`; exposes `speaking` property and `toggle()`
- `services/Mono.qml` (new) — singleton that reads `~/.config/dusky/settings/mono_audio` for state; calls `~/user_scripts/audio/mono_audio_pipewire.py toggle` to toggle; exposes `active` property and `toggle()`
- `modules/utilities/cards/Toggles.qml` — added four `DelegateChoice` blocks (shazam, mono, stt, tts) after the vpn entry

**Icons:** `graphic_eq` (shazam), `speaker` (mono), `speech_to_text` (stt), `text_to_speech` (tts)

**Config:** `shell.json` already has all four entries in `utilities.quickToggles` with `enabled: true` — no change needed there.

---

## 2026-06-11: RAM optimizations

**Files:**
- `~/.config/caelestia/shell.json` — two config changes
- `services/Audio.qml` — gate CavaProvider behind refcount proxy
- `modules/dashboard/media/CoverVisualiser.qml` — point ServiceRef at proxy
- `modules/background/Visualiser.qml` — point ServiceRef at proxy

**Changes:**

1. **Disabled desktop clock blur** (`background.desktopClock.background.blur: false`). Removes a ShaderEffectSource + MultiEffect offscreen framebuffer that sampled the wallpaper texture every frame behind the clock.

2. **Narrowed wallpaper directory** (`paths.wallpaperDir: "/home/tony/walls/dark/favs/"`). The FileSystemModel scans all images recursively and holds every entry as a QML object in memory. Using the smaller favs directory instead of the full walls tree reduces this proportionally.

3. **Gated CavaProvider behind a refcount.** Previously, `CavaProvider { bars: 45 }` was unconditionally instantiated in the `Audio` singleton, running an active Pipewire audio capture + FFT pipeline 24/7. The existing `ServiceRef { service: Audio.cava }` calls had no effect because CavaProvider has no built-in `refCount` property — they were creating a dangling dynamic property.

   Fix: added a `cavaRef` QtObject proxy on the Audio singleton with a real `refCount` property that syncs to `_cavaRefCount`. CavaProvider is now wrapped in a `Loader { asynchronous: false; active: _cavaRefCount > 0 }` so it is only instantiated when the dashboard media tab or background visualiser is active. `Audio.cava` is now a typed property (`CavaProvider`) pointing at `cavaLoader.item`. Updated `ServiceRef` targets in `CoverVisualiser.qml` and `Visualiser.qml` to use `Audio.cavaRef`. Added null-safe access (`?.values ?? []`) at the two value read sites. CavaProvider now only captures audio when the dashboard media tab is open (or the background visualiser is enabled).
