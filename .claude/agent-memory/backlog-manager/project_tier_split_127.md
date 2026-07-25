---
name: project-tier-split-127
description: Payload/dev-tooling/repo-meta tier split — ratified by spike #127, executed via epic #361; the spike's decision comment is the source of truth
metadata:
  type: project
---

Spike #127 ratified the three-tier model (payload / dev-tooling / repo-meta) ADR-0006 named but
left partly TBD; epic #361 executed it (children #362/#363/#364). The full reasoning is the
spike's final decision comment
(https://github.com/carpet-stain/dotfiles/issues/127#issuecomment-5013636073) — the source of
truth for anyone touching this area; don't re-derive it here. A tag+guard mechanism was chosen
over a Brewfile↔Aptfile generator (more machinery than the drift needs). The non-obvious
sequencing and verification constraints that shaped execution live in #361's plan-review
comments.

Related: ADR-0029 (#350, macOS fnm/uv-only) deliberately left Linux scope to this work.
