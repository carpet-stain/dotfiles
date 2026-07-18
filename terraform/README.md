# Repos as code

GitHub API-level governance managed with OpenTofu — repository settings,
labels, and branch rulesets for the repos in `repos.tf`'s map. Working-tree
files stay copier-owned (`git-flow/`); the tool, state backend, and import
strategy are ADR-0022. Part of epic #273; this MVP is #294.

For repos in the map, this replaces `scripts/apply-labels.sh` and
`scripts/bootstrap-branch-protection.sh` — plan/apply here instead of
re-running those. Unmanaged repos still use the scripts and the bootstrap
runbook.

## Running

Environment comes from direnv — `.envrc` derives the backend credentials,
endpoint, and the `TF_ENCRYPTION` block from the secrets in `.envrc.local`
(see `.envrc.local.example`), so everything must run from inside the repo.
The runtime installs via tenv (Brewfile), pinned by `required_version`.

```sh
just tofu init          # once per checkout
just tofu plan          # routine scoped token — read-only, safe anywhere
just tofu-apply         # elevated session token (Administration scope)
```

State is client-side encrypted before it reaches the R2 bucket; losing
`TF_STATE_PASSPHRASE` means re-importing, not recovering (ADR-0022).

## Adding a repo

Add an entry to `local.repos` (and, if it already exists on GitHub, it's
adopted by the `import` blocks in `imports.tf` on the next apply). Labels
apply per-repo; the ruleset resource currently covers `dotfiles` only —
generalize both when the second repo joins the map.
