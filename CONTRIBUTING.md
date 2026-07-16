# Contributing to Franken Shell

Franken Shell is developed as a sequence of narrow, test-validated pull
requests. The operational source of truth is
`docs/franken-shell-pr-engineering-roadmap.md`; accepted decisions and feature
specifications remain authoritative for product behavior.

## Before starting

1. Read `AGENTS.md` and the nearest nested `AGENTS.md`.
2. Select one open roadmap item whose prerequisites are complete.
3. Branch from a green, current `main` using the branch name recorded in the
   roadmap.
4. Change that roadmap item to `in-progress` immediately after creating the
   branch.

Do not combine unrelated feature, documentation, formatting, or infrastructure
work. Do not modify anything under `references/repos/`.

## Local validation

Install the repository-owned tooling, then run the same entry points used by
GitHub Actions:

```sh
./ci/bootstrap-tools
./ci/run hygiene
./ci/run format
./ci/run lint
./ci/run unit
./ci/run smoke
```

`./ci/run all` runs the complete local sequence. The pinned and Arch container
lanes install their system packages in GitHub Actions; local development uses
the compatible tools already installed on the workstation.

Existing formatting and QML lint debt is recorded under `ci/baselines/`.
Changing a non-compliant file changes its fingerprint and requires either
removing the debt or explicitly reviewing a baseline update. New files do not
inherit those exceptions.

## Pull requests

Use the pull-request template and include:

- the outcome and explicit non-goals;
- the architectural owner and adapter boundaries;
- the applicable change-to-test rows from the roadmap;
- automated and manual evidence;
- failure, fallback, reload, and teardown behavior;
- documentation and roadmap updates;
- a safe rollback path.

All required checks must pass. Do not disable or weaken a failing check merely
to merge. Hosted CI limitations must be recorded as limitations rather than
presented as automated coverage.

## Main branch protection

Once PR-001 has created the check names on GitHub, protect `main` with these
required status checks:

- `CI / Hygiene`
- `CI / Format`
- `CI / Lint`
- `CI / Unit`
- `CI / Smoke`
- `CI / Pinned`
- `CI / Arch`

Keep force pushes and branch deletion disabled. Do not require an approving
review while the repository is solo-maintained; required checks provide the
merge gate.

## Merge bookkeeping

Keep the roadmap item `in-progress` while review or CI work remains. Change it
to `closed` only in the final merge-ready commit or in a small bookkeeping PR
after merge, and record the pull-request number and merge commit when known.
