# 39. Extract agent definitions to the agents repo as a main-tracking submodule

Date: 2026-08-13

## Status

Accepted. Amended by `carpet-stain/agents` ADR-0002 (vendored agent cloud channel, #597): this
ADR's SHA-pinning deferral is resolved for that second, cloud-only channel — the decision below
(pull-latest `main` via submodule) is unchanged for this, the local-CLI channel.

Residency scope amended 2026-08-20 by [ADR-0050](0050-philosophy-layer-exported-ahead-of-the-substrate-gate-amending-the-adr-0039-residency-scope-clause.md):
the decided philosophy layer (framework doc, `docs/operating-model.md`, agents#22) exported to
`carpet-stain/agents` ahead of the substrate gate; the operating-model machinery export
(roster/ceremonies/telemetry) remains gated on #576, unchanged.

## Context

The agent definitions — personas (`claude/agents/**`), the rules tree
(`claude/rules/**`), and the skills (`claude/skills/**`) — live inside
personal dotfiles because they started here, not because a workstation-config
repo is where team-managed agent definitions belong. Managing an agent _is_ a
PR to its definition, and nobody PRs a colleague's change to someone's
personal dotfiles (#545, principle 7). The moment there's a second user or a
second consuming project, the definitions need a team-shaped home.

Spike #563 (plan-approved 2026-08-13, two review rounds) settled residency,
the extraction boundary, and distribution against the live `claude/` tree.
Its key finding: no genuine dotfiles-coupling exists in `rules/` or
`agents/` — every rules file already self-identifies as loaded globally, and
the dotfiles-token hits are provenance headers and illustrative examples, not
structural coupling. The extraction is mostly move-with-scrub, not surgery.

This ADR extends the operating-model record (ADR-0035 through 0038: named
identities, memory, authorship) — it doesn't start a new track. ADR-0028
established the extraction pattern it reuses.

## Decision

**Residency: a dedicated public repo, `carpet-stain/agents`,** created and
governed through infra's `repos.tf` — the same extraction pattern
project-starter-template used (ADR-0028), inheriting rulesets, the
single-commit/Conventional-Commit gates, and the canonical labels from day
one (infra#177). It carries its own backlog; agent-scoped ADRs are born there
going forward. Dotfiles ADRs stay put as historical origin, cited by pointer
(`see carpet-stain/dotfiles ADR-NNNN`), never restated. The repo is
provider-neutral markdown plus skill dirs, deliberately ignorant of how any
consumer invokes it — one definition, many instantiations, no fork.
Per-project instantiation config (trigger, model, memory scope, provider
binding) stays with each consumer.

**Distribution: a git submodule tracking `main`** — the deploy pulls latest.
Strict SHA-pinning is deferred until a team plus cross-machine
reproducibility make it worth the edit-friction: first-party high-churn
definitions make a hard pin pure friction for a solo maintainer, and pinning
later is a config flip on the same mechanism, not a re-architecture. The
deploy symlinks the submodule's `rules/ agents/ skills/` into `~/.claude/`,
layered with the local `settings.json` and `verify-nvim-config`.

**The extraction boundary** is the three-bucket test — _"would this be true
verbatim for the same agent working in a different repo?"_ — yielding:

- **MOVES:** all `rules/universal/*`, `rules/tools/*` (git, go, python,
  terraform), `rules/platform/github.md`, `rules/domain/architecture.md`,
  `agents/*` (backlog-manager, plan-reviewer), and every skill except
  verify-nvim-config. `git.md`/`github.md` move whole, not split — they're
  clean universal baselines whose repo-specific realization already lives in
  dotfiles' `AGENTS.md`. Most moves are move-with-scrub: invert the
  `Canonical source: my dotfiles` provenance headers, scrub dotfiles
  worked-examples from audit-rules/audit-memory.
- **STAYS:** `skills/verify-nvim-config`, `settings.json`,
  `AGENTS.md`/`CLAUDE.md`, the deploy scripts, `docs/adr/**`.
- **SPLITS:** `claude/README.md` only — the agent repo gets its own; the
  dotfiles one shrinks to "consumes the agent repo + local specifics".

Migration carries history (`git filter-repo` / `subtree split`) and
fully-qualifies surviving inline `#NNN`/ADR pointers as
`carpet-stain/dotfiles#NNN` so they resolve cross-repo. Both deploy scripts
gain a `required()` submodule-init step that aborts on failure — an
uninitialized submodule would otherwise silently empty `~/.claude/rules`,
machine-wide, with no error.

**Cross-repo seams,** stated so they don't silently rot:

- `backlog-manager.md` → **dotfiles ADR-0036.** The operative MCP-memory
  contract (entity types, pointer-shaped observations, the hardcoded
  `~/.claude/agent-memory-mcp/…` store path) moves with the definition; the
  decision record stays here as origin, cited by pointer.
- **The provider-adapter seam:** the `SKILL.md`/agent-frontmatter schema and
  the `~/.claude/*` paths are the named coupling points a future adapter
  binds. Claude Code stays the sole concrete binding — seam named, no
  abstraction built for a single consumer (#545, principle 8).

## Alternatives considered

- **Deploy-clone without submodule tracking** — rejected: no clean update
  path, a network dependency at deploy time, and no reproducibility story
  even as a future option. The submodule gives the same pull-latest behavior
  now and a pin later, one mechanism.
- **A published Claude plugin** — rejected as the distribution mechanism:
  vendor-coupled, which contradicts the repo's provider-neutral premise. Kept
  as the _future_ home for the provider adapter if Claude Code's plugin
  system matures — the adapter is exactly the vendor-specific layer a plugin
  should carry.
- **Keeping the definitions in dotfiles behind better docs** — rejected: no
  documentation fixes residency. Team-managed means PR-able by a second
  person, and a personal dotfiles repo structurally isn't.
- **Strict SHA-pinning from day one** — deferred, not rejected: pure
  edit-friction while one maintainer is the only author and consumer.
  Revisited when a team or cross-machine reproducibility arrives.

## Consequences

- Agent-definition changes become normal PRs to `carpet-stain/agents`,
  reviewable by anyone — the property the whole extraction exists for.
- Dotfiles shrinks to consumer: submodule wiring, deploy symlinks, local
  `settings.json`, and the repo-specific `AGENTS.md` realization. Its ADRs
  0033/0035–0038 remain the historical record the moved definitions point
  back at.
- Two cross-repo seams now need tending: the memory contract's pointer back
  to ADR-0036, and the provider-adapter coupling points. Both are named
  above precisely so a future change to either side knows what it's breaking.
- The deploy gains a hard dependency on submodule init — hence the
  `required()` abort in both scripts; deploy-pair-coupling enforces the
  both-scripts change.
- Revisit the pinning deferral when a second person or machine-reproducibility
  requirement appears; revisit the plugin rejection if Claude Code's plugin
  system becomes the natural adapter home.

Deciding spike: carpet-stain/dotfiles#563. Extraction lands via #567
(Phase 1) and its Phase 2 follow-on; the repo itself via infra#177.
