# 41. Vended token as the routine gh credential with a fail-closed sentinel

Date: 2026-08-13

## Status

Accepted

Supercedes [7. Scoped GH_TOKEN credential model for routine gh usage](0007-scoped-gh-token-credential-model-for-routine-gh-usage.md)

## Context

Both halves of ADR-0007's model are retired in substance, so it reads as the
current model while describing one that no longer exists — misleading to any
contributor or agent who trusts it. Surfaced by an `audit-rules` pass
during #453's implementation (#538).

- **Routine credential.** #453 / PR #537 (`6d6ebe76`) made infra's rotating
  vended token the routine credential. 0007's hand-minted fine-grained PAT in
  gitignored `.envrc.local` meant per-repo minting toil and a long-lived static
  secret on disk per repo; a covered repo now needs neither.
- **Elevation.** infra#151/#152 (infra ADR-0013) moved the fleet dev PAT into
  gh's keyring and admin operations behind infra's Keychain-gated
  `with-infra-secrets.sh --gh-admin`. 0007's "elevate to the keyring session"
  names a path that no longer carries admin at all.

What carries forward from 0007 unchanged, and is not re-decided here: routine
work never holds Administration; real tokens stay gitignored, never committed;
one credential covers both `gh` and `git-cliff` via the `GITHUB_TOKEN` alias,
including #213's correction that elevation must drop both vars.

## Decision

Routine `gh` rides the vended token, the scoped PAT is demoted to an escape
hatch, and an unconditional sentinel is the floor. `.envrc` resolves `GH_TOKEN`
in exactly that order: any non-empty `GH_TOKEN` already in the environment wins
— the `.envrc.local` escape hatch, or one inherited from the parent shell; else
the vended token; else `GH_TOKEN=vended-unavailable-see-453`.

**The sentinel is fail-closed, unconditional, and last.** Leaving `GH_TOKEN`
empty on failure is fail-open: `gh` silently reaches its keyring credential,
which is #160's hole, and a `log_error` doesn't prevent it — stderr noise while
gh succeeds on another credential is still fail-open. A non-empty garbage value
is authoritative to gh, so it 401s visibly instead. Unconditional and last
because two distinct paths leave the variable empty: the vended fetch ran and
failed, or the `infra-aws-local-read` Keychain item was absent so the fetch
block never ran at all. A sentinel nested in that block's `else` covers only the
first — and the second is precisely the machine that lacks the Keychain item yet
still carries a gh keyring login to fall through to. The behavior is pinned by an
acceptance probe rather than assumed stable:
`GH_TOKEN=vended-unavailable-see-453 gh api user` must 401, never return the
keyring identity.

The containment argument was restated mid-implementation, when infra#151/#152
landed: the keyring holds the dev PAT rather than an admin session, so
fall-through is no longer admin exposure — but the dev PAT covers infra, the one
repo the vended grant deliberately excludes, so fail-closed still earns its
keep.

`GITHUB_TOKEN` aliases the resolved `GH_TOKEN`, so `git-cliff` inherits the
sentinel too. A loud git-cliff 401 while the vended path is down is intended,
not a git-cliff bug; `--offline` skips the lookups.

**The PAT is demoted, not deleted.** The `export GH_TOKEN=` line stays — empty —
in `.envrc.local` and in the tracked `.envrc.local.example`, so the
template-sync check and the escape hatch can't fight: a filled local PAT strips
to the same empty line the template carries. The pre-cutover PATs are revoked,
so the hatch is "mint a fresh scoped PAT (Contents/Issues/Pull requests/Actions
read-write, no Administration, ~2 min) and fill the line," not "paste the old
one back." Rollback is deliberate.

**Expiry is accepted, not engineered around.** The token is fetched fresh at
shell entry and never cached; its ~1h life against a re-mint cycle measured in
minutes leaves most of an hour of runway per fetch. A long-lived shell can
outlive it — remedy is `direnv reload` interactively, or a new shell for an
agent, where `.zshenv`'s eager `direnv export` re-fetches.

**Elevation.** `env -u GH_TOKEN -u GITHUB_TOKEN gh ...` drops to gh's keyring,
which since infra#151 is the fleet dev PAT with no Administration. Genuine admin
rides infra's `with-infra-secrets.sh --gh-admin` (infra ADR-0013). Both vars
must drop, because `.envrc` aliases `GITHUB_TOKEN` to the resolved `GH_TOKEN`:
dropping one leaves the identical token behind in the other. #213 reached the
right rule from a wrong mechanism — it attributed this to gh preferring
`GITHUB_TOKEN`, which is not how gh resolves them (verified on gh 2.97.0:
`GH_TOKEN=aaa GITHUB_TOKEN=bbb gh auth status` fails on `GH_TOKEN`). Value
identity, not precedence, is why one var is a no-op.

Scope: this binds the local credential model only. The vended token's design,
grant, and role matrix live in infra ADR-0010, admin elevation in infra
ADR-0013 — cited, not restated.

## Alternatives considered

- **Leave `GH_TOKEN` unset when the vended fetch fails** — the first shape of
  #453, retracted in review. It reopens #160: gh falls through to the keyring
  credential silently, and at the time that meant a full-admin session.
- **Sentinel nested in the fetch block's `else`** — covers only the
  fetch-attempted-and-failed path. An absent or locked Keychain item skips the
  block entirely, leaving the fall-through open on exactly the machines that
  have something to fall through to.
- **A PAT floor** — keep a real scoped PAT as the last resort instead of a
  deliberately-invalid sentinel, with vended as a side-channel. It closes the
  same fail-open, but keeps per-repo PAT toil and long-lived static secrets
  permanently — the problem #453 exists to remove. With fail-closed mandatory,
  vended-as-routine is safe without it.
- **Export the vended token globally from `.zshenv`** — it would then live in
  every process on the machine instead of repo-scoped shells. direnv at repo
  entry stays the load point, with its fail-loud expiry check.
- **An auto-refresh `gh` wrapper** — a second mechanism to maintain, for a token
  with most of an hour of runway and a one-command recovery. Revisit on observed
  friction.

## Consequences

A covered repo needs no hand-minted credential, and provisioning a new one is a
one-line change to infra's vend list alongside the `repos.tf` entry it needs
anyway — near-zero, via reviewed code, but not zero: a repo absent from that
list isn't covered. Every failure mode now lands on a visible 401 whose token
value names the issue that explains it.

The costs are an expiry window a long-lived shell can cross, and a health check
that reads differently per path: the vended token is a GitHub App installation
token, so `gh api user` 403s on it by design (user-scoped endpoint) and
repo-scoped probes are the real check — on that command, 403 means the
installation token works and 401 means the sentinel.

Revisit if the vended path proves unreliable enough that the escape hatch
becomes routine (the PAT floor gets a second hearing), if the `GITHUB_TOKEN`
alias is dropped (breaks git-cliff and re-breaks elevation, #213), or if a
routine operation needs a scope the vended grant lacks — grant it narrowly in
infra, Administration stays off.
