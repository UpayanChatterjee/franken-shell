# Franken Shell — Project State

> **Status:** Current repository publication record
> **Recorded:** 2026-07-17
> **Operational plan:** `franken-shell-pr-engineering-roadmap.md`

## Repository

- **GitHub repository:** `https://github.com/UpayanChatterjee/franken-shell`
- **Git remote:** `git@github.com:UpayanChatterjee/franken-shell.git`
- **Visibility:** Public
- **Default branch:** `main`

## Pre-PR engineering baseline

- **Baseline commit:** `d02c7946e69a195e3e53a3ac9da8bfaa4aa353ec`
- **Annotated tag:** `engineering-baseline-v1`
- **Baseline outcome:** Phase 0 plus the implemented Phase 1 foundations: configuration helper/client/service and typed snapshots, MonitorRegistry, and CommandRegistry.

The baseline tag identifies the final implementation commit before the
repository switched to the PR-scoped engineering workflow. Roadmap and project
state bookkeeping follow that tagged commit and do not change the tagged
implementation.

## Publication verification

The baseline was verified by:

1. confirming local `main` and remote `main` resolved to the baseline commit
   before bookkeeping;
2. cloning the public repository into a new temporary directory;
3. confirming the clone checked out the same commit;
4. confirming `shell/dev/franken-shell` was present and executable;
5. running the existing QML check from the fresh clone.

GitHub contained no pull requests or Actions runs when this record was created.
PR-001 establishes the repository CI and pull-request workflow used for all
subsequent implementation.
