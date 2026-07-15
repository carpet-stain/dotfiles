# 19. Adopt just over make as the repo task runner

Date: 2026-07-14

## Status

Accepted

## Context

Dev verbs were scattered. `linux/Makefile` held 10 small targets driving an
OrbStack Debian VM to exercise `linux/deploy.sh` (vm-fresh/deploy/smoke-test/
test/e2e-test/…) — macOS-host tooling, run by hand before a release, not wired
into CI (`e2e-linux.yml` calls `bash linux/deploy.sh` and `bash
linux/smoke-test.sh` directly, not the Makefile). Every other dev verb —
`lefthook run pre-commit --all-files`, `scripts/act-run.sh`, `git cliff --bump`
— lived only as a documented command in `AGENTS.md`, with no single discoverable
entry point. There was no root runner.

\#184 asked the consolidation question: one task-runner for the whole repo, not
make-in-`linux/` alongside anything else. Its own written analysis leaned _keep
make_ — make ships with the Xcode CLT (zero install), the Makefile was already
proven, and its usual boilerplate/discovery downsides aren't real pain at 10
targets. The counter-case is ergonomics and discoverability as the repo grows a
root dev-verb surface.

## Decision

Adopt `just` as the single repo-wide task runner. A root `justfile` migrates the
10 linux VM recipes verbatim in behavior (same invocation UX, e.g. `just
e2e-test DEBIAN=bookworm VM=…`) and folds in the common dev verbs — `lint`
(lefthook), `act`, `cliff-preview`, `adr` (adr-tools) — so `just --list` is the
one discoverable entry point. `linux/Makefile` is deleted; `just` is added to `macos/Brewfile`
and to `ci.yml`'s lint job, which now runs `just lint --no-tty` — the same
entry point contributors run — instead of invoking `lefthook` directly, so CI
and local can't drift. Elevated-credential scripts (`apply-labels.sh`,
`bootstrap-branch-protection.sh`)
deliberately stay out of the justfile — they need the dropped-token admin
session and shouldn't read as routine recipes.

## Alternatives considered

- **Keep make (\#184's recommendation)** — zero new dependency, already the
  repo's pattern, boilerplate cost is small at this scale. Rejected: the
  owner prioritizes `just`'s ergonomics — `just --list` discovery, real named
  parameters, no tab-sensitivity or `.PHONY` bookkeeping — for a growing root
  dev-verb surface, and one Homebrew dependency is an acceptable price for a
  consolidated, self-documenting runner. The "modern replacement" rule that
  justifies fd/rg/eza/bat over their coreutils originals doesn't transfer
  cleanly (a runner isn't a daily-driver with constant friction), so this is an
  explicit preference call, not that rule applied.
- **Two runners — `just` at root, `make` in `linux/`** — rejected: split
  tooling is exactly the problem \#184 names; one runner is the point.
- **`linux/justfile`, 1:1, no root file** — rejected: it swaps the tool but
  keeps the verbs siloed in `linux/`, giving no repo-wide entry point. The root
  `justfile` with `just --list` is the discoverability win.

## Consequences

One new dependency — `just` in `macos/Brewfile` for local use and in `ci.yml`'s
lint job, which now shares the `just lint` entry point. The VM recipes stay
macOS-host-only: they SSH into an OrbStack VM, so the linux e2e CI job (which
runs `deploy.sh` inside a container) can't share them — CI↔local convergence is
limited to `lint`, where the execution model matches, not the VM path, where it
genuinely differs. `just --list` is the discovery surface; `brew bundle`
installs `just` on deploy, nothing to symlink (the justfile runs in place from
the repo checkout). The justfile stays unlinted, like the repo's other
deliberately-unstyled formats (kdl, most json) — a `just --fmt --check` hook
isn't worth it for one small, stable file (CI now has `just`, so that's no
longer the blocker). Revisit if the verb surface grows enough to warrant it.
