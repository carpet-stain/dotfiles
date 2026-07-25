---
name: project-deal-finder
description: New initiative (2026-07-24) — personal secondhand-hardware marketplace monitor with LLM-judged relevance; repo not yet created, infra#75 files the creation ask
metadata:
  type: project
---

**Status: pre-repo.** User handed a full functional spec (G1-G6 + FRs, notify-only, no
auto-purchase, no adversarial scraping) for a system that polls marketplaces (Reddit first, then
Craigslist RSS), filters against an in-progress PC build's open needs, LLM-judges fit/price/gap,
and pushes a notification. Deliberately not my call to make: language/framework/host — the user's
own spec says "hand it to another LLM for the how."

**Why the repo doesn't exist yet:** this account routes all repo creation through
`carpet-stain/infra`'s `repos.tf` (`local.repos` map + `tofu apply`), not raw `gh repo create` —
see [[reference-infra-repo]] and [[project-terraform-repos-as-code]]. Filed **infra#75**
(`feat(repos): add deal-finder to local.repos`) to add the map entry; that's a real repo-creation
+ elevated-`tofu apply` step, out of backlog-manager's scope to run (never touch repo
settings/administrative resources).

**Next steps, in order, none of them mine to execute:**
1. infra#75's `tofu apply` (elevated) — creates the empty, governed repo.
2. Copier scaffold: `uvx copier copy project-starter-template/git-flow <dir>` + a language
   overlay, per project-starter-template's bootstrap runbook (git-flow/README.md — note that
   runbook's steps 1/3/4 are stale, project-starter-template#13/#15 already track fixing it;
   steps 1/3/4 are superseded by infra's `tofu apply` per [[project-gitflow-starter]]). Watch the
   known gotcha: branch protection is live before the first commit exists (GH013) — work around
   via the branch-rename contingency, not a forced push.
3. **Once the repo exists, come back here and build the real backlog**: an epic mapping G1-G6 to
   the "Suggested Build Sequence" in the user's spec (one source → normalizer → keyword filter →
   LLM analysis → notification → seen-set as the first vertical-slice child issue; build-state
   config next; second source adapter to prove the extensibility contract; hardening last). The
   full spec text lives in this conversation's transcript, not restated here — don't re-derive it
   from memory when the time comes, ask the user to re-paste or check chat history if it's not
   still available.

No architecture/plan-review gate applies yet — nothing's `architecture`-labeled or `epic`-labeled
because nothing's filed in a real repo yet.
