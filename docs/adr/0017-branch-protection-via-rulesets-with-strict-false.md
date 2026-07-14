# 17. Branch protection via rulesets with strict:false

Date: 2026-07-12

## Status

Accepted

## Context

Every new repo bootstrapped from the copier template (#136) needs branch
protection on `main`: rebase-merge only, single commit, required status checks.
Applying that goes through GitHub's Administration API, which the routine scoped
`GH_TOKEN` deliberately can't touch — and which shouldn't be automated into a
copier post-gen task, since that would run under whatever token invoked the
scaffold (a2fd6da9, github.md). GitHub has two enforcement systems for this,
classic branch protection and rulesets; the ruleset was prototyped and dry-run
validated in the #137 spike before the bootstrap script shipped (a2fd6da9).

Required checks must not force green PRs to update-then-re-run: rebase-merge
already replays commits onto current `main` server-side at merge time, so a
pre-merge "branches up to date" gate is redundant and just re-runs CI. The
ruleset therefore sets `strict_required_status_checks_policy: false`
(bootstrap-branch-protection.sh). The one live gotcha, surfaced later in #185
(OPEN): a stray legacy classic rule with `strict:true`/`enforce_admins:true` can
coexist and win, because GitHub enforces both systems and takes the most
restrictive — silently overriding the ruleset's `strict:false` until the legacy
rule is deleted.

(provenance: partial — the artifacts are commit a2fd6da9 and
bootstrap-branch-protection.sh; #185 is an OPEN bug that supplies the
`strict:false` rationale after the fact, not a ratifying record, and no source
records a head-to-head classic-vs-rulesets weighing at decision time.)

## Decision

Enforce `main` protection via a single GitHub ruleset (`protect <branch>`), not
classic branch protection. The ruleset carries a `pull_request` rule restricted
to `allowed_merge_methods: ["rebase"]`, plus `deletion`, `non_fast_forward`, and
`required_status_checks`. Required checks are always `single commit` +
`conventional commit` (the pr-guards.yml contract) plus any per-repo extras
passed as args (e.g. `lint`), and run with
`strict_required_status_checks_policy: false` — do not require the branch up to
date before merge. Applied idempotently by
scripts/bootstrap-branch-protection.sh, run deliberately by a human with an
elevated token (`env -u GH_TOKEN`), never wired into CI or a copier post-gen
task.

## Alternatives considered

- **Classic branch protection** — rulesets were the choice as the single source
  of truth; a lingering classic rule is treated as drift to delete, since it
  coexists with the ruleset and GitHub takes the most restrictive of both, so a
  stray classic rule silently overrides ruleset intent (#185, OPEN). No source
  records this as a weighed head-to-head at decision time (inferred).
- **`strict_required_status_checks_policy: true`** (require branches up to date
  before merge) — forces every green PR to run "Update branch", rebasing current
  `main` in and re-running CI before merge; redundant under rebase-merge, which
  already replays commits onto current `main` server-side at merge time (#185,
  bootstrap-branch-protection.sh).
- **Automate the bootstrap into CI or a copier post-gen task** — needs
  Administration scope the routine `GH_TOKEN` deliberately lacks, and a post-gen
  task would run under whatever token invoked the scaffold; it must stay a
  deliberate human-invoked step separate from the routine credential (a2fd6da9,
  bootstrap script header).

## Consequences

Rebase-merge lands the already-squashed, already-Conventional commit on `main`
verbatim (github.md), and green PRs merge without a forced update + CI re-run
once `strict:false` actually governs (#185). One ruleset is the intended single
source of truth, applied idempotently across bootstrapped repos
(bootstrap-branch-protection.sh). Costs: the bootstrap needs an elevated token
run by hand (`env -u GH_TOKEN`), and rulesets require GitHub Pro or a public
repo — a private repo 403s (bootstrap script header). Premise still open: a
legacy classic `strict:true`/`enforce_admins:true` rule can coexist and win, so
the model only holds once that legacy rule is deleted and the script asserts it
absent (#185, OPEN). Revisit if repos-as-code lands (Terraform github provider):
replace the script with a `github_repository_ruleset` resource for plan/apply
drift detection (bootstrap script header).
