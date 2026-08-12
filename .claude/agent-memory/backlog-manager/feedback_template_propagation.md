---
name: feedback-template-propagation
description: Governance-surface changes in dotfiles (git/CI/md-lint/justfile/lefthook) must propagate to project-starter-template — check on every such change
metadata:
  type: feedback
---

Any dotfiles change touching the governance surfaces — git workflow tooling, CI workflows,
basic markdown linting, justfile recipes, lefthook jobs — must be evaluated for propagation to
`carpet-stain/project-starter-template` (payload `git-flow/template/**` + the template repo's
own live copies), and an issue filed there when it applies.

**Why:** the template is the governance source for every future repo; capabilities landing only
in dotfiles rot the template silently. Observed twice on 2026-07-26 before the rule was stated:
gitleaks (dotfiles#390 shipped, template had none → template#26) and the dependabot label
mismatch (template#25). Directed by the user: "anything involving git/CI/basic md
linting/justfile/lefthooks should be added to the template."

**Downstream chain (added 2026-07-26):** propagation is one-hop — dotfiles → template →
consumers. infra syncs its live governance copies from the *template's* output, never ported from
dotfiles directly — two sources would fork the lineage. infra#101 established this pattern (shipped).

**How to apply:** when triaging or filing a dotfiles issue on those surfaces, add a
propagate-to-template acceptance item or a companion template issue. During grooming sweeps,
diff the surfaces (dotfiles' lefthook.yml/justfile/workflows/lint configs vs the template
payload) rather than trusting memory of parity. Scope guard: dotfiles-specific content (zsh,
nvim, deploy scripts, claude/rules) does NOT propagate — only the governance tier the template
already owns. Related: [[feedback-single-source-of-truth]] (the template copy points at its
source's reasoning, never restates it).
