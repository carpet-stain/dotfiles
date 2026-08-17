# Credentials

Operational companion to
[ADR-0041](adr/0041-vended-token-as-the-routine-gh-credential-with-a-fail-closed-sentinel.md),
which owns the credential model — resolution order, the fail-closed
sentinel, the demoted-PAT escape hatch, expiry, elevation. This doc binds
the local setup: what's wired where, and the one-time steps. Everything
here is macOS-only (no consumer on the payload-only Linux target,
ADR-0006).

## Routine gh auth: `.envrc` / `.envrc.local`

`.envrc` resolves `GH_TOKEN` by calling `use_github_token`
(`direnv/lib/use_github_token.sh`, deployed to `~/.config/direnv/lib/` so
every vended-covered repo shares one copy — infra#195); the function's and
`.envrc`'s own comments carry the mechanics. `zsh/.zshenv` runs
`direnv export` eagerly so non-interactive shells (scripts, cron, an
agent's tool shell) get the same fail-closed guarantee (#160).

Escape hatch: fill the empty `export GH_TOKEN=` line in gitignored
`.envrc.local` with a fresh fine-grained PAT (Contents/Issues/Pull
requests/Actions read-write, no Administration, ~2 min — the pre-cutover
PATs are revoked). `.envrc.local.example` is the tracked template; a
pre-commit hook enforces its export lines stay empty and its structure
matches.

## Vended cross-repo token (AWS SSM)

The source of routine `GH_TOKEN`: the sibling repo `carpet-stain/infra`
vends a rotating, narrowly-scoped GitHub token (no Administration; grant
list in infra's `vend-token.yml`) into SSM Parameter Store at
`/runtime/vended-token` — design and role matrix in infra's ADR-0010; this
doc only binds the local setup (#377). `scripts/aws-vended-token.sh`
fetches it fresh at shell entry, failing loud if stale or missing — its
header owns the mechanism (Keychain-read IAM credential, process-only
export, no ambient `AWS_*`).

One-time setup — create an access key for `infra-local-read` (AWS console,
as root: IAM → Users → infra-local-read → Security credentials → Create
access key, use case CLI), then store it (`-A` allows silent reads, since
the vended path is routine, not elevated; contrast infra's
`infra-aws-local-apply`/`infra-aws-bootstrap` items, added _without_ `-A`
so their crown-jewel reads stay prompt-gated):

```sh
security add-generic-password -s infra-aws-local-read -a <ACCESS_KEY_ID> -A -U -w
# prompts for the value — paste the secret access key,
# keeping it out of shell history
```

`audit-keychain-gate` (`scripts/audit-keychain-gate.sh`, on PATH from the
deploy) verifies infra's elevated items still prompt on every read — its
header owns the why; when to run it is infra's periodic audit (its
`docs/BOOTSTRAP.md`).

## OpenRouter API key (aichat)

The Alt-a floating aichat pane (#511) reads the login Keychain item
`openrouter-api-key` at launch — `scripts/aichat-pane.sh`'s header owns the
resolution order, the routine-tier `-A` call, and the pending infra#170
residency question. Without the item the pane warns and closes. One-time
setup (mint the key at openrouter.ai/settings/keys):

```sh
security add-generic-password -s openrouter-api-key -a openrouter -A -U -w
# prompts for the value — paste the API key, keeping it out of shell history
```

## Scheduled jobs (launchd)

Two jobs, each a `macos/com.carpet-stain.dotfiles.*.plist` symlinked to
`~/Library/LaunchAgents` and loaded by `deploy.zsh`. The plists invoke
their scripts by bare name — launchd can't expand `$HOME`, and the plists
are symlinked as-is, not templated per machine — resolving via
`$HOME/.local/bin`, which `zsh/.zshenv` puts on `PATH` for every shell,
not just interactive ones.

- `backup-agent-memory` (daily, #542) — ships the agent-memory store to
  infra's versioned B2 bucket; the script header owns the what, the
  no-delete key scoping (infra#200), and why no timestamped-key scheme is
  needed.
- `snapshot-token-usage` (weekly, #518) — captures token-usage reports to
  `$XDG_STATE_HOME/token-usage/`, outside Claude Code's 30-day transcript
  prune window; the script header owns the rest.

The backup's Healthchecks.io liveness ping is optional until a check
exists — a blocking part of #542's acceptance, since the 365-day
noncurrent-version floor means a silently-dead job eventually loses
history; the script skips the ping (not an error) if the item is absent.
One-time setup once a check exists:

```sh
security add-generic-password -s healthchecks-agent-memory-backup -A -U -w
# prompts for the value — paste the check's ping URL
```
