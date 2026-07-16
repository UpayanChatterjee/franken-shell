# Reference material instructions

The repository-level `../AGENTS.md` also applies.

This directory contains upstream source references and Franken Shell’s written analyses of them.

## Directory ownership

### `repos/`

Everything under `repos/` is strictly read-only.

These repositories exist only for:

* source inspection;
* behavioural comparison;
* dependency research;
* architecture analysis;
* licence and attribution checks.

Do not:

* edit source files;
* run formatters or fixers that modify files;
* commit, create branches, rebase, reset, or alter Git state;
* update submodules or remotes;
* install dependencies into the reference tree;
* create build products, caches, generated files, virtual environments, or lockfile changes;
* alter reference code to make integration easier;
* make the active shell import files directly from these repositories;
* merge or copy an entire module or directory into the active shell.

Read-only commands such as searching, listing files, inspecting Git history, viewing configuration, and reading source are allowed.

If a tool might write files as a side effect, do not run it inside `repos/`. Use a temporary directory outside the reference tree when such execution is genuinely required.

### `analyses/`

Files under `analyses/` are Franken Shell documentation and may be created or updated when the task includes reference research or feature analysis.

Analyses should record:

* visible behaviour;
* component and state ownership;
* services, IPC, configuration, and runtime dependencies;
* reusable ideas;
* assumptions specific to the upstream project;
* incompatibilities with Franken Shell’s architecture or design;
* relevant upstream paths and revisions;
* licensing or attribution considerations;
* unanswered research questions.

An analysis is evidence, not an authoritative Franken Shell product decision.

Accepted decisions belong in `../docs/decisions.md`. Unresolved product questions belong in `../docs/open-questions.md`. Implementation contracts belong under `../docs/features/`.

## Adaptation policy

Before adapting a referenced feature:

1. read the corresponding analysis when one exists;
2. inspect the relevant upstream source;
3. describe the desired behaviour independently of the implementation;
4. identify upstream-specific assumptions and dependencies;
5. compare the result with Franken Shell’s accepted decisions and architecture;
6. update the relevant analysis or feature specification where necessary;
7. implement through the active shell’s services, controllers, components, and design system.

Reference implementations do not override Franken Shell’s accepted decisions, feature specifications, architecture, interaction language, or visual language.

When copying or substantially adapting selected source code or assets:

* verify that the upstream licence permits it;
* preserve required notices and attribution;
* record the upstream repository, file path, and revision;
* copy only the smallest justified portion;
* do not create an ongoing runtime import from `repos/`.

## Scope discipline

Do not modify reference analyses merely to justify an implementation already chosen.

Do not rewrite unrelated analyses during a feature task.

At completion, report:

* reference repositories inspected;
* analysis files created or changed;
* upstream paths or revisions used;
* ideas adapted;
* licensing or attribution requirements discovered;
* remaining unanswered questions.
