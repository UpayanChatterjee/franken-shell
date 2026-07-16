# Active shell instructions

This directory contains the active, runnable Quickshell configuration.

It began as a customized Caelestia Shell configuration. It is now maintained
independently, while deliberately retaining selected Caelestia services,
native QML modules, CLI functionality and runtime dependencies.

# Active Franken Shell implementation instructions

## Scope

This directory contains the active, runnable Franken Shell Quickshell configuration.

The repository-level `../AGENTS.md` also applies. This file adds implementation-specific rules for files under `shell/`.

Franken Shell began as a heavily customized Caelestia configuration and is now maintained independently while deliberately retaining selected Caelestia services, QML modules, CLI functionality, helpers, and runtime dependencies.

The goal is not to remove every trace of Caelestia. The goal is to build one cohesive shell with its own architecture, visual language, interaction model, configuration, and failure behaviour.

## Required project guidance

Before substantial implementation work, read:

* `../docs/decisions.md`;
* the relevant file under `../docs/features/`;
* applicable sections of:

  * `../docs/architecture.md`;
  * `../docs/configuration-model.md`;
  * `../docs/interaction-language.md`;
  * `../docs/visual-language.md`;
  * `../docs/implementation-phases.md`;
* relevant unresolved items in `../docs/open-questions.md`.

Accepted decisions must not be contradicted.

Treat applicable open questions as unresolved. Do not select an implementation merely because it is easiest.

Recommendations, candidate values, prototype ranges, and suggested baselines are not settled requirements unless an accepted decision or feature specification says otherwise.

When implementation reveals a genuine conflict or missing product decision:

1. preserve existing accepted behaviour where safe;
2. avoid implementing the disputed portion by convenience;
3. report the conflict;
4. update design documents only when the task explicitly includes resolving it.

Do not rewrite a feature specification merely because implementation has begun. Update it only when its contract is absent, materially incomplete, or changed by an approved decision.

## Source structure

Follow the existing implementation tree and the target architecture in `../docs/architecture.md`.

Do not introduce a competing directory taxonomy.

The intended responsibility groups include:

* `core/` for shell-wide coordination, registries, diagnostics, and shared state;
* `theme/` for semantic visual and motion tokens;
* `services/` for normalized system-service adapters;
* `surfaces/` for top-level window and surface hosts;
* `features/` for feature controllers and feature-specific views;
* `components/` for reusable visual and interaction primitives;
* `ipc/` for versioned shell IPC;
* `helpers/` for narrowly scoped functionality that cannot safely remain in QML.

Legacy structure may remain while features are migrated.

Do not reorganize the entire shell merely to match the target tree. Migrate incrementally when a task gives a component a clear new owner.

Before creating a new top-level directory, confirm that the responsibility is not already represented.

## Architectural invariants

### Main process

Franken Shell should normally use one principal Quickshell instance for:

* bars;
* control centres;
* popovers;
* notification presentation;
* toasts;
* OSDs;
* shared services;
* configuration;
* diagnostics;
* shell IPC.

Do not create an independent Quickshell process for an ordinary feature merely to simplify local state.

Adopted external components such as Vicinae and quickshell-overview may remain separate according to their specifications.

### Presentation and controllers

QML views should:

* render normalized state;
* manage local presentation and interaction state;
* request actions through controllers;
* use shared components and theme tokens.

Views must not:

* invoke `hyprctl`, `nmcli`, `bluetoothctl`, `wpctl`, or equivalent backend commands directly;
* parse service-specific output;
* edit configuration files;
* perform privileged writes;
* instantiate duplicate global services;
* decide shell-wide surface ownership.

Feature controllers may:

* combine normalized service state;
* expose presentation-ready models;
* enforce documented feature policy;
* map failures into user-facing state;
* request toasts and OSD updates.

Controllers must not own top-level window geometry or bypass the central surface coordinator.

### Shared ownership

Use the established central owners:

* `ConfigService` for loading, validation, normalization, migration, and atomic configuration application;
* `ThemeManager` for semantic visual roles;
* `MonitorRegistry` for normalized monitor identity, geometry, scale, transform, focus, and hotplug;
* `SurfaceCoordinator` for transient visibility, monitor ownership, dismissal, and focus restoration;
* `CommandRegistry` for structured external command invocation;
* `CapabilityRegistry` for feature availability;
* diagnostics registry for structured service health and failures.

Do not create parallel authoritative state for concepts already owned by these services.

### Services and external commands

Prefer suitable Quickshell-native APIs behind Franken Shell adapters.

External processes must:

* use structured executable and argument lists rather than shell-string concatenation;
* run asynchronously;
* expose exit status and structured errors;
* avoid blocking the QML UI thread;
* avoid logging secrets or notification contents;
* be rate-limited where repeated invocation is required.

Privileged operations must use a narrowly scoped helper and approved authorization mechanism. Never expose an arbitrary privileged command or arbitrary writable path.

## Caelestia dependencies

Selected Caelestia dependencies are intentional.

Do not replace or remove a Caelestia service, plugin, CLI integration, helper, or utility merely to make the project appear more independent.

Before changing a Caelestia integration, identify:

1. the features and services that consume it;
2. the package or repository component that supplies it;
3. runtime and configuration dependencies;
4. IPC or compatibility expectations;
5. behaviour that would be lost;
6. whether the requested feature actually requires replacement.

A dependency should be replaced only when justified by an accepted decision or a concrete implementation need, such as:

* it blocks a documented requirement;
* it repeatedly causes compatibility failures;
* its behaviour requires substantial divergence;
* it is no longer used;
* a simpler and demonstrably better supported implementation satisfies the same contract.

Record approved significant dependency changes in `../docs/decisions.md` and update `../docs/runtime-dependencies.md`.

## Reference-source policy

Reference repositories are under:

* `../references/repos/caelestia/`;
* `../references/repos/illogical-impulse/`;
* `../references/repos/activspot/`.

They are read-only.

Never:

* modify or commit inside them;
* make the active shell import files from them at runtime;
* merge a reference directory wholesale;
* treat reference structure or styling as a Franken Shell requirement.

Before adapting a referenced feature:

1. read the relevant feature specification;
2. inspect `../references/analyses/` and the component inventory;
3. inspect raw upstream source only where needed;
4. describe the desired behaviour and state independently;
5. identify dependencies, IPC, configuration, and architecture assumptions;
6. separate the useful concept from project-specific implementation details;
7. implement through Franken Shell services, controllers, surfaces, and theme tokens.

When copying or substantially adapting code or assets:

* verify that the licence permits it;
* preserve required copyright and licence notices;
* record the upstream repository, path, and revision;
* keep copied material limited to the justified component.

## QML implementation rules

Prefer declarative QML and stable bindings.

Use:

* typed properties;
* `required` properties where ownership requires them;
* explicit models and controller interfaces;
* reusable components;
* `Loader` or `LazyLoader` for expensive conditional content;
* `ListView` for scrolling or potentially large models;
* `Repeater` only for small bounded collections;
* `Qt.resolvedUrl()` for relative resources;
* scoped, interruptible state transitions;
* accessible names and visible keyboard focus.

Avoid:

* replacing bindings with imperative assignments without necessity;
* binding loops;
* duplicated derived properties;
* deeply nested anonymous components;
* components with unrelated responsibilities;
* direct backend access from feature views;
* duplicated service instances;
* deprecated imports;
* hard-coded monitor assumptions;
* fixed geometry that ignores logical scale and available space;
* expensive hidden delegates remaining active;
* high-frequency polling while the consuming surface is closed.

Do not introduce a new service when an existing normalized service can satisfy the requirement.

Unsupported capabilities should normally be omitted or explained through an unavailable state, not represented as permanently dead controls.

## Surface, focus, and input rules

All major workflows must be keyboard-accessible and pointer-complete according to `../docs/interaction-language.md`.

Transient surfaces must open through `SurfaceCoordinator`.

Required behaviour includes:

* deterministic initial keyboard focus;
* visible focus indication;
* no keyboard input leaking to the previous application;
* stack-aware `Escape` behaviour;
* outside-click dismissal only where safe;
* one ordinary bar popover at a time;
* focus restoration after closing;
* no invisible item retaining focus;
* no invisible component remaining interactive.

Do not use hover or a gesture as the only path to an essential action.

True fullscreen is an interruption boundary. Use normalized fullscreen state rather than inferring it from geometry or maximization.

Do not assume a single monitor. Obtain monitor ownership and transformed geometry through the monitor and surface abstractions.

## Visual implementation

Use semantic tokens from the shared theme system for:

* colours;
* typography;
* spacing;
* corner radii;
* outlines;
* shadows and surface effects;
* icon dimensions;
* standard surface dimensions;
* animation durations and easing.

Do not create a parallel visual-token system under a feature.

Avoid hard-coded visual values when the value is shared or semantically reusable. Small local measurements are acceptable when they are genuinely component-specific and do not represent a shell-wide design decision.

A new shared token must:

1. have a semantic name;
2. have no suitable existing equivalent;
3. derive from the established visual language;
4. be used consistently;
5. avoid triggering unrelated visual migration.

The shell should remain:

* compact and restrained at rest;
* expressive during direct interaction;
* readable over arbitrary application content;
* cohesive across adapted features;
* free from decorative effects without a functional purpose.

## Animation rules

Every new animation must identify:

* the state transition it communicates;
* the properties being animated;
* duration and easing token;
* interruption and reversal behaviour;
* reduced-motion behaviour;
* response to rapid repeated input.

Prefer transforms and opacity over repeatedly animating layout-affecting geometry when they communicate the same result more smoothly.

Input must not wait for an animation to finish.

Rapid state changes must not leave a component:

* partially expanded;
* invisible but interactive;
* visible but non-interactive;
* focused while hidden;
* displaying stale content;
* stuck between states.

Persistent idle animation requires explicit justification.

## Performance rules

The shell must remain responsive while optional services are slow or unavailable.

Requirements:

* never block the UI thread on process or filesystem work;
* keep persistent bar components lightweight;
* lazy-load substantial popovers and detail pages;
* lower or stop polling when a surface is hidden;
* coalesce high-frequency updates;
* avoid recreating windows and models during repeated OSD or toast updates;
* avoid waking a suspended discrete GPU solely for passive telemetry;
* rate-limit backend retries;
* recover services independently rather than restarting the entire shell.

Measure idle resource use at the implementation milestones defined in `../docs/implementation-phases.md`.

## Task procedure

Before editing:

1. inspect the target component and its parent surface;
2. inspect its controller, services, shared state, and theme dependencies;
3. search for other consumers of the same APIs;
4. read the relevant specification, decisions, phase, and open questions;
5. identify the smallest coherent set of files that must change;
6. identify required fixture, unavailable, and failure states.

For substantial tasks, provide a brief plan before modifying files.

During implementation:

* keep the requested scope narrow;
* preserve behaviour not explicitly changed;
* avoid unrelated formatting, renaming, or cleanup;
* do not silently change public component, service, IPC, or configuration contracts;
* do not solve unrelated open questions;
* keep experiments out of production paths;
* use fixture-driven vertical slices where live backends are not yet ready.

Do not create Git commits unless explicitly requested.

When commits are requested, keep each commit scoped and reversible.

## Validation

Use the relevant feature specification's acceptance criteria as the primary validation contract.

After changing QML or supporting implementation:

1. inspect imports, bindings, ownership, and syntax;
2. run available repository validation, formatting, linting, and tests;
3. run `git diff --check`;
4. inspect the complete diff for unrelated changes;
5. exercise fixture, normal, loading, empty, unavailable, error, and recovery states relevant to the change;
6. test rapid repeated interaction and interrupted animations;
7. verify keyboard focus, `Escape`, dismissal, and focus restoration where applicable;
8. test supported monitor scale and orientation cases relevant to the component;
9. reload or launch the shell when a suitable graphical session is available;
10. inspect runtime logs for new warnings or errors.

For visual changes, capture review screenshots when a graphical session and capture tools are available:

* current reviews: `../reviews/current/`;
* comparisons: `../reviews/comparisons/`;
* approved baselines: `../reviews/approved/`.

Do not place screenshots in `approved/` without explicit acceptance.

If runtime, hardware, monitor, or visual validation cannot be performed in the current environment, report it as skipped and state why. Do not infer success from static inspection.

## Safety and reversibility

Never edit the installed shell under `/etc/xdg/quickshell/`.

Never write generated runtime state, credentials, notification content, caches, or machine-local secrets into the repository.

Do not create committed `.old`, `.bak`, or duplicate backup components. Git is the rollback mechanism.

Do not remove the currently working execution path until its replacement has passed the validation available for the task.

Avoid combining architectural migration and visual redesign unless the task explicitly requires both.

Do not change unrelated services to make a local UI implementation easier.

## Completion report

At the end of a task, report:

* files changed;
* behaviour added or altered;
* architectural or configuration contracts changed;
* retained or changed Caelestia dependencies;
* reference implementations or ideas adapted;
* validation commands and manual checks performed;
* skipped checks and their reasons;
* known limitations;
* newly discovered unresolved questions.

Do not claim visual, runtime, hardware, or test validation that was not actually performed.
