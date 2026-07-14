# 10. lefthook over the pre-commit framework for git hooks

Date: 2026-07-11

## Status

Accepted

## Context

This repo adopted the `pre-commit` framework for shift-left tooling: zsh syntax
(`zsh -n`), `shellcheck` on `linux/*.sh`, `actionlint` on workflow files, an
auto-rebase-on-push hook, and a credential-template sync check
(`.envrc.local.example`) (#73). `pre-commit` needs a Python runtime, and
`macos/deploy.zsh` installed `python` via Homebrew solely for it — nothing else
in the repo touches Python (#73). `pre-commit` also maintains its own separately
pinned, isolated copies of shellcheck/actionlint via its `repo:`/`rev:`
mechanism (`shellcheck-py`, `rhysd/actionlint`), duplicating binaries the repo
already installs as Homebrew formulae for editor use (#73). At the time, CI
(`ci.yml`) implemented its own zsh-syntax/shellcheck/actionlint checks
independently — `.pre-commit-config.yaml` was just a local mirror of CI, not
something CI invoked — so the choice of hook manager was local-tooling-only,
with CI unaffected (#73). A spike (#73, labelled `spike`) was opened to test
lefthook side-by-side rather than decide from memory. Every existing hook
translated directly to lefthook with no functional gap — verified against the
repo's real configured files, not lefthook's docs (#73, be3faf8c).

## Decision

Use lefthook as the git-hook manager. lefthook is a single Go binary with no
runtime dependency, and shells out to whatever binaries are on PATH (the
Homebrew-installed shellcheck/actionlint/etc.) rather than maintaining its own
tool-installer, deduping down to one copy of each versioned like every other CLI
tool here (#73, be3faf8c). `lefthook.yml` becomes the single YAML source for
every lint/format hook. `.pre-commit-config.yaml` was deleted, `python` dropped
from `macos/Brewfile` (lefthook added in its place), and
`install_pre_commit_hooks` renamed to `install_lefthook_hooks` in
`macos/deploy.zsh` (be3faf8c).

## Alternatives considered

- **The pre-commit (Python) framework — keep the incumbent** — needs a Python
  runtime, which `macos/deploy.zsh` installed via Homebrew solely for
  pre-commit, making it the only Python dependency in the repo (#73). It also
  maintains its own separately pinned copies of shellcheck/actionlint via
  `repo:`/`rev:`, duplicating the Homebrew formulae the repo already installs;
  lefthook dedupes to one copy of each, versioned like every other CLI tool here
  (#73). lefthook is a single Go binary with no runtime dependency, and every
  existing hook mapped over with no functional gap (#73, be3faf8c).

## Consequences

Removed the repo's only Python dependency — `python` dropped from
`macos/Brewfile`, hook manager is now one Go binary (be3faf8c).
shellcheck/actionlint are versioned once via Homebrew instead of twice, but
lefthook can't pin hook-tool versions — you get whatever is on PATH, matching
how the rest of the repo's CLI tools are versioned (#73). lefthook has no
shared-stage concept, so the credential-template sync check
(`envrc-local-example-sync`), needed on both pre-commit and pre-push, is
duplicated across the two top-level keys rather than shared (#73, lefthook.yml).

At migration time CI still ran its own independent checks, so `lefthook.yml`
only mirrored CI by convention (#73). A later change (251cded4, same day) made
`ci.yml`'s lint job invoke `lefthook run pre-commit --all-files` directly, so
`lefthook.yml` became the single source both CI and the local hook read and CI
can no longer drift from it — and the per-file-type tools it added (shfmt,
stylua, selene, taplo, yamlfmt, markdownlint-cli2, prettier) postdate this
decision. Revisit if a hook ever needs a pinned/isolated tool version lefthook
can't provide.
