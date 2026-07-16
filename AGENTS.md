# Franken Shell repository instructions

## Repository scope

This repository contains the product documentation, reference material, and active implementation for Franken Shell: an independently maintained Quickshell desktop shell derived from a heavily modified Caelestia setup.

The active implementation is under `shell/`.

This file applies to the entire repository. Before modifying anything under `shell/`, also read `shell/AGENTS.md`. For implementation-focused sessions, prefer starting Codex with `shell/` as the working directory so both instruction files are loaded.

## Project direction

Franken Shell retains selected Caelestia services, helpers, and runtime dependencies. Removing all Caelestia dependencies is not a project goal.

Visual and behavioural ideas may be adapted from:

* Caelestia Shell;
* Illogical Impulse;
* ActivSpot.

Vicinae and quickshell-overview are adopted integrations rather than features to rebuild without an explicit approved decision.

The active shell must remain one cohesive product. Do not preserve a reference project's structure, styling, naming, or architectural assumptions merely because a feature originated there.

## Sources of truth

Apply project guidance in this order:

1. accepted decisions in `docs/decisions.md`;
2. the relevant specification under `docs/features/`;
3. shared requirements in:

   * `docs/architecture.md`;
   * `docs/configuration-model.md`;
   * `docs/interaction-language.md`;
   * `docs/visual-language.md`;
   * `docs/implementation-phases.md`;
4. broader direction in:

   * `docs/product-vision.md`;
   * `docs/design-principles.md`;
   * `docs/feature-map.md`;
5. current inventories and reference analyses;
6. reference implementation details;
7. implementation convenience.

Do not silently contradict an accepted decision.

Treat every applicable item in `docs/open-questions.md` as unresolved. Recommendations, candidate values, and prototype ranges are not settled requirements.

Do not resolve an open question or revise an accepted product decision unless the task explicitly includes that design decision. When a resolution is approved, update `docs/decisions.md`, `docs/open-questions.md`, and every affected specification together.

If authoritative documents conflict, stop implementation of the conflicting portion, preserve the accepted decision, and report the conflict clearly.

## Repository areas

* `docs/` contains the authoritative product, interaction, architecture, configuration, and delivery specifications.
* `docs/features/` contains implementation-facing feature contracts.
* `references/analyses/` contains existing behavioural and architectural analysis of reference projects.
* `references/repos/` contains read-only upstream reference repositories.
* `shell/` contains the active Franken Shell implementation.

Do not modify anything under `references/repos/`.

Do not treat reference analyses or reference source code as Franken Shell product requirements.

## Feature workflow

Before implementing any substantial feature or behavioural change:

1. read the applicable accepted decisions and shared design documents;
2. read the corresponding specification under `docs/features/`;
3. inspect `docs/component-inventory.md`, `docs/runtime-dependencies.md`, and relevant files under `references/analyses/`;
4. inspect raw reference source only when needed to verify behaviour, dependencies, licensing, or an analysis gap;
5. identify the feature's ownership, service dependencies, architectural assumptions, and unresolved questions;
6. update or complete the feature specification when the implementation contract is missing or materially incomplete;
7. implement through Franken Shell's architecture and shared design system;
8. verify the result against the specification and acceptance criteria.

Do not begin broad implementation from a screenshot, reference repository, or high-level feature-map entry alone.

Prefer narrow vertical slices and fixture-driven work in the sequence defined by `docs/implementation-phases.md`.

## Reference adaptation

Describe and understand desired behaviour independently before adapting implementation details.

Never merge a reference repository wholesale into the active shell.

Do not introduce a reference project's:

* global state ownership;
* direct backend calls from views;
* duplicate service models;
* hard-coded configuration;
* visual tokens;
* dependency assumptions;

unless they independently satisfy Franken Shell's documented architecture and requirements.

When copying or substantially adapting source code or assets:

* verify that the upstream licence permits it;
* preserve required copyright and licence notices;
* record the upstream repository, path, and revision;
* keep copied code limited to the justified component;
* document any continuing runtime or maintenance dependency.

## Working discipline

For substantial tasks:

1. inspect the relevant repository state first;
2. give a short plan before editing;
3. keep the task within the requested files and scope;
4. avoid unrelated cleanup and speculative refactoring;
5. make a best effort from existing documentation rather than inventing missing product decisions.

Do not create Git commits unless explicitly requested.

When commits are requested, keep each commit limited to one coherent feature or refactor and do not mix documentation, unrelated cleanup, and implementation without a clear reason.

## Validation and completion

Before declaring a task complete:

* run the relevant commands required by the nearest applicable `AGENTS.md`;
* run `git diff --check`;
* inspect the complete diff;
* verify that no read-only or unrelated files changed;
* compare the result against the relevant feature acceptance criteria;
* record newly discovered design questions instead of silently deciding them;
* report files changed, checks performed, failures or skipped checks, and remaining unresolved issues.

Do not claim that a check passed unless it was actually run.
