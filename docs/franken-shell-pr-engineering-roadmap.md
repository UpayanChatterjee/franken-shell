# Franken Shell — PR-Scoped Engineering Roadmap

> **Status:** Working execution plan
> **Created:** 2026-07-17
> **Project:** `franken-shell`
> **Primary runtime:** Quickshell / QML
> **Target compositor:** Hyprland 0.55+ with Lua configuration
> **Purpose:** Replace the broad phase-only plan with reviewable pull requests, explicit test cutoffs, evolving CI gates, and ready-to-use implementation-agent instructions.

This document is the operational layer above the existing product, architecture, feature, configuration, decision, and open-question documents. It **does not replace** those specifications. It converts them into mergeable engineering units.

The current baseline is understood to contain Phase 0 plus part of Phase 1: `ConfigService`, typed snapshots, helper/client foundations, `MonitorRegistry`, and `CommandRegistry`. `CapabilityRegistry`, `ThemeManager`, `SurfaceCoordinator`, final IPC, and feature UI remain to be completed.

---

## 1. Operating Rules

### 1.1 Status vocabulary

Use only these values in the roadmap table:

- **open** — planned and ready to start, but no active implementation branch exists;
- **in-progress** — branch work, an active pull request, review fixes, or CI repair is underway;
- **closed** — merged, or deliberately abandoned with the reason recorded in the detailed section and PR.

A blocker does not create a new status. Keep the item `open` or `in-progress` and record the blocker in its PR/issue notes.

### 1.2 Status update rule

The implementation agent must update this file in the same working branch:

1. change `open` to `in-progress` immediately after creating the branch;
2. keep `in-progress` while the PR is open or CI/review work remains;
3. change it to `closed` in the final merge-ready commit or immediately after merge through a tiny bookkeeping PR;
4. never mark a PR `closed` only because code was written locally;
5. record a merged PR number and merge commit beside the detailed section when available.

### 1.3 PR sizing and dependency rules

- Each PR should validate one architectural boundary or one narrow vertical slice.
- A PR must leave `main` runnable and no less diagnosable than before.
- New functional code and its relevant tests belong in the same PR.
- Tests may precede production code, but production code must not be merged with a promise to add tests later.
- Infrastructure changes must not conceal unrelated functional changes.
- A PR that becomes difficult to explain in one paragraph should be split before review.
- Use feature flags/fixture injection rather than merging half-owned global D-Bus services.
- Never create empty placeholder modules merely to match the target directory tree.
- Decisions discovered during implementation go to `docs/decisions.md`; unresolved choices go to `docs/open-questions.md`.

### 1.4 Branch and merge policy

- Branch from current `main` only after required checks pass.
- Naming: `feat/<scope>`, `fix/<scope>`, `test/<scope>`, `chore/<scope>`, `perf/<scope>`, or `docs/<scope>`.
- Prefer small conventional commits while developing; squash merge each PR unless preserving a meaningful multi-commit history is justified.
- Do not push feature work directly to `main` after B-000.
- Do not force-push `main`; allow branch force-push only when needed to clean the active PR.
- While solo-maintained, require CI and the PR checklist rather than mandatory external approval.

---

## 2. Publish the Current Repository

Run from `~/Projects/franken-shell` after confirming the exact path and branch:

```bash
cd ~/Projects/franken-shell
git status --short
git branch --show-current
git log -1 --oneline
gh auth status
```

For a new GitHub repository:

```bash
gh repo create franken-shell --private --source=. --remote=origin --push
git push --follow-tags
```

For an already-created empty repository:

```bash
git remote add origin git@github.com:<owner>/franken-shell.git
git push -u origin main
git push --tags
```

Create a baseline tag only if an equivalent immutable tag is not already present:

```bash
git tag -a engineering-baseline-v1 -m "Pre-PR engineering baseline"
git push origin engineering-baseline-v1
```

Verify publication:

```bash
local_sha=$(git rev-parse HEAD)
remote_sha=$(git ls-remote origin refs/heads/main | awk '{print $1}')
test "$local_sha" = "$remote_sha"
gh repo view --web
```

Do not apply branch protection until PR-001 has created real check names. Afterward, protect `main` with required status checks, blocked force-push/deletion, and a PR requirement. Do not require an external approval while this remains a solo project unless that policy is deliberately changed.

### 2.1 Standard `gh` PR loop

```bash
git switch main
git pull --ff-only
git switch -c <branch-from-roadmap>
# implement, test, and update this roadmap status
git push -u origin HEAD
gh pr create --fill --base main
gh pr checks --watch
gh pr view --web
```

Useful diagnosis commands:

```bash
gh pr checks
gh run list --branch "$(git branch --show-current)"
gh run view <run-id> --log-failed
gh pr diff
gh pr view --comments
```

The implementation agent may use `gh` to create and update PRs, inspect CI, download artifacts, and report the exact failing check. It must not merge while a required check is failing or silently disable a check to obtain green status.

---

## 3. Definition of Done for Every PR

A PR is merge-ready only when all applicable items pass:

1. **Scope:** the PR description states what it changes and what it deliberately does not change.
2. **Architecture:** system access remains behind adapters, authoritative state has one owner, and feature views do not execute raw commands.
3. **Automated tests:** normal, invalid, unavailable, failure, cancellation/reconnect, and lifecycle cases relevant to the change are covered.
4. **Interaction:** keyboard and pointer paths are covered for interactive UI; focus and dismissal are verified.
5. **Lifecycle:** startup, reload, teardown, and duplicate-owner behavior are tested when global objects or services change.
6. **Degraded mode:** an optional dependency can be absent or fail without taking down unrelated shell functionality.
7. **Performance:** no UI-thread blocking, uncontrolled timers, unbounded polling, or obvious event storms are introduced.
8. **Safety:** secrets/private content are not logged; destructive and privileged operations use explicit friction and narrow boundaries.
9. **CI:** all required checks pass in the pinned and Arch lanes; applicable language-native checks run.
10. **Documentation:** decisions, open questions, feature specs, test instructions, and this roadmap status are updated.
11. **Evidence:** manual validation is recorded where hosted CI cannot reproduce compositor/hardware behavior.
12. **Cutoff:** the PR-specific cutoff below is met; passing a smaller subset is not sufficient.

---

## 4. CI Architecture

### 4.1 Required PR pipeline

Keep the initial pull-request path fast and deterministic:

1. **Repository hygiene:** generated-file freshness, forbidden paths/patterns, executable bits, conflict markers, secret scan, and workflow validation.
2. **Formatting:** run the formatter appropriate to each language and Prettier for supported text/config formats.
3. **Lint/static analysis:** QML, Rust, shell, Lua, workflows, Markdown/config, and any newly introduced language.
4. **Unit tests:** pure logic, registries, state machines, formatting, config, helper code, and policies.
5. **Component tests:** visual components with fixtures, keyboard/pointer events, empty/unavailable/failure states, and focus.
6. **Shell smoke:** non-owning fixture-mode startup, readiness, reload, teardown, no duplicate owner, no unexplained QML warning.
7. **Pinned environment:** the authoritative reproducible toolchain.
8. **Arch current:** catches rolling package and filesystem integration problems relevant to Garuda/Arch.

Use stable required-check names even when internal jobs expand. Cancel obsolete runs on the same PR branch.

### 4.2 Scheduled compatibility pipeline

Run nightly or on demand:

- Fedora current;
- newest supported Quickshell/Qt/Hyprland dependency set;
- upstream-edge dependencies as **informational**, never silently promoted to required;
- real-service smoke where a controlled D-Bus/PipeWire/NetworkManager environment exists;
- endurance/reload loops and report-only performance comparisons;
- dependency/security audits that are too slow or noisy for every PR.

The distro matrix validates packaging and dependency differences. It does not replace adapter contracts or a real Hyprland session.

### 4.3 Real compositor and hardware pipeline

Introduce only after the shell owns meaningful surfaces and adapters:

- protected self-hosted runner;
- supported Hyprland baseline and current supported release;
- real layer-shell placement, exclusive zones, focus, reload, monitor hotplug, mixed scale, rotation, and screencopy;
- actual systemd user-service behavior;
- AMD/NVIDIA/hybrid coverage only where hardware exists and a regression justifies it.

Run on merges to `main`, nightly, and release candidates. Never expose self-hosted secrets or privileged access to untrusted fork PRs.

### 4.4 Packaging and release pipeline

Before release, require:

- clean-checkout build/package;
- temporary-root install, first start, upgrade, migration, uninstall, and reinstall;
- installed-files-only smoke test;
- helper/Polkit/systemd validation;
- release diagnostics and redaction checks;
- checksums/provenance/signing supported by the repository;
- declared compatibility matrix and rollback drill.

### 4.5 Language-aware check contract

The CI dispatcher should detect relevant files but keep a repository-wide integrity job. The practical baseline is:

| Language/content | Format | Lint/static analysis | Tests/build |
|---|---|---|---|
| QML/Qt | `qmlformat` | `qmllint` with correct import paths and explicit known suppressions | Qt Quick Test/unit/component and Quickshell smoke |
| Rust | `cargo fmt --check` | `cargo clippy --all-targets --all-features -- -D warnings`; audit/deny as adopted | `cargo test --all-targets --all-features` |
| Shell | `shfmt -d` | `shellcheck` | Bats or executable integration tests when behavior exists |
| Lua | `stylua --check` | `selene` or the project-selected Lua linter | language-native tests or config-load smoke |
| JS/TS | Prettier | ESLint/type-check according to the package | package test/build commands |
| JSON/YAML/Markdown/CSS | Prettier | schema validation, `markdownlint`, link checks where appropriate | generated/config fixture validation |
| Python, if introduced | `ruff format --check` | `ruff check`; type check if adopted | `pytest` |
| Go, if introduced | `gofmt` | `go vet`/selected static checker | `go test ./...` |
| C/C++, if introduced | `clang-format --dry-run --Werror` | `clang-tidy`/compiler warnings as errors | configured build and test runner |
| GitHub Actions | YAML/Prettier | `actionlint` and least-privilege review | disposable failure-path validation |

**New-language rule:** the first PR introducing a new implementation language must also add its pinned toolchain, formatter, linter/static analysis, test command, cache policy, local `ci/` entry point, and CI routing. A language may not be merged as an unchecked exception.

### 4.6 Change-to-test expansion rule

| Functional change | Minimum added coverage |
|---|---|
| New singleton/registry/public method | normal, invalid, failure, lifecycle/reload |
| New state or transition | entry, exit, cancellation, unexpected event |
| New config field/schema version | default, valid, invalid, reload, migration/last-valid |
| New external command | availability, exact argv, success, nonzero exit, timeout/cancel |
| New adapter property/action | available, unavailable, update/action, disconnect/reconnect, malformed data |
| New interactive component | keyboard, pointer, focus, disabled/unavailable, empty/long data |
| New surface/global owner | startup, open/close, arbitration, focus restoration, reload/no duplicate |
| New IPC method | valid, malformed, unsupported version, capability denial, failure response |
| New privileged operation | validation, authorization denial, path restriction, atomicity, rollback |
| New package/migration | clean install, upgrade, failure, rollback, uninstall, user-data preservation |

A PR description must identify which rows apply and link the tests that satisfy them.

### 4.7 Diagnostics artifacts

On failure, upload only redacted evidence:

- test reports;
- Quickshell stdout/stderr and structured logs;
- toolchain and dependency versions;
- QML import paths;
- readiness/capability summary;
- process tree and leaked-child report;
- synthetic fixture screenshots/diffs;
- package manifest and generated test configuration.

Never upload credentials, OAuth tokens, Wi-Fi secrets, notification bodies, private clipboard data, or unrestricted user configuration.

---

## 5. Bird’s-Eye PR Ledger

The sequence is dependency-aware, but a later item may be reordered only when its prerequisites and cutoffs remain valid.


| ID | Milestone | Brief outcome | Branch | Test-validated cutoff | Status |
|---|---|---|---|---|---|
| **B-000** | Repository baseline | Publish the current committed local project unchanged, establish `main` as the remote baseline, and preserve the pre-PR history with an annotated tag. | `main` | Remote `main` exactly represents the current committed local state, tags are present, and a fresh clone is usable. | **closed** |
| **PR-001** | Engineering foundation | Add the repository workflow, PR bookkeeping, language-aware validation scripts, fast CI, and nightly compatibility structure. | `chore/engineering-foundation` | A pull request receives real format, lint, test, and smoke results in both pinned and Arch lanes; failures upload diagnostics; the same commands run locally. | **open** |
| **PR-002** | Core baseline | Backfill tests and smoke coverage for the already implemented ConfigService, typed snapshots, helper/client foundation, MonitorRegistry, and CommandRegistry. | `test/core-baseline` | Every currently implemented core subsystem has direct contract tests, startup/reload smoke passes, and there are no unexplained warnings or leaked child processes. | **open** |
| **PR-003** | Core skeleton | Implement CapabilityRegistry, diagnostics/error aggregation, ShellState, and explicit readiness/degraded-state reporting. | `feat/core-readiness-diagnostics` | The shell reports truthful readiness and capability state, optional failures remain local, and CI can wait on readiness without arbitrary sleeps. | **open** |
| **PR-004** | Core skeleton | Implement ThemeManager and semantic design tokens with atomic fallback and reload behavior. | `feat/theme-manager` | The shell always has a coherent theme, invalid or partial updates cannot leak into UI, and no new feature-facing raw palette ownership is introduced. | **open** |
| **PR-005** | Core skeleton | Implement SurfaceCoordinator, focus/dismissal contracts, monitor ownership, and the minimal shell IPC surface. | `feat/surface-coordinator-ipc` | Transient ownership and IPC are deterministic, focus restoration has a testable contract, and reload does not duplicate global owners. | **open** |
| **PR-006** | Shell appears | Create the monitor-aware BarHost and stable semantic layout zones using fixture content. | `feat/bar-host-layout` | A stable fixture bar renders without layout jitter, is owned by the monitor model, and can later rotate without rewriting each delegate. | **open** |
| **PR-007** | Shell appears | Implement the fixture numbered-workspace pager and special-workspace selector as controller-driven components. | `feat/workspace-pager` | All documented fixture workspace states pass, commands route through injected controllers, and the pager remains stable under rapid input. | **open** |
| **PR-008** | Shell appears | Add the anchor-aware PopoverHost, fixture bar items, layout-stability coverage, and normalized fullscreen hide behavior. | `feat/bar-popovers-fixtures` | Milestone A is met: the fixture shell starts, shows a stable bar, changes workspace groups, opens popovers, and distinguishes maximized from fullscreen. | **open** |
| **PR-009** | Drawer works | Select and implement the ControlCenterHost primitive with keyboard/pointer open-close, scrim, focus, and outside dismissal. | `feat/control-centre-host` | The selected primitive is documented, explicit opening and dismissal are reliable, and focus behavior is repeatable without timing sleeps. | **open** |
| **PR-010** | Drawer works | Implement the edge-drag intent/state machine and direct manipulation of control-centre reveal progress. | `feat/control-centre-drag` | The drawer follows the pointer, settles predictably, rejects vertical intent, and passes the critical stop condition before feature work continues. | **open** |
| **PR-011** | Drawer works | Add the control-centre page stack, tabs, placeholder quick controls/sliders, keyboard navigation, and Escape unwinding. | `feat/control-centre-navigation` | Milestone B is met: the drawer opens by explicit action and edge drag, navigates predictably, unwinds correctly, and contains no backend coupling. | **open** |
| **PR-012** | Real desktop state | Implement the normalized Hyprland adapter and connect live workspace/fullscreen state through existing controllers. | `feat/hyprland-adapter` | Live workspace and fullscreen behavior can replace fixtures, reconnects without shell restart, and all views remain backend-agnostic. | **open** |
| **PR-013** | Real desktop state | Implement the audio adapter for default devices, volume/mute, streams, and normalized output classification. | `feat/audio-adapter` | Audio state/actions are authoritative and reconnecting; bar interactions work; absence degrades without breaking the shell. | **open** |
| **PR-014** | Real desktop state | Implement battery and brightness adapters with capability-aware omission and asynchronous actions. | `feat/power-brightness-adapters` | Laptop and desktop/no-capability fixtures behave correctly, actions never block the UI thread, and unsupported controls disappear cleanly. | **open** |
| **PR-015** | Real desktop state | Implement network throughput and low-frequency resource summary adapters with bounded polling. | `feat/throughput-resource-adapters` | Persistent metrics are stable, bounded, and non-blocking; hidden detail consumers reduce or stop elevated polling. | **open** |
| **PR-016** | Real desktop state | Implement the Network adapter and control-centre model for connectivity, scans, saved networks, and connection tasks. | `feat/network-adapter` | Network state/actions are normalized, secrets remain private, progress/errors are explicit, and backend failure does not prevent opening the drawer. | **open** |
| **PR-017** | Real desktop state | Implement the Bluetooth adapter and control-centre model including pairing task states and graceful absence. | `feat/bluetooth-adapter` | Bluetooth can be absent or restart safely, pairing state is explicit, and device/audio ownership boundaries remain clean. | **open** |
| **PR-018** | Real desktop state | Implement the tray adapter, collapsed affordance, drawer model, menus, activation, secondary activation, and scroll. | `feat/tray-adapter` | Tray interactions work through one adapter, empty/large states are correct, and development mode avoids duplicate global ownership. | **open** |
| **PR-019** | Notification-complete prototype | Implement normalized notification service ownership, in-memory history, and the pure policy engine for DND/fullscreen/grouping. | `feat/notification-core-policy` | Notification state and policy are deterministic and content-private; DND/fullscreen decisions can be tested without UI or live D-Bus. | **open** |
| **PR-020** | Notification-complete prototype | Implement notification popup stack and grouped drawer history with focus-safe interaction. | `feat/notification-surfaces` | Ordinary application notifications render and remain manageable under bursts, no unread count exists, and opening history prevents duplicate interruption. | **open** |
| **PR-021** | Notification-complete prototype | Implement keyed system toasts, volume/brightness OSDs, and the initial notification sound policy. | `feat/toasts-osds` | Milestone D is met: notifications, DND, history, toasts, and OSDs are behaviorally distinct and pass the documented policy matrix. | **open** |
| **PR-022** | Daily-use prototype | Compose the real persistent bar from live adapters and complete its practical interactions and contextual-status policy. | `feat/daily-use-bar` | The persistent bar can replace the current shell bar for a normal session without a blocker; optional failures remain local and visible. | **open** |
| **PR-023** | Daily-use prototype | Replace control-centre placeholders with practical audio, brightness, network, Bluetooth, notification, and quick-control workflows. | `feat/daily-use-control-centre` | The control centre handles ordinary daily audio/device/connectivity/notification tasks and remains usable when any one backend fails. | **open** |
| **PR-024** | Daily-use prototype | Stabilize the prototype through sustained use, eliminate blocker defects, and establish performance/reliability baselines. | `perf/daily-use-stabilization` | Milestone E is met: no blocker-level daily-use defect remains, every fixed bug has a regression test, and baseline performance/reliability data is recorded. | **open** |
| **PR-025** | Integrated ecosystem | Research, pin, and document the quickshell-overview compatibility and invocation contract before code integration. | `chore/overview-contract-pin` | The integration contract is evidence-based and pinned; the next PR can implement without guessing upstream behavior. | **open** |
| **PR-026** | Integrated ecosystem | Implement OverviewAdapter, invocation/fallback, shared workspace configuration, theme sync, and diagnostics. | `feat/overview-adapter-sync` | The overview behaves as an optional first-class integration, uses shared config/theme, and cannot break direct navigation when it fails. | **open** |
| **PR-027** | Integrated ecosystem | Implement Vicinae availability, command mapping, first-party shell extension contract, and shared theme generation. | `feat/vicinae-integration` | Milestone F is met: Vicinae and overview are optional but coherent shell integrations with versioned contracts, diagnostics, and fallbacks. | **open** |
| **PR-028** | Deeper utilities | Implement detailed resource and sensor services with generic interfaces and capability-driven omission. | `feat/resource-sensors` | Detailed metrics are capability-driven and bounded; unsupported hardware degrades cleanly; the full monitor remains external. | **open** |
| **PR-029** | Deeper utilities | Implement the narrowly scoped auto-cpufreq privileged helper, validation, atomic writes, backups, and Polkit boundary. | `feat/auto-cpufreq-helper` | The helper passes an explicit security review checklist, cannot escape its narrow contract, and recovers safely from failed writes. | **open** |
| **PR-030** | Deeper utilities | Implement the power and auto-cpufreq panel over the approved helper with apply/revert and truthful capability states. | `feat/power-panel` | Power management is useful without weakening the privilege boundary; failed or absent auto-cpufreq never harms battery display or configuration. | **open** |
| **PR-031** | Deeper utilities | Implement the local calendar panel and a provider-neutral calendar contract without network accounts. | `feat/calendar-provider-local` | The local calendar is complete and accessible, and a clean provider boundary exists for optional future account integration. | **open** |
| **PR-032** | Optional near-term integration | Add Google Calendar through the provider contract with secure authentication and storage; it is not a blocker for the first stable shell. | `feat/google-calendar-integration` | Google integration can be enabled or absent independently, secrets are securely handled, and the local calendar remains fully functional on failure. | **open** |
| **PR-033** | Deeper utilities | Implement focused-window actions and session/power actions with explicit destructive confirmation and stable targeting. | `feat/window-session-actions` | Window/session actions are keyboard-accessible, safely targeted, and cannot accidentally escalate from graceful to destructive behavior. | **open** |
| **PR-034** | Feature-complete beta | Implement the settings/configuration UI, schema-aware validation, diagnostics surface, and user-safe save/apply behavior. | `feat/settings-config-ui` | Settings safely manage the authoritative configuration, failures are recoverable, and diagnostics make broken configuration actionable. | **open** |
| **PR-035** | Feature-complete beta | Finalize per-monitor ownership, hotplug, mixed scaling, rotation, and recovery across bars, popovers, drawer, overview, and notifications. | `feat/multi-monitor-hardening` | All major surfaces follow a documented ownership policy and recover from topology changes without crashes, lost focus, duplicates, or off-screen placement. | **open** |
| **PR-036** | Feature-complete beta | Add approved trackpad gestures and establish controlled real-Hyprland/hardware acceptance CI. | `feat/gestures-hardware-acceptance` | Gestures are optional and reliable where supported, and real compositor/hardware regressions have a reproducible acceptance lane. | **open** |
| **PR-037** | Polished beta | Apply final visual language, accessibility, reduced motion, text scaling, and controlled visual regression coverage. | `feat/visual-accessibility` | The shell remains readable and usable across representative themes/scales, interaction is never delayed by motion, and visual regressions are reviewable rather than hidden. | **open** |
| **PR-038** | Release hardening | Add Arch/Garuda-first installation, systemd user service, Polkit/helper installation, migrations, uninstall, and package validation. | `chore/arch-packaging-systemd` | A clean Arch/Garuda-class system can install, start, upgrade, diagnose, and uninstall the shell safely while preserving user data. | **open** |
| **PR-039** | Release hardening | Finalize release CI, compatibility policy, diagnostics bundle, documentation, changelog, signing/checksums, and release checklist. | `chore/release-pipeline-docs` | A release is reproducible, installable, diagnosable, documented, and gated by the declared compatibility/test matrix; rollback is documented and practiced. | **open** |

---

## 6. Detailed PR Instructions


### B-000 — Publish the current committed local project unchanged, establish `main` as the remote baseline, and preserve the pre-PR history with an annotated tag.

- **Milestone:** Repository baseline
- **Branch:** `main`
- **Status:** **closed**
- **Merged PR / commit:** Direct baseline publication; no PR. Baseline commit `d02c7946e69a195e3e53a3ac9da8bfaa4aa353ec`.

#### Closure record

- **Repository:** `https://github.com/UpayanChatterjee/franken-shell`
- **Default branch:** `main`
- **Baseline tag:** `engineering-baseline-v1`
- **Closed:** 2026-07-17
- **Evidence:** remote `main` matched the baseline commit before bookkeeping, a fresh shallow clone checked out that exact commit, the documented development entry point was present and executable, and the clone completed the existing QML check.

#### Scope
- Verify the working tree is clean and inspect the current branch and tags.
- Create or attach the GitHub repository, add `origin`, and push the current branch and all relevant tags.
- Create an annotated baseline tag if one does not already identify the exact imported state.
- Record the repository URL, default branch, baseline SHA, and tag in `docs/project-state.md`.

#### Explicitly out of scope
- Do not refactor, reformat, squash, or reorder current commits during publication.
- Do not enable branch protection until the first CI workflow exists.

#### Required tests and evidence
- Run the existing development validation commands before pushing.
- Confirm `git rev-parse HEAD` matches the remote `main` SHA.
- Confirm a fresh clone can check out the baseline and find the documented development entry point.

#### CI evolution

None yet; this establishes the immutable starting point that PR-001 will protect.

#### Merge cutoff

**Remote `main` exactly represents the current committed local state, tags are present, and a fresh clone is usable.**

#### Ready-to-use implementation-agent prompt

```text
Publish the current Franken Shell repository to GitHub without changing functional content or rewriting history. Verify the local tree, create or attach the remote with `gh`, push `main` and tags, confirm the remote SHA matches local HEAD, and record the repository URL and baseline tag in `docs/project-state.md`. Stop if publication would overwrite unrelated remote history.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-001 — Add the repository workflow, PR bookkeeping, language-aware validation scripts, fast CI, and nightly compatibility structure.

- **Milestone:** Engineering foundation
- **Branch:** `chore/engineering-foundation`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Add `.github/pull_request_template.md`, contribution conventions, and the roadmap status-update rule.
- Create repository-owned `ci/` entry points for format, lint, unit, smoke, and diagnostics collection.
- Add path-aware checks for QML, Rust, shell, Lua, Markdown, JSON, YAML, JavaScript/TypeScript, and any language already present.
- Create required PR jobs for a pinned toolchain and Arch-current environment; create a scheduled Fedora/latest-dependency workflow.
- Use stable check names, least-privilege workflow permissions, concurrency cancellation, dependency caches, and failure artifacts.
- Document branch protection and the local commands equivalent to CI.

#### Explicitly out of scope
- Do not add feature code or perform broad formatting unrelated to CI setup.
- Do not create empty test jobs that always pass; a job exists only when it performs a real check.
- Do not require human approval while the project is solo-maintained unless the owner explicitly changes that policy.

#### Required tests and evidence
- Run `actionlint` or an equivalent workflow validator.
- Run every `ci/` entry point locally against the repository.
- Temporarily introduce a formatting error and a failing test in a disposable commit/worktree to prove CI fails for the correct reason.
- Verify changed-file routing never skips a repository-wide integrity check required for safety.

#### CI evolution

Establish `CI / Format`, `CI / Lint`, `CI / Unit`, `CI / Smoke`, `CI / Pinned`, and `CI / Arch`; add non-blocking nightly Fedora/latest lanes.

#### Merge cutoff

**A pull request receives real format, lint, test, and smoke results in both pinned and Arch lanes; failures upload diagnostics; the same commands run locally.**

#### Ready-to-use implementation-agent prompt

```text
Create the practical engineering foundation for Franken Shell. Add repository-owned CI scripts, PR templates, stable workflow checks, pinned and Arch PR lanes, nightly Fedora/latest compatibility, language-aware formatting/linting/testing, least-privilege permissions, concurrency cancellation, caching, and failure artifacts. Keep the change infrastructure-only and prove both success and intentional failure paths.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-002 — Backfill tests and smoke coverage for the already implemented ConfigService, typed snapshots, helper/client foundation, MonitorRegistry, and CommandRegistry.

- **Milestone:** Core baseline
- **Branch:** `test/core-baseline`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Inventory the existing Phase 0 and Phase 1 implementation without redesigning it.
- Create deterministic fixtures and a documented test runner.
- Test config defaults, valid/invalid input, last-valid retention, helper/client protocol errors, monitor normalization, and CommandRegistry lifecycle.
- Add shell startup and reload smoke tests in a non-owning mock mode.
- Make unexpected QML warnings and binding-loop messages fail the smoke job after known false positives are explicitly documented.

#### Explicitly out of scope
- Do not add CapabilityRegistry, ThemeManager, SurfaceCoordinator, or feature UI.
- Do not modify public contracts merely to simplify tests unless the existing contract is demonstrably broken and documented.

#### Required tests and evidence
- QML unit tests for normal, invalid, unavailable, failure, cancellation, and reload cases.
- Process cleanup and duplicate-instance checks.
- Mock startup reaches a deterministic readiness sentinel and exits cleanly.
- Rust tests for any existing helper/client code plus `cargo fmt`, `clippy`, and `test`.

#### CI evolution

Make core unit and smoke jobs blocking; preserve artifacts containing Quickshell logs, process tree, versions, and test reports.

#### Merge cutoff

**Every currently implemented core subsystem has direct contract tests, startup/reload smoke passes, and there are no unexplained warnings or leaked child processes.**

#### Ready-to-use implementation-agent prompt

```text
Stabilize the current Franken Shell baseline before adding new architecture. Inventory the existing ConfigService, snapshots, helper/client, MonitorRegistry, and CommandRegistry; add deterministic contract tests and non-owning startup/reload smoke tests; fail on unexplained warnings and leaks. Do not introduce the remaining Phase 1 services in this PR.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-003 — Implement CapabilityRegistry, diagnostics/error aggregation, ShellState, and explicit readiness/degraded-state reporting.

- **Milestone:** Core skeleton
- **Branch:** `feat/core-readiness-diagnostics`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Add one authoritative capability model with available, unavailable, degraded, and failed distinctions.
- Add structured diagnostics and an error model that avoids secrets and notification contents.
- Expose shell readiness states from bootstrapping through surfaces-ready and degraded.
- Provide a deterministic IPC- or log-based readiness signal for smoke tests.
- Integrate existing core services without creating duplicate state owners.

#### Explicitly out of scope
- Do not implement feature-specific capabilities beyond the initial architecture list.
- Do not let an optional capability block the fallback shell readiness path.

#### Required tests and evidence
- State-transition tests, aggregation tests, repeated-error coalescing, and redaction tests.
- Startup with all optional integrations missing must reach `Degraded`, not `Failed`.
- Required-core failure must produce a diagnosable nonzero smoke result.

#### CI evolution

Extend smoke tests with healthy, degraded, and required-core-failure scenarios.

#### Merge cutoff

**The shell reports truthful readiness and capability state, optional failures remain local, and CI can wait on readiness without arbitrary sleeps.**

#### Ready-to-use implementation-agent prompt

```text
Implement Franken Shell readiness, capability, and diagnostics foundations. Add CapabilityRegistry, ShellState, structured diagnostics/error aggregation, redaction, and a deterministic readiness signal. Test healthy, degraded, repeated-error, and required-core-failure paths. Preserve one source of truth and prevent optional integrations from blocking usable startup.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-004 — Implement ThemeManager and semantic design tokens with atomic fallback and reload behavior.

- **Milestone:** Core skeleton
- **Branch:** `feat/theme-manager`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Add semantic colors, typography, spacing, radii, and motion tokens.
- Keep a built-in valid fallback theme independent of Caelestia.
- Apply candidate themes atomically only after validation and retain the last valid theme.
- Expose fixture themes for dark/light, low/high contrast, and reduced motion.
- Document the adapter boundary for later Caelestia dynamic colors.

#### Explicitly out of scope
- Do not integrate wallpaper color generation yet.
- Do not spread raw color literals through feature code.

#### Required tests and evidence
- Token completeness and type validation.
- Invalid candidate retains last valid theme.
- Rapid reloads settle on one coherent snapshot.
- Representative components instantiate under every fixture theme.

#### CI evolution

Add a theme contract suite and formatting/lint checks for token/config files.

#### Merge cutoff

**The shell always has a coherent theme, invalid or partial updates cannot leak into UI, and no new feature-facing raw palette ownership is introduced.**

#### Ready-to-use implementation-agent prompt

```text
Implement the semantic ThemeManager foundation with a guaranteed built-in fallback, atomic validated updates, last-valid retention, and fixture themes for contrast and reduced motion. Add contract tests for completeness, invalid candidates, and rapid reloads. Do not add Caelestia wallpaper integration or feature-specific styling.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-005 — Implement SurfaceCoordinator, focus/dismissal contracts, monitor ownership, and the minimal shell IPC surface.

- **Milestone:** Core skeleton
- **Branch:** `feat/surface-coordinator-ipc`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Coordinate one major transient surface and one anchored popover policy.
- Track origin control and monitor for focus restoration.
- Implement close-all and replacement behavior.
- Expose version, diagnostics, config reload, and close-transients through a compact versioned IPC contract.
- Add reload safety so handlers and surface ownership are not duplicated.

#### Explicitly out of scope
- Do not implement final BarHost or ControlCenterHost visuals.
- Do not expose arbitrary internal properties or general command execution through IPC.

#### Required tests and evidence
- Pure state-machine tests for open, replace, close, Escape, owner disappearance, and monitor removal.
- IPC tests for valid, malformed, unsupported-version, and repeated requests.
- Reload smoke proves no duplicate IPC handler or surface owner.

#### CI evolution

Add component-independent coordinator tests and IPC smoke coverage.

#### Merge cutoff

**Transient ownership and IPC are deterministic, focus restoration has a testable contract, and reload does not duplicate global owners.**

#### Ready-to-use implementation-agent prompt

```text
Implement SurfaceCoordinator and the minimal versioned shell IPC contract. Centralize major-surface/popover arbitration, origin and monitor tracking, focus restoration, close-all behavior, and reload safety. Test state transitions, malformed IPC, owner disappearance, monitor removal, and duplicate-handler prevention. Do not build final surfaces in this PR.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-006 — Create the monitor-aware BarHost and stable semantic layout zones using fixture content.

- **Milestone:** Shell appears
- **Branch:** `feat/bar-host-layout`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Create one left-edge BarHost on a selected monitor.
- Implement start, flexible, context, end, and absolute-end zones.
- Centralize thickness, edge, insets, and exclusive-zone behavior.
- Provide orientation abstractions without claiming all four edges are polished.
- Keep the host compatible with fixture mode and SurfaceCoordinator.

#### Explicitly out of scope
- Do not connect real system adapters.
- Do not implement autohide or final visual effects.

#### Required tests and evidence
- Component instantiation under normal, long-text, high-text-scale, and missing-item fixtures.
- Geometry assertions prove changing values do not move protected end controls.
- Startup/reload smoke with the BarHost enabled.

#### CI evolution

Add bar component tests and fixture screenshots as non-blocking artifacts.

#### Merge cutoff

**A stable fixture bar renders without layout jitter, is owned by the monitor model, and can later rotate without rewriting each delegate.**

#### Ready-to-use implementation-agent prompt

```text
Build the first monitor-aware left BarHost with semantic layout zones and stable geometry. Use fixture content only, centralize edge/thickness metrics, integrate SurfaceCoordinator ownership, and add component tests for long values, text scale, missing items, and reload. Defer real adapters, autohide, and final polish.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-007 — Implement the fixture numbered-workspace pager and special-workspace selector as controller-driven components.

- **Milestone:** Shell appears
- **Branch:** `feat/workspace-pager`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement configurable contiguous workspace groups, defaulting to groups of five.
- Support click, normalized scroll, keyboard traversal, and active-workspace policy injection.
- Implement one persistent special-workspace control and selector using authoritative fixture definitions.
- Ensure occupancy and application icons are absent.
- Expose inaccessible/unavailable/busy/failure states without raw Hyprland commands in views.

#### Explicitly out of scope
- Do not connect live Hyprland or quickshell-overview.
- Do not settle the final active-workspace click behavior beyond a replaceable policy hook.

#### Required tests and evidence
- Boundary groups: 1, 5, 6, 7, 10, partial final group, alternate group sizes, wrap/no-wrap.
- Rapid high-resolution scroll is coalesced.
- Keyboard focus survives group changes and Escape restores focus.
- Overview unavailable/failure does not disable direct pager behavior.

#### CI evolution

Add dedicated workspace unit/component suite as a blocking check.

#### Merge cutoff

**All documented fixture workspace states pass, commands route through injected controllers, and the pager remains stable under rapid input.**

#### Ready-to-use implementation-agent prompt

```text
Implement the fixture workspace pager and special-workspace selector with configurable grouping, keyboard/pointer parity, normalized scrolling, replaceable active-workspace policy, and no backend commands in views. Cover boundary groups, rapid input, unavailable/failure states, and focus restoration. Keep Hyprland and overview integration out of scope.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-008 — Add the anchor-aware PopoverHost, fixture bar items, layout-stability coverage, and normalized fullscreen hide behavior.

- **Milestone:** Shell appears
- **Branch:** `feat/bar-popovers-fixtures`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement one anchor-aware popover host governed by SurfaceCoordinator.
- Add fixture forms of throughput, audio, resources, battery, date/time, tray, Vicinae, and contextual slots.
- Support open/toggle, outside click, Escape, and focus restoration.
- Wire normalized fixture fullscreen state so true fullscreen hides the bar while maximized does not.
- Use stable cells and tabular numeric treatment where relevant.

#### Explicitly out of scope
- Do not add real services or detailed popover feature workflows.
- Do not implement autohide.

#### Required tests and evidence
- Only one popover is open; switching anchors replaces it cleanly.
- Long numeric and localized fixture values do not shift neighbors.
- Maximized and fullscreen fixtures produce different visibility.
- Keyboard-only and pointer-only opening/dismissal paths pass.

#### CI evolution

Promote bar component tests and shell-appears smoke to required checks.

#### Merge cutoff

**Milestone A is met: the fixture shell starts, shows a stable bar, changes workspace groups, opens popovers, and distinguishes maximized from fullscreen.**

#### Ready-to-use implementation-agent prompt

```text
Complete the fixture bar milestone by adding the centralized PopoverHost, all placeholder bar items, focus-safe open/dismiss behavior, layout-stability tests, and normalized fullscreen hiding. Keep services mocked and autohide deferred. The PR is complete only when the shell-appears smoke path is deterministic.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-009 — Select and implement the ControlCenterHost primitive with keyboard/pointer open-close, scrim, focus, and outside dismissal.

- **Milestone:** Drawer works
- **Branch:** `feat/control-centre-host`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Prototype the plausible Quickshell surface primitives narrowly and record the choice in an ADR.
- Implement a right-edge host with no permanent exclusive zone.
- Support explicit keyboard open, pointer button open, scrim, outside click, close, and focus restoration.
- Integrate with SurfaceCoordinator so it closes bar popovers.
- Render placeholder content only.

#### Explicitly out of scope
- Do not implement edge drag, real controls, or backend pages.
- Do not hide unresolved focus limitations with arbitrary delays.

#### Required tests and evidence
- Host open/close and major-surface arbitration.
- Escape closes and restores the invoking focus target.
- Pointer and keyboard opening follow the documented focus policy.
- Reload does not create duplicate hosts or scrims.

#### CI evolution

Add control-centre host component/smoke tests; attach diagnostic screenshots on failure.

#### Merge cutoff

**The selected primitive is documented, explicit opening and dismissal are reliable, and focus behavior is repeatable without timing sleeps.**

#### Ready-to-use implementation-agent prompt

```text
Prototype and select the ControlCenterHost surface primitive, document the ADR, then implement explicit keyboard/pointer opening, scrim, outside-click dismissal, focus acquisition/restoration, and SurfaceCoordinator arbitration. Use placeholder content and deterministic tests. Do not implement edge dragging or real service controls.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-010 — Implement the edge-drag intent/state machine and direct manipulation of control-centre reveal progress.

- **Milestone:** Drawer works
- **Branch:** `feat/control-centre-drag`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement the documented drag states as a testable controller.
- Use configurable activation width, intent ratio, distance, and velocity thresholds.
- Make panel and scrim follow reveal progress and support reversal/cancellation.
- Suppress pointer edge drag under normalized fullscreen policy.
- Keep vertical child interactions from falsely opening the drawer.

#### Explicitly out of scope
- Do not add a trackpad gesture.
- Do not tune by hiding failures with large activation regions or excessive thresholds.

#### Required tests and evidence
- Start outside strip, mostly vertical movement, insufficient movement, threshold open, velocity open, reversal, cancellation, and fullscreen suppression.
- Deterministic fake clock/velocity tests.
- Manual pointer test on the development machine with captured notes.

#### CI evolution

Add pure state-machine tests as blocking; keep real pointer compositor validation documented until hardware CI exists.

#### Merge cutoff

**The drawer follows the pointer, settles predictably, rejects vertical intent, and passes the critical stop condition before feature work continues.**

#### Ready-to-use implementation-agent prompt

```text
Implement the control-centre edge-drag state machine as isolated, deterministic logic and connect it to direct reveal progress. Cover intent discrimination, distance/velocity thresholds, reversal, cancellation, and fullscreen suppression with fake-time tests. Do not add trackpad gestures or compensate for bugs using overly broad activation.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-011 — Add the control-centre page stack, tabs, placeholder quick controls/sliders, keyboard navigation, and Escape unwinding.

- **Milestone:** Drawer works
- **Branch:** `feat/control-centre-navigation`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Create header, quick-control row, volume/brightness placeholders, Notifications and Mixer tabs, and nested Network/Bluetooth placeholders.
- Implement tab, arrow, back, Escape, and pointer navigation.
- Define safe state restoration boundaries without preserving credentials or confirmations.
- Ensure dragging closed and outside click behave correctly on nested pages.
- Keep all backend state injected.

#### Explicitly out of scope
- Do not implement real Network, Bluetooth, audio, brightness, or notification models.
- Do not create duplicate feature-owned service state.

#### Required tests and evidence
- Keyboard-only traversal and pointer-only traversal.
- Escape pops detail page before closing drawer.
- Unavailable/busy/failed placeholders remain independently usable.
- Open/close cycles do not leak page or focus state.

#### CI evolution

Make drawer component/navigation tests and drawer smoke required.

#### Merge cutoff

**Milestone B is met: the drawer opens by explicit action and edge drag, navigates predictably, unwinds correctly, and contains no backend coupling.**

#### Ready-to-use implementation-agent prompt

```text
Complete the fixture control-centre mechanics with page stack, tabs, placeholder quick controls/sliders, nested Network/Bluetooth pages, keyboard/pointer navigation, safe restoration, and correct Escape unwinding. All state must be injected; no backend imports or command execution belongs in this PR.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-012 — Implement the normalized Hyprland adapter and connect live workspace/fullscreen state through existing controllers.

- **Milestone:** Real desktop state
- **Branch:** `feat/hyprland-adapter`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose active workspace, workspace list, special workspaces, focused window/monitor, fullscreen, and urgent state.
- Provide normalized command methods through CommandRegistry.
- Handle event-stream interruption and state resynchronization.
- Connect the pager and fullscreen policy without leaking raw Hyprland syntax into views.
- Document minimum supported Hyprland behavior and version diagnostics.

#### Explicitly out of scope
- Do not add focused-window action UI or overview integration.
- Do not treat maximized as fullscreen.

#### Required tests and evidence
- Fixture contract tests for all events and commands.
- Malformed event, disconnect, reconnect, stale state, and command failure tests.
- Developer-machine acceptance: direct compositor shortcuts update UI, special workspace state is truthful, and reconnect works.

#### CI evolution

Add adapter-contract tests to PR CI; schedule real Hyprland smoke only when a controlled runner exists.

#### Merge cutoff

**Live workspace and fullscreen behavior can replace fixtures, reconnects without shell restart, and all views remain backend-agnostic.**

#### Ready-to-use implementation-agent prompt

```text
Implement a normalized, reconnecting Hyprland adapter and connect live workspace/fullscreen state through existing controllers. Keep raw dispatchers and event parsing inside the adapter, distinguish maximized from fullscreen, add fixture contracts and developer-machine acceptance evidence, and defer overview and focused-window UI.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-013 — Implement the audio adapter for default devices, volume/mute, streams, and normalized output classification.

- **Milestone:** Real desktop state
- **Branch:** `feat/audio-adapter`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose default input/output, volume, mute, devices, application streams, and availability.
- Provide set volume, mute, device selection, and stream actions.
- Centralize output icon classification with an unknown/fallback category.
- Connect bar scroll/middle-click and fixture mixer models through the adapter.
- Handle service restart and device disappearance.

#### Explicitly out of scope
- Do not build the final mixer UI or embed OSD UI in the service.
- Do not maintain a second audio model in bar/control-centre code.

#### Required tests and evidence
- No backend, service starts late, default device replacement, stream disappearance, action failure, and reconnect.
- Volume bounds and coalesced scroll input.
- No duplicate model ownership after reload.

#### CI evolution

Add audio adapter contract suite; real PipeWire virtual-device smoke can be nightly when available.

#### Merge cutoff

**Audio state/actions are authoritative and reconnecting; bar interactions work; absence degrades without breaking the shell.**

#### Ready-to-use implementation-agent prompt

```text
Implement the authoritative audio adapter with normalized devices, default input/output, volume/mute, application streams, actions, classification fallback, and reconnect handling. Connect bar actions through the adapter, add absence/restart/device-replacement tests, and keep mixer presentation and OSD ownership out of scope.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-014 — Implement battery and brightness adapters with capability-aware omission and asynchronous actions.

- **Milestone:** Real desktop state
- **Branch:** `feat/power-brightness-adapters`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose battery availability, percentage, charging, power source, credible estimates, and thresholds.
- Expose brightness availability, value, range, and target.
- Connect battery bar state and control-centre brightness slider.
- Use asynchronous writes and truthful pending/failure state.
- Omit unsupported controls rather than rendering dead UI.

#### Explicitly out of scope
- Do not implement auto-cpufreq configuration or brightness OSD yet.
- Do not hard-code one machine device path in UI.

#### Required tests and evidence
- No battery, charging/discharging, invalid estimate, low/critical, no brightness device, multiple target fixture, write failure, and delayed update.
- Hidden surfaces do not poll unnecessarily.

#### CI evolution

Add power/brightness contract tests and timing guards against synchronous process calls.

#### Merge cutoff

**Laptop and desktop/no-capability fixtures behave correctly, actions never block the UI thread, and unsupported controls disappear cleanly.**

#### Ready-to-use implementation-agent prompt

```text
Implement normalized battery and brightness adapters with capability-aware omission, asynchronous actions, pending/failure states, and no UI-owned device paths. Connect the existing battery/slider surfaces, cover no-device and write-failure cases, and defer auto-cpufreq and OSD presentation.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-015 — Implement network throughput and low-frequency resource summary adapters with bounded polling.

- **Milestone:** Real desktop state
- **Branch:** `feat/throughput-resource-adapters`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose raw and smoothed upload/download rates with compact formatting.
- Aggregate active interfaces without assuming Wi-Fi only.
- Expose low-frequency RAM/CPU/storage summary and availability.
- Increase polling only when a detailed consumer explicitly requests it.
- Connect persistent throughput and RAM fixture items to live adapters.

#### Explicitly out of scope
- Do not implement full sensor/GPU backends or a process manager.
- Do not allow hidden popovers to maintain high-frequency polling.

#### Required tests and evidence
- Counter wrap/reset, interface change, Wi-Fi+Ethernet aggregation, zero traffic, very large values, missing proc/sysfs data, and poll-rate changes.
- Layout tests for 0K through large units.

#### CI evolution

Add deterministic sampler/formatter tests and a report-only polling/performance check.

#### Merge cutoff

**Persistent metrics are stable, bounded, and non-blocking; hidden detail consumers reduce or stop elevated polling.**

#### Ready-to-use implementation-agent prompt

```text
Implement bounded throughput and resource-summary adapters with interface aggregation, smoothing, compact formatting, missing-data handling, and consumer-driven poll rates. Connect the persistent bar metrics, add deterministic counter/reset and layout tests, and defer detailed sensors and process management.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-016 — Implement the Network adapter and control-centre model for connectivity, scans, saved networks, and connection tasks.

- **Milestone:** Real desktop state
- **Branch:** `feat/network-adapter`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Resolve and document the approved backend path before implementation.
- Expose connectivity, Wi-Fi power, Ethernet, active connection, scans, visible/saved networks, and task state.
- Represent unavailable, disabled, scanning, connecting, limited, captive, connected, and failed distinctly.
- Handle credentials without persisting or logging secrets.
- Connect quick control and placeholder Network page models.

#### Explicitly out of scope
- Do not implement advanced enterprise certificates, custom routing, or DNS administration.
- Do not run `nmcli` directly from delegates.

#### Required tests and evidence
- Backend absent/late, Wi-Fi disabled, scan failure, open/secured connection, cancellation, secret redaction, limited/captive states, and reconnect.
- Task state must not survive reload in an unsafe form.

#### CI evolution

Add network contract fixtures; real NetworkManager smoke remains nightly/self-hosted when available.

#### Merge cutoff

**Network state/actions are normalized, secrets remain private, progress/errors are explicit, and backend failure does not prevent opening the drawer.**

#### Ready-to-use implementation-agent prompt

```text
Research and implement the approved Network backend behind a normalized adapter. Cover connectivity, scans, saved/visible networks, task progress, cancellation, limited/captive states, reconnect, and strict secret redaction. Connect existing quick-control/page models without delegate-owned commands or advanced network administration.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-017 — Implement the Bluetooth adapter and control-centre model including pairing task states and graceful absence.

- **Milestone:** Real desktop state
- **Branch:** `feat/bluetooth-adapter`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose adapter availability/power, scanning, paired/connected/nearby devices, type, and battery where available.
- Represent pairing codes, confirmations, progress, cancellation, and failure explicitly.
- Connect the quick control and Bluetooth page model.
- Coordinate audio-device output switching through the audio adapter rather than duplicating audio state.
- Handle adapter/service disappearance and reconnect.

#### Explicitly out of scope
- Do not infer audio state independently or store pairing secrets.
- Do not make Bluetooth absence break control-centre startup.

#### Required tests and evidence
- No adapter, powered off, discovery failure, pairing confirm/reject/cancel, reconnect, device disappearance, and non-audio contextual state.
- Reload cannot repeat a pairing confirmation or unsafe task.

#### CI evolution

Add Bluetooth contract fixtures; real BlueZ tests may run on controlled nightly infrastructure later.

#### Merge cutoff

**Bluetooth can be absent or restart safely, pairing state is explicit, and device/audio ownership boundaries remain clean.**

#### Ready-to-use implementation-agent prompt

```text
Implement the normalized Bluetooth adapter and page model with explicit availability, power, discovery, device, pairing, confirmation, cancellation, failure, and reconnect states. Coordinate audio devices through AudioService, prevent secret/task restoration, and ensure no-adapter systems remain fully usable.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-018 — Implement the tray adapter, collapsed affordance, drawer model, menus, activation, secondary activation, and scroll.

- **Milestone:** Real desktop state
- **Branch:** `feat/tray-adapter`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose normalized tray items, status, category, icon, title, tooltip, and supported actions.
- Use the project/Quickshell menu facility rather than reconstructing menus from strings.
- Hide the affordance when empty and keep large populations collapsed.
- Integrate with the PopoverHost and focus/dismissal rules.
- Handle item registration/removal and malformed item data.

#### Explicitly out of scope
- Do not pin tray applications by default.
- Do not let tray ownership conflict with the still-running production shell during non-owning development mode.

#### Required tests and evidence
- Empty, one item, attention item, large population, malformed icon/menu, item disappearance while open, activation, secondary activation, and scroll.
- Reload does not duplicate watcher/ownership.

#### CI evolution

Add tray fixture/component tests; real D-Bus menu smoke waits for an isolated session runner.

#### Merge cutoff

**Tray interactions work through one adapter, empty/large states are correct, and development mode avoids duplicate global ownership.**

#### Ready-to-use implementation-agent prompt

```text
Implement the authoritative tray adapter, collapsed affordance, and drawer integration with proper menu delegation, activation, secondary activation, scroll, empty/large-state behavior, malformed-item handling, and reload safety. Preserve non-owning development mode and do not introduce default pinning.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-019 — Implement normalized notification service ownership, in-memory history, and the pure policy engine for DND/fullscreen/grouping.

- **Milestone:** Notification-complete prototype
- **Branch:** `feat/notification-core-policy`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement notification model, app identity, title/body/actions, urgency, progress, replacement, close, and history.
- Implement routine/important/critical policy, DND, fullscreen suppression, timeout, grouping, and burst coalescing as pure logic.
- Guard notification-server ownership and preserve non-owning development mode.
- Redact all content from diagnostics and CI artifacts.
- Define the boundary between notifications, system toasts, and OSDs.

#### Explicitly out of scope
- Do not implement popup/drawer visuals or persistent database history.
- Do not allow permissive critical bypass based on untrusted text alone.

#### Required tests and evidence
- Replacement, progress, malformed action, grouping, burst, DND matrix, fullscreen matrix, conservative critical bypass, history retention, and redaction.
- Duplicate ownership and reload behavior.

#### CI evolution

Add notification policy/model suite and artifact redaction checks.

#### Merge cutoff

**Notification state and policy are deterministic and content-private; DND/fullscreen decisions can be tested without UI or live D-Bus.**

#### Ready-to-use implementation-agent prompt

```text
Implement notification core and policy as deterministic, content-private services. Add normalized models/history, replacement/progress/actions, DND/fullscreen/grouping/burst logic, conservative critical bypass, ownership guards, and redaction tests. Keep popup, drawer, toast, OSD, and persistent database UI out of scope.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-020 — Implement notification popup stack and grouped drawer history with focus-safe interaction.

- **Milestone:** Notification-complete prototype
- **Branch:** `feat/notification-surfaces`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Create right-side popup host with maximum visible count, timeout pause, actions, dismissal, and grouped updates.
- Create control-centre history grouped by application with expand/collapse, individual/group dismissal, clear all, progress, and stable scrolling.
- Prevent duplicate popup presentation while the relevant history surface is open.
- Use injected notification models and SurfaceCoordinator rules.
- Add deterministic fixture screenshots for representative states.

#### Explicitly out of scope
- Do not add sounds, toasts, OSDs, unread counts, or persistence.
- Do not log rendered notification content in failure output.

#### Required tests and evidence
- Popup timeout pause, action/dismissal, maximum stack, group replacement, scroll stability, clear all, long content, malformed icon, keyboard traversal, and no-duplicate rule.
- Screenshots must use synthetic non-sensitive fixtures.

#### CI evolution

Add required notification component tests; visual diffs begin as review artifacts rather than strict pixel gates.

#### Merge cutoff

**Ordinary application notifications render and remain manageable under bursts, no unread count exists, and opening history prevents duplicate interruption.**

#### Ready-to-use implementation-agent prompt

```text
Build the notification popup stack and grouped control-centre history using the existing notification service/policy. Cover timeout pause, actions, dismissal, burst limits, group updates, stable scrolling, clear-all, keyboard navigation, and no-duplicate presentation. Use synthetic fixtures and never leak content into logs or artifacts.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-021 — Implement keyed system toasts, volume/brightness OSDs, and the initial notification sound policy.

- **Milestone:** Notification-complete prototype
- **Branch:** `feat/toasts-osds`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement keyed replacement toasts for network, Bluetooth, Night Light, idle inhibitor, audio output, power, and generic success/failure.
- Implement in-place volume and brightness OSDs with timeout and fullscreen visibility.
- Ensure DND suppresses ordinary notification popups/sounds but not OSDs or user-triggered configuration toasts.
- Implement only reliable call/alarm/timer/critical sound categories.
- Keep service-to-surface communication event-based.

#### Explicitly out of scope
- Do not create popups for media track changes.
- Do not add a per-application sound editor.

#### Required tests and evidence
- Key replacement, timeout, rapid updates, DND matrix, fullscreen behavior, unavailable brightness, volume mute, and track-change non-events.
- OSD/toast surfaces do not compete with major surfaces.

#### CI evolution

Add toast/OSD policy and component suites; shell smoke covers DND/fullscreen scenarios.

#### Merge cutoff

**Milestone D is met: notifications, DND, history, toasts, and OSDs are behaviorally distinct and pass the documented policy matrix.**

#### Ready-to-use implementation-agent prompt

```text
Implement keyed system toasts, in-place volume/brightness OSDs, and the conservative initial sound policy. Preserve the distinction from application notifications, enforce DND/fullscreen rules, suppress track-change feedback, and add rapid-update and policy-matrix tests.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-022 — Compose the real persistent bar from live adapters and complete its practical interactions and contextual-status policy.

- **Milestone:** Daily-use prototype
- **Branch:** `feat/daily-use-bar`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Replace remaining bar fixtures with live workspace, tray, throughput, audio, resources, battery, date/time, Vicinae availability, and contextual states.
- Complete the real special-workspace selector and stable contextual-status region.
- Implement compact audio/resource/calendar/tray entry behavior without duplicating deeper pages.
- Add optional autohide only if its open questions have been resolved through a focused prototype.
- Document fallback behavior for every optional integration.

#### Explicitly out of scope
- Do not add weather, application icons, permanent window titles, or a full process manager.
- Do not expose arbitrary layout micro-settings.

#### Required tests and evidence
- Full bar component matrix with each adapter available/unavailable/busy/failed.
- Keyboard and pointer paths for each actionable item.
- Long-running smoke with rapid workspace/audio/metric changes and no layout jitter.
- Manual normal-session replacement test on the primary machine.

#### CI evolution

Add composed-bar smoke and a report-only idle CPU/memory/polling baseline.

#### Merge cutoff

**The persistent bar can replace the current shell bar for a normal session without a blocker; optional failures remain local and visible.**

#### Ready-to-use implementation-agent prompt

```text
Compose the daily-use Franken Shell bar from the normalized live adapters. Complete workspace/special navigation, contextual statuses, tray, throughput, audio, resources, battery, date/time, and Vicinae entry behavior with full unavailable/failure coverage and stable layout. Preserve explicit non-goals and record performance baselines.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-023 — Replace control-centre placeholders with practical audio, brightness, network, Bluetooth, notification, and quick-control workflows.

- **Milestone:** Daily-use prototype
- **Branch:** `feat/daily-use-control-centre`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Connect quick controls, master volume, brightness, Notifications, Mixer, Network, and Bluetooth to authoritative adapters.
- Implement the agreed main-view scrolling/sticky policy and safe state restoration.
- Ensure async tasks show pending, cancellation, success, and failure.
- Add settings/session entry placeholders that route through stable contracts.
- Keep one source of truth for audio and notification models.

#### Explicitly out of scope
- Do not implement advanced enterprise networking, full settings UI, or final session surface.
- Do not restore credentials, confirmations, or unsafe in-flight tasks.

#### Required tests and evidence
- Each backend absent/disabled/busy/failed independently.
- Keyboard/pointer parity, nested Escape behavior, task cancellation, close/reopen restoration, and service reconnect while open.
- Manual edge-drag use with long lists and concurrent tasks.

#### CI evolution

Add composed control-centre integration tests using fixtures; retain real service acceptance as documented manual/self-hosted evidence.

#### Merge cutoff

**The control centre handles ordinary daily audio/device/connectivity/notification tasks and remains usable when any one backend fails.**

#### Ready-to-use implementation-agent prompt

```text
Turn the fixture control centre into a practical daily-use surface by connecting normalized audio, brightness, notifications, network, Bluetooth, and quick controls. Implement safe restoration and complete async task states, preserve navigation/focus behavior, and prove each backend can fail independently without closing the drawer.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-024 — Stabilize the prototype through sustained use, eliminate blocker defects, and establish performance/reliability baselines.

- **Milestone:** Daily-use prototype
- **Branch:** `perf/daily-use-stabilization`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Run a documented sustained daily-use period and record defects by severity.
- Fix only blocker/high-severity reliability, lifecycle, focus, polling, and memory issues found in the validation period.
- Measure startup readiness, idle CPU/memory/wakeups, reload, popover/drawer latency, and child-process count.
- Add regression tests for every defect fixed.
- Document the controlled cutover/rollback procedure from the current shell.

#### Explicitly out of scope
- Do not add new product features or visual redesign.
- Do not create hard performance gates before stable baselines exist; report first, then gate catastrophic regressions.

#### Required tests and evidence
- Repeated reload/open-close/service-restart loops.
- Long fixture event bursts and task cancellation.
- Performance report comparison against baseline.
- Manual one-full-day acceptance with rollback available.

#### CI evolution

Add nightly endurance and report-only performance jobs; gate only leaks, crashes, deadlocks, or extreme regressions.

#### Merge cutoff

**Milestone E is met: no blocker-level daily-use defect remains, every fixed bug has a regression test, and baseline performance/reliability data is recorded.**

#### Ready-to-use implementation-agent prompt

```text
Stabilize the daily-use prototype rather than adding features. Conduct sustained use, fix blocker/high lifecycle, focus, polling, memory, and process issues, add a regression test for each fix, record startup/idle/interaction baselines, and document cutover/rollback. Keep performance thresholds conservative until repeatable.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-025 — Research, pin, and document the quickshell-overview compatibility and invocation contract before code integration.

- **Milestone:** Integrated ecosystem
- **Branch:** `chore/overview-contract-pin`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Verify repository, licence/attribution, revision, Quickshell/Hyprland compatibility, IPC, lifecycle, config format, theme mechanism, multi-monitor, and screencopy requirements.
- Record a known-working revision and compatibility note.
- Resolve or explicitly retain relevant open questions.
- Add a small executable compatibility probe where practical.
- Define direct-workspace fallback and duplicate-process policy.

#### Explicitly out of scope
- Do not vendor, fork, or implement speculative IPC strings.
- Do not modify the main shell beyond a non-functional probe boundary.

#### Required tests and evidence
- Probe succeeds against the pinned version and fails clearly for absent/incompatible versions.
- Documentation review confirms ownership and fallback boundaries.

#### CI evolution

Add non-blocking nightly compatibility probe against the pinned external component where infrastructure permits.

#### Merge cutoff

**The integration contract is evidence-based and pinned; the next PR can implement without guessing upstream behavior.**

#### Ready-to-use implementation-agent prompt

```text
Research and pin quickshell-overview before integration. Verify its licence, revision, Quickshell/Hyprland compatibility, IPC, lifecycle, configuration, theming, multi-monitor, and screencopy behavior; document the contract, fallback, and compatibility probe. Do not vendor or implement speculative commands.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-026 — Implement OverviewAdapter, invocation/fallback, shared workspace configuration, theme sync, and diagnostics.

- **Milestone:** Integrated ecosystem
- **Branch:** `feat/overview-adapter-sync`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement fixture and real OverviewAdapter with availability, compatibility, duplicate-request guard, structured errors, and invocation.
- Coordinate shell surfaces before opening and preserve direct workspace fallback.
- Generate or synchronize workspace definitions through the approved one-way mechanism.
- Map supported theme roles atomically with last-valid fallback.
- Expose version and sync health in diagnostics.

#### Explicitly out of scope
- Do not vendor the overview or make it a second workspace owner.
- Do not require exact visual parity through a fragile fork.

#### Required tests and evidence
- Absent/incompatible/busy/failure/restart/duplicate-request cases.
- Generated configuration is deterministic and atomic.
- Bar and overview derive identical special-workspace definitions.
- Manual invocation, focus, screencopy, and failure fallback.

#### CI evolution

Add adapter/config-generation tests; nightly/self-hosted integration smoke against the pinned version.

#### Merge cutoff

**The overview behaves as an optional first-class integration, uses shared config/theme, and cannot break direct navigation when it fails.**

#### Ready-to-use implementation-agent prompt

```text
Implement the pinned quickshell-overview integration through OverviewAdapter. Add guarded invocation, surface coordination, direct-navigation fallback, deterministic shared workspace configuration, atomic theme sync, diagnostics, and failure/restart tests. Preserve external-process ownership and do not vendor upstream.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-027 — Implement Vicinae availability, command mapping, first-party shell extension contract, and shared theme generation.

- **Milestone:** Integrated ecosystem
- **Branch:** `feat/vicinae-integration`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement VicinaeAdapter for root search and configured direct entries.
- Define and version the first-party extension-to-shell IPC commands.
- Generate supported theme configuration atomically.
- Expose availability/version/failure diagnostics and preserve shell operation when absent.
- Connect the bar entry and secondary shortcut menu.

#### Explicitly out of scope
- Do not implement a competing application launcher or search UI.
- Do not let the extension edit shell files directly or expose arbitrary shell execution.

#### Required tests and evidence
- Absent/incompatible/invocation failure, malformed extension request, unsupported IPC version, theme-write failure, and repeated toggle.
- All extension commands enforce the same capability and safety checks as UI actions.

#### CI evolution

Add adapter/IPC/theme-generation tests; nightly probe against a pinned Vicinae version if automatable.

#### Merge cutoff

**Milestone F is met: Vicinae and overview are optional but coherent shell integrations with versioned contracts, diagnostics, and fallbacks.**

#### Ready-to-use implementation-agent prompt

```text
Implement Vicinae as Franken Shell’s external command/search layer. Add adapter availability and launch methods, a versioned first-party extension IPC contract, atomic theme generation, bar entry behavior, diagnostics, and absent/failure tests. Never build a competing launcher or expose general command execution.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-028 — Implement detailed resource and sensor services with generic interfaces and capability-driven omission.

- **Milestone:** Deeper utilities
- **Branch:** `feat/resource-sensors`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Add normalized sensor channels and generic resource detail models.
- Implement only the backends needed for the initial machine while retaining generic AMD/NVIDIA/null boundaries.
- Increase sampling while the popover is open and reduce it when hidden.
- Build the compact resource popover and external system-monitor launch action.
- Omit unsupported metrics without dead placeholders.

#### Explicitly out of scope
- Do not build a process manager or hard-code one laptop’s hwmon paths in UI.
- Do not make vendor-specific data mandatory for shell startup.

#### Required tests and evidence
- Missing sensors, malformed sysfs, multiple GPUs, unsupported vendor, command timeout, hidden/open polling, and external monitor launch failure.
- Performance test confirms bounded sampling.

#### CI evolution

Add deterministic sensor fixtures and report-only sampling benchmarks; real hardware coverage later.

#### Merge cutoff

**Detailed metrics are capability-driven and bounded; unsupported hardware degrades cleanly; the full monitor remains external.**

#### Ready-to-use implementation-agent prompt

```text
Implement the detailed resource/sensor layer with normalized channels, generic vendor boundaries, capability-driven omission, open/hidden polling rates, compact popover, and external monitor action. Cover missing/malformed/multi-GPU cases and keep hardware-specific paths out of view code.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-029 — Implement the narrowly scoped auto-cpufreq privileged helper, validation, atomic writes, backups, and Polkit boundary.

- **Milestone:** Deeper utilities
- **Branch:** `feat/auto-cpufreq-helper`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Finalize the helper language and explicit operation contract.
- Parse and validate only approved fields and paths.
- Use atomic writes, backups, restore, structured errors, and Polkit authorization.
- Reject arbitrary files, commands, unsupported fields, and unsafe values.
- Package helper tests independently from QML.

#### Explicitly out of scope
- Do not build the power panel in this PR.
- Do not expose a generic privileged executor or destroy unknown configuration silently.

#### Required tests and evidence
- Unit/property tests for valid/invalid values, path traversal, arbitrary command attempts, interrupted writes, backup/restore, idempotency, and authorization denial.
- Static analysis, dependency audit, and temporary-root integration tests.

#### CI evolution

Add strict language-native format/lint/test/audit jobs and privileged-helper security tests; no live root access in untrusted PR CI.

#### Merge cutoff

**The helper passes an explicit security review checklist, cannot escape its narrow contract, and recovers safely from failed writes.**

#### Ready-to-use implementation-agent prompt

```text
Implement the auto-cpufreq privileged helper as a narrowly scoped, separately testable security boundary. Support only explicit read/validate/write/apply/restore operations, approved paths and fields, atomic writes, backups, structured errors, and Polkit. Add traversal, arbitrary-command, interruption, authorization, and rollback tests; no panel UI yet.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-030 — Implement the power and auto-cpufreq panel over the approved helper with apply/revert and truthful capability states.

- **Milestone:** Deeper utilities
- **Branch:** `feat/power-panel`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose detected installation/daemon/config source, inherited versus overridden values, supported fields, and current profile.
- Build validation-aware edit, save, apply, revert, and failure flows.
- Keep battery status functional when auto-cpufreq is absent.
- Represent automatic mode versus temporary override distinctly.
- Use the helper contract exclusively for protected operations.

#### Explicitly out of scope
- Do not duplicate or silently create conflicting configuration.
- Do not expose unsupported fields or privileged filesystem access to QML.

#### Required tests and evidence
- Helper absent, daemon stopped, unsupported field, validation failure, authorization denial, apply failure, revert, stale config, and reload during an edit.
- Manual safe test on the primary machine with a backup.

#### CI evolution

Add panel/controller fixtures and helper-client integration tests; live apply remains manual/self-hosted and protected.

#### Merge cutoff

**Power management is useful without weakening the privilege boundary; failed or absent auto-cpufreq never harms battery display or configuration.**

#### Ready-to-use implementation-agent prompt

```text
Build the power/auto-cpufreq panel strictly over the approved helper. Show configuration source, supported values, automatic versus override state, validation, save/apply/revert, authorization and failure paths, while preserving battery-only fallback. Test absence, denial, stale config, apply failure, and reload safety.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-031 — Implement the local calendar panel and a provider-neutral calendar contract without network accounts.

- **Milestone:** Deeper utilities
- **Branch:** `feat/calendar-provider-local`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement locale-aware month data, selected date, month navigation, Today action, and keyboard/pointer interaction.
- Define a provider-neutral event/query interface for future integrations without coupling UI to Google response objects.
- Keep the prototype free of empty permanent agenda chrome.
- Integrate with the date/time bar popover and theme/focus systems.
- Handle time zone and locale changes predictably.

#### Explicitly out of scope
- Do not implement OAuth, token storage, or Google network calls.
- Do not duplicate a full calendar inside the control centre.

#### Required tests and evidence
- Month boundaries, leap year, locale, time zone change, keyboard grid navigation, Today, text scale, and no-provider state.
- Provider contract tests use fixtures only.

#### CI evolution

Add deterministic calendar logic/component suite with fixed clock and locale fixtures.

#### Merge cutoff

**The local calendar is complete and accessible, and a clean provider boundary exists for optional future account integration.**

#### Ready-to-use implementation-agent prompt

```text
Implement the local calendar panel and a provider-neutral calendar interface. Cover month math, locale/time-zone changes, Today, selected-day state, keyboard/pointer navigation, and no-provider behavior. Integrate with the date/time popover, but keep Google OAuth, tokens, and network calls out of scope.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-032 — Add Google Calendar through the provider contract with secure authentication and storage; it is not a blocker for the first stable shell.

- **Milestone:** Optional near-term integration
- **Branch:** `feat/google-calendar-integration`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Research and document the approved desktop OAuth flow and secure token-storage mechanism.
- Implement account lifecycle, refresh, revocation, sync state, range queries, and mapped event models behind the provider interface.
- Keep account failures local and preserve the local calendar.
- Avoid logging tokens, event content, or account identifiers unnecessarily.
- Document offline/error behavior and an explicit disable path.

#### Explicitly out of scope
- Do not store credentials in TOML/plain files or couple UI to provider payloads.
- Do not make this PR a release blocker unless the project owner promotes it.

#### Required tests and evidence
- Mock OAuth success/cancel/failure, expired refresh, revoked token, secure-store unavailable, offline sync, pagination, time zones, all-day events, and redaction.
- No live credentials in CI.

#### CI evolution

Add provider mock tests and secret scans; live-account tests remain manual and use disposable test credentials outside PR CI.

#### Merge cutoff

**Google integration can be enabled or absent independently, secrets are securely handled, and the local calendar remains fully functional on failure.**

#### Ready-to-use implementation-agent prompt

```text
Implement optional Google Calendar only through the established provider interface. First settle OAuth and secure token storage, then add account lifecycle, sync, mapping, offline/failure behavior, and strict redaction using mocks. Preserve the local calendar and do not make account integration mandatory for release.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-033 — Implement focused-window actions and session/power actions with explicit destructive confirmation and stable targeting.

- **Milestone:** Deeper utilities
- **Branch:** `feat/window-session-actions`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Build a summonable focused-window action surface using normalized Hyprland state and authoritative workspace definitions.
- Support move, floating, fullscreen, graceful close, and separately confirmed force-kill.
- Snapshot the target so focus changes cannot silently retarget a destructive action.
- Implement session actions through explicit safe contracts.
- Integrate keyboard and one settled pointer/Vicinae entry path.

#### Explicitly out of scope
- Do not add a permanent active-window title to the bar.
- Do not expose raw compositor/session commands from delegates.

#### Required tests and evidence
- Target disappears, focus changes, command failure, move target invalid, graceful close versus force-kill, confirmation cancel/timeout, and Escape unwinding.
- Session actions require explicit confirmation where destructive.

#### CI evolution

Add controller/confirmation contract tests; live compositor/session commands require controlled manual/self-hosted validation.

#### Merge cutoff

**Window/session actions are keyboard-accessible, safely targeted, and cannot accidentally escalate from graceful to destructive behavior.**

#### Ready-to-use implementation-agent prompt

```text
Implement focused-window and session actions through normalized adapters. Snapshot targets, distinguish graceful close from confirmed force-kill, use authoritative workspace targets, add safe session confirmations, and test focus changes, disappearing targets, failures, cancellation, and Escape. Keep raw commands out of UI.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-034 — Implement the settings/configuration UI, schema-aware validation, diagnostics surface, and user-safe save/apply behavior.

- **Milestone:** Feature-complete beta
- **Branch:** `feat/settings-config-ui`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Expose only meaningful settings settled by product docs: bar edge/autohide policy, workspace groups/special definitions, throughput convention, monitor enablement, text scale, reduced motion, and supported integrations.
- Edit the same authoritative TOML schema used by ConfigService.
- Show validation errors, last-valid state, restart/recreate requirements, diagnostics, and repair actions.
- Use atomic saves and preserve comments/unknown fields according to the accepted config strategy.
- Add schema migration hooks without requiring final packaging.

#### Explicitly out of scope
- Do not expose arbitrary per-item padding, unrestricted reorder, raw animation curves, or a second configuration store.
- Do not silently discard unknown data.

#### Required tests and evidence
- Round-trip, invalid input, concurrent external edit, save failure, migration fixture, restart-required marker, cancel, and recovery to last valid.
- Settings changes update the same models consumed by shell features.

#### CI evolution

Add config round-trip/migration suites and settings component tests; generated-schema freshness becomes required.

#### Merge cutoff

**Settings safely manage the authoritative configuration, failures are recoverable, and diagnostics make broken configuration actionable.**

#### Ready-to-use implementation-agent prompt

```text
Implement a schema-aware settings and diagnostics surface over the authoritative TOML ConfigService. Expose only meaningful settled options, add validation, atomic save, external-edit conflict handling, restart/recreate indicators, migrations, repair actions, and round-trip tests. Never create a second config store or discard unknown data silently.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-035 — Finalize per-monitor ownership, hotplug, mixed scaling, rotation, and recovery across bars, popovers, drawer, overview, and notifications.

- **Milestone:** Feature-complete beta
- **Branch:** `feat/multi-monitor-hardening`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Settle and document bar/control-centre/notification/overview monitor ownership policies.
- Implement per-monitor surface instances where required and global uniqueness where required.
- Handle add/remove, focused-monitor changes, owner removal, mixed scale, fractional scale, and rotation.
- Restore or close focus safely when a monitor disappears.
- Validate hybrid GPU and screencopy failure boundaries where relevant.

#### Explicitly out of scope
- Do not add gestures or visual redesign.
- Do not hide unsupported topology with hard-coded primary-monitor assumptions.

#### Required tests and evidence
- Topology fixtures: one/two/three monitors, right neighbor blocking edge, hotplug while surfaces open, owner removal, mixed scales, rotation, fractional pixel alignment, and overview failure.
- Controlled real two-monitor acceptance.

#### CI evolution

Introduce scheduled/self-hosted Hyprland monitor acceptance; fixture topology tests remain required on PRs.

#### Merge cutoff

**All major surfaces follow a documented ownership policy and recover from topology changes without crashes, lost focus, duplicates, or off-screen placement.**

#### Ready-to-use implementation-agent prompt

```text
Harden Franken Shell for real multi-monitor use. Settle and implement ownership policies, per-monitor/global surface rules, hotplug, owner removal, mixed/fractional scaling, rotation, focus recovery, overview/screencopy boundaries, and topology fixtures. Keep gestures and visual polish out of scope.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-036 — Add approved trackpad gestures and establish controlled real-Hyprland/hardware acceptance CI.

- **Milestone:** Feature-complete beta
- **Branch:** `feat/gestures-hardware-acceptance`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Research the supported Hyprland/Quickshell gesture path and record an ADR.
- Implement only gestures with reliable progress/cancellation and no conflict with workspace navigation.
- Provide settings/capability fallbacks when unsupported.
- Set up a controlled self-hosted runner or documented local acceptance harness for compositor, focus, layer-shell, GPU, and monitor behavior.
- Collect logs, screenshots, process state, and versions on failure.

#### Explicitly out of scope
- Do not make hardware CI a broad distro farm.
- Do not emulate continuous gestures using fragile command polling.

#### Required tests and evidence
- Gesture start/progress/reversal/cancel, conflict detection, unsupported path, monitor ownership, fullscreen policy.
- Self-hosted startup/reload/focus/layer-shell/hotplug smoke against the supported Hyprland baseline.

#### CI evolution

Add non-PR or protected self-hosted `Hardware / Hyprland` workflow on main/nightly/release candidates; never expose secrets to forked PRs.

#### Merge cutoff

**Gestures are optional and reliable where supported, and real compositor/hardware regressions have a reproducible acceptance lane.**

#### Ready-to-use implementation-agent prompt

```text
Research and implement only reliable approved trackpad gestures, with progress, reversal, cancellation, conflict handling, capability fallback, and monitor ownership. Establish protected self-hosted Hyprland/hardware acceptance for startup, reload, focus, layer-shell, hotplug, and diagnostics. Avoid fragile polling and an unnecessary distro farm.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-037 — Apply final visual language, accessibility, reduced motion, text scaling, and controlled visual regression coverage.

- **Milestone:** Polished beta
- **Branch:** `feat/visual-accessibility`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Resolve remaining typography, icon, thickness, geometry, opacity/blur, motion, and state-treatment prototypes.
- Ensure focus differs from selection and active state is not color-only.
- Support reduced motion, high contrast, and the documented text-scale range.
- Normalize adopted integrations without unnecessary forks.
- Promote stable deterministic screenshots to reviewed visual baselines.

#### Explicitly out of scope
- Do not change architecture or add product features to achieve a visual target.
- Do not ship unlicensed font assets.

#### Required tests and evidence
- Theme/wallpaper fixture set, high contrast, reduced motion, text scale, all bar orientations at component level, long localization, pixel alignment, and interaction timing.
- Visual diffs require deliberate baseline review.

#### CI evolution

Add stable visual-regression gates for deterministic components; keep noisy real-GPU screenshots informational.

#### Merge cutoff

**The shell remains readable and usable across representative themes/scales, interaction is never delayed by motion, and visual regressions are reviewable rather than hidden.**

#### Ready-to-use implementation-agent prompt

```text
Complete visual and accessibility hardening without changing architecture. Resolve typography/icons/geometry/motion through prototypes, support reduced motion, high contrast and text scale, separate focus/selection/active semantics, validate representative themes, and establish deliberate deterministic visual baselines. Do not add features or distribute unlicensed fonts.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-038 — Add Arch/Garuda-first installation, systemd user service, Polkit/helper installation, migrations, uninstall, and package validation.

- **Milestone:** Release hardening
- **Branch:** `chore/arch-packaging-systemd`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Implement the primary systemd user-service startup path and documented Hyprland integration without duplicate launches.
- Add Arch package/install definitions, dependency checks, config paths, helper, Polkit policy, and uninstall behavior.
- Implement package-time generated-file and migration handling.
- Test installation into a clean temporary root and from a built package rather than the source tree.
- Preserve user configuration on upgrade/uninstall according to policy.

#### Explicitly out of scope
- Do not claim support for distributions not in the compatibility policy.
- Do not leave the privileged helper or policies after uninstall.

#### Required tests and evidence
- Clean install, first start, upgrade with old config, failed migration, rollback, uninstall, reinstall, missing dependency, duplicate-start guard, and package manifest.
- Installed shell starts without referencing the source checkout.

#### CI evolution

Add blocking package build/install tests on Arch and release-candidate self-hosted validation.

#### Merge cutoff

**A clean Arch/Garuda-class system can install, start, upgrade, diagnose, and uninstall the shell safely while preserving user data.**

#### Ready-to-use implementation-agent prompt

```text
Package Franken Shell for Arch/Garuda first. Add the systemd user-service startup path, Hyprland integration without duplicate launches, dependency checks, config/migration handling, helper and Polkit installation, clean uninstall, and temporary-root package tests. Do not claim unsupported distro coverage.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


### PR-039 — Finalize release CI, compatibility policy, diagnostics bundle, documentation, changelog, signing/checksums, and release checklist.

- **Milestone:** Release hardening
- **Branch:** `chore/release-pipeline-docs`
- **Status:** **open**
- **Merged PR / commit:** _fill when closed_

#### Scope
- Create tag/release workflows that build from a clean checkout and publish verified artifacts.
- Run required pinned, Arch, Fedora/latest, self-hosted Hyprland, package install, migration, and smoke gates according to support policy.
- Generate checksums and provenance/signing metadata supported by the hosting setup.
- Finalize installation, first run, configuration, keybindings, architecture, troubleshooting, contribution, recovery, and release notes.
- Produce one redacted diagnostics command/bundle containing versions, config status, integrations, and service health.

#### Explicitly out of scope
- Do not release from an unclean local tree or bypass failed required gates.
- Do not include secrets, notification bodies, tokens, or private paths unnecessarily in diagnostics.

#### Required tests and evidence
- Dry-run release on a prerelease tag, artifact install, checksum verification, diagnostics redaction, documentation link checks, rollback drill, and final sustained-use checklist.
- All declared compatibility lanes must pass or be explicitly removed from the support policy before release.

#### CI evolution

Promote release-candidate matrix and package/security checks to required release gates; upstream-edge remains informational.

#### Merge cutoff

**A release is reproducible, installable, diagnosable, documented, and gated by the declared compatibility/test matrix; rollback is documented and practiced.**

#### Ready-to-use implementation-agent prompt

```text
Finalize Franken Shell’s release lifecycle. Build releases from clean tags, run the declared pinned/Arch/Fedora/hardware/package gates, generate verified artifacts and checksums/provenance, create a redacted diagnostics bundle, complete user/contributor/recovery docs, and dry-run rollback. Never bypass required gates or leak private data.
Before coding, read the repository AGENTS instructions and the relevant architecture, decisions, open-questions, configuration, implementation, and feature specification documents. Keep this PR narrow, update tests and documentation in the same branch, run all local CI-equivalent commands, push the branch, open/update the PR with `gh`, inspect CI failures, and do not merge until the stated cutoff is met.
```


---

## 7. Pull Request Description Template

Use this structure in every PR:

```markdown
## Outcome

What usable or architectural result does this PR deliver?

## Scope

- ...

## Explicit non-goals

- ...

## Architectural boundaries

- State owner:
- Adapter/service boundary:
- Surface/focus ownership:
- Security/privacy implications:

## Change-to-test mapping

- Applicable roadmap rows:
- Automated tests added/updated:
- Manual/self-hosted evidence:

## CI

- Local commands run:
- Required checks:
- Expected new/changed check:

## Failure and fallback behavior

- Dependency absent:
- Backend disconnect/failure:
- Reload/teardown:

## Documentation

- Decisions updated:
- Open questions updated:
- Feature/config docs updated:
- Roadmap status updated:

## Rollback

How can this PR be reverted or disabled without corrupting state?
```

---

## 8. Review Checklist for the Implementing Agent

Before requesting merge, answer all of the following in the PR:

- Is the implementation smaller than the original phase and independently reviewable?
- Does the repository still start in fixture/non-owning mode?
- Did this PR introduce direct system access outside an adapter?
- Did it create a second source of truth?
- Does every optional dependency have an unavailable/failure state?
- Are keyboard, pointer, focus, and dismissal paths covered where applicable?
- Are reload, teardown, reconnection, and duplicate-owner paths covered?
- Did any log or artifact gain private content?
- Did a new language or tool enter without format/lint/test CI?
- Can the PR be reverted without migrating or corrupting user data?
- Are manual limitations recorded rather than presented as automated coverage?
- Has the roadmap status and merged PR reference been updated?

---

## 9. Relationship to the Original Phase Plan

The original phases remain useful as milestones and risk ordering:

- **Phases 0–1:** B-000 through PR-005;
- **Phase 2:** PR-006 through PR-008;
- **Phase 3:** PR-009 through PR-011;
- **Phase 4:** PR-012 through PR-018;
- **Phase 5:** PR-019 through PR-021;
- **Phase 6:** PR-022 through PR-024;
- **Phase 7:** PR-025 through PR-027;
- **Phase 8:** PR-028 through PR-033, with PR-032 explicitly optional for first stable release;
- **Phase 9:** PR-034;
- **Phase 10:** PR-035 through PR-036;
- **Phase 11:** PR-037;
- **Phase 12:** PR-038 through PR-039.

The important change is that phases are no longer implementation units. **Pull requests are the implementation units; phases are only milestone groupings.**

---

## 10. Immediate Next Actions

1. Complete B-000 and record the remote URL, baseline SHA, and tag.
2. Create `chore/engineering-foundation` and change PR-001 to `in-progress`.
3. Merge PR-001 before creating feature branches so all later work is protected by real CI.
4. Complete PR-002 to establish truthful coverage of the code that already exists.
5. Continue sequentially unless a documented dependency/risk review justifies reordering.
