# 7. Scoped GH_TOKEN credential model for routine gh usage

Date: 2026-07-10

## Status

Accepted

## Context

Routine `gh` work in this repo (labels, comments, PRs, actions) needs GitHub
credentials, but the default `gh auth login` keyring session is broadly scoped —
`repo, delete_repo, admin:public_key, gist, read:org` (#160). An agent driving
`gh` would hold `delete_repo` and `admin:public_key` for every routine call, so
a label edit and a repo deletion carry the same authority (#160). The
credential-scoping guidance in `github.md` and AGENTS.md's "Credentials" wants
routine work structurally unable to touch repo settings, branch protection, or
deletion; secrets must stay gitignored, never committed (Security By Default).
Introduced 07-10 with the shift-left tooling work (29a55064, #70).

## Decision

Default `gh` to a fine-grained scoped PAT (Contents / Pull requests / Actions
read-write, no Administration) via `GH_TOKEN`, loaded by direnv from gitignored
`.envrc.local`, instead of the full-admin `gh auth login` session. The tracked
`.envrc.local.example` template documents the scopes and carries an empty export
value. `.envrc` aliases `GITHUB_TOKEN` to the same scoped `GH_TOKEN` so
git-cliff reuses it without a second credential. Genuine admin (branch
protection, deletion) requires explicitly elevating to the keyring session.

## Alternatives considered

- **Full-admin `gh auth login` keyring session for everything** — it is the
  default, and broadly scoped:
  `repo, delete_repo, admin:public_key, gist, read:org` (#160). Routine work
  would carry `delete_repo` and `admin:public_key` continuously — a label edit
  and a repo deletion get the same authority — and an agent holding those scopes
  the whole session is the exact risk to avoid (#160).
- **Hardcode / track the token in a committed file** — a real secret must stay
  gitignored, never committed (Security By Default; #74 tracks moving it
  off-disk entirely). The token lives in gitignored `.envrc.local`; only the
  empty-valued `.envrc.local.example` template is tracked, enforced by a
  pre-commit hook (every export line empty, structure must match) (29a55064,
  #70).
- **A second, separate credential for git-cliff's `GITHUB_TOKEN`** — another
  credential to manage. git-cliff reads `GITHUB_TOKEN` not `GH_TOKEN`; `.envrc`
  aliases it to the same scoped `GH_TOKEN` instead, so one token covers both.

## Consequences

Routine `gh` in interactive shells runs with no admin and no deletion authority;
the escape hatch is explicit. Two gaps surfaced and were fixed, both extending
this model, not superseding it. #160: direnv only fires for interactive shells,
so non-interactive/agent shells fell back to the broad keyring session and the
scoped-token guarantee was inoperative there — fixed by running `direnv export`
eagerly for every shell in `zsh/.zshenv`. #213 extended the model on two layers:
(Layer 1) the scoped PAT had Issues at read/none, so routine grooming
(`gh issue edit --add-label`, comment, close) 403'd — recalibrated to Issues:
read and write (verified live: `X-Accepted-Github-Permissions: issues=write`,
Administration still 403), Administration untouched; (Layer 2) the documented
elevation `env -u GH_TOKEN` was a no-op, because `.envrc`'s `GITHUB_TOKEN` alias
points at the same scoped token and gh prefers `GITHUB_TOKEN` — corrected to
`env -u GH_TOKEN -u GITHUB_TOKEN` in `github.md`, `AGENTS.md`, and the two
bootstrap scripts (75f5592c, Layer 2 of #213). Revisit if: the `GITHUB_TOKEN`
alias is removed (would break git-cliff and re-break elevation), Claude Code
changes how tool-shell env is injected, or a new routine operation needs a scope
the PAT lacks (grant the narrowest scope, keep Administration off — the
least-privilege framing #213 applied to Issues:write).
