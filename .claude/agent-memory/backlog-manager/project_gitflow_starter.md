---
name: project-gitflow-starter
description: Portable git/GitHub governance bootstrap (epics #136, #309) — extracted to project-starter-template; lessons that would recur in any similar extraction
metadata:
  type: project
---

Epics #136 (codify the governance bootstrap as copier templates) and #309 (extract them to
`carpet-stain/project-starter-template`) shipped; **the durable decision record is ADR-0028** —
read that for the why. This entry keeps only what would matter again in a similar extraction.

**Load-bearing finding — `/compose-agents` only ports prose, by design** (its SKILL.md keeps
`Write` out of `allowed-tools`). Governance has four layers and only layer 1 moves through it:
prose (compose-agents) → tracked enforcement files (needed the copier scaffolder) → repo
settings (Administration API — never mine to run; provisioned by infra's `tofu apply` for
`repos.tf`-managed repos, see [[reference-infra-repo]]) → label taxonomy (same
infra-supersedes-manual pattern).

**Two couplings that would recur:** (a) the branch-protection ruleset must require the *exact*
check names pr-guards.yml emits (`single commit`, `conventional commit`) or bad merges slip
through; (b) a repo's actual branch model may not match git.md's documented default —
compose-agents can't instantiate prose it wasn't told about; making a non-default model portable
means promoting it to a first-class rule in git.md/github.md first (judgment work, propose
before writing).

**Bootstrap gotcha** (recorded in project-starter-template#1's closing comment): once creation
routes through `repos.tf`, branch protection is live *before* the first commit exists (GH013) —
use the runbook's branch-rename contingency, never a forced push.
