# 46. Hosted per-role agent memory over MCP-over-HTTP

Date: 2026-08-16

## Status

Accepted

Roster runtime-homes block extended 2026-08-17 by
[ADR-0048](0048-hosted-github-actions-runtimes-for-plan-reviewer-and-the-self-driving-implementor.md):
plan-reviewer gains a hosted home.

Supercedes the local-store model of
[36. MCP knowledge-graph memory with a private local store](0036-mcp-knowledge-graph-memory-with-a-private-local-store.md)
— the MCP knowledge-graph interface, the pull-recall model, and the translated
content contract all survive; what reverses is the machine-local JSONL store,
its stdio wiring, and the falsified `claude --agent` frontmatter clause.

Supercedes
[43. Per-role memory write-ownership](0043-per-role-memory-write-ownership-amending-the-adr-0036-shared-write-clause.md)
— its "one store per role" rejection is reversed; the shared-reference tier and
the anti-smuggling rule dissolve with it.

Amends ADR-0033's content contract (as carried forward by ADR-0036): adds the
episodic tier beside the semantic pointer layer.

Amends ADR-0042's roster table: runtime homes per the #582 topology.

Decided in epic #581; gating spikes #582 (topology/transport) and #583
(conflict model), design settled by the 2026-08-16 grilling, plan-reviewed.

## Context

ADR-0036 put agent memory in a machine-local JSONL store behind the reference
MCP memory server. Three findings broke that model (#581, spikes #582/#583):

- **Multi-surface requirement.** backlog-manager must work from CLI, the
  macOS app, claude.ai/code web, and iOS against the same memory. Web/iOS
  run in Anthropic's managed sandbox, which cannot reach a machine-local
  store regardless of protocol — so "stdio if local" is dead, not deferred.
- **ADR-0036's `claude --agent` clause is falsified.** Frontmatter
  `mcpServers` is subagent-only (verified at #542 rollout); a standalone
  `claude --agent backlog-manager` session runs memoryless today. Wiring
  must live at config level (`.mcp.json` / settings), not frontmatter, for
  standalone and cloud runs.
- **The reference server races even single-process** (#583): every mutation
  is async load-whole-file → mutate → save-whole-file with no lock, so a
  hosted single endpoint does not serialize by construction — #579's lost
  write reproduces in one process. Online safety must be built.

Separately, ADR-0042's roster made per-role lanes real, and ADR-0043 tried
to hold memory ownership by a write-scoping layer that was never built.
Decision 4 (#582) removed the need for it.

## Decision

Each roster agent owns a **private, role-scoped store** on a hosted
**Neon Postgres** database (ADR-0014 §3's relational default), reached over
**MCP streamable-HTTP** by every surface — one wrapper server, per-role
credentials. backlog-manager migrates first.

- **Interface: MCP, never a parallel REST API for runtimes** (#582). The
  store keeps non-MCP consumers at store level (DR dumps, `audit-memory`);
  a runtime REST API earns its place only if a hosted memory-bearing agent
  that can't speak MCP ever appears.
- **Transport: MCP-over-HTTP, unconditional.** A remote streamable-HTTP MCP
  server replaces the local reference `server-memory`. Memory wiring lives
  at config level; frontmatter wiring remains for subagent runs only.
- **Per-role ownership by construction** (supersedes ADR-0043): per-role
  stores/namespaces with per-role credentials — each token reaches only its
  own store, so read+write scoping holds structurally and the write-scoping
  enforcement layer drops out unbuilt. No shared-reference tier, no
  cross-role reads: a role needing more than its issue carries invokes
  backlog-manager in the substrate (the information broker, #545
  principle 10), not another role's store. Accepted cost: decisionless
  repo-recoverable facts the shared tier cached once now duplicate across
  every role's store — the exact duplication ADR-0043's tier existed to
  avoid, now paid for structural lane-keeping.
- **Writes: online-only, serialized at the wrapper.** The endpoint owns a
  single serialized write path (mutex/single-flight or CAS + retry — a
  named build item, since the reference implementation provides none). The
  local cache is **read-only**; offline sessions read stale memory and
  cannot write. All of #583's replay machinery — additive-subset queue,
  same-name-create merge, create-before-add ordering — is out of scope by
  construction. Offline CLI capture loss is accepted: rare surface, and the
  transcript survives to distill later.
- **Read freshness: stale-read-until-sync, accepted.** No online-freshness
  guarantee; a reconnecting session catches up then.
- **Two tiers within a store** (amends the ADR-0033 contract): episodic —
  raw conversational capture, append-only, expiring — distills into
  semantic, the curated pointer-contract moat ADR-0033 defined.
  Distillation is a cross-tier read-modify-write, so it runs under the same
  write serializer as single writes **and** as a single Postgres
  transaction — one serialized write path, distillation transactional
  within it, which is what satisfies #583's multi-tier guard.
- **Retrieval: plain Postgres substring/full-text (ILIKE or `tsvector`),
  no pgvector in v1.** ADR-0036's "substring suffices" verdict was proven
  on the curated semantic tier and is inherited only provisionally for the
  higher-volume episodic tier. Revisit trigger: retrieval demonstrably
  missing relevant facts at episodic scale — which requires the
  retrieval-observability hook (build epic) to even evaluate, since the
  #570 silent-empty-return failure is undetectable without one.
- **Bounded context:** retrieval returns a relevant slice, never load-all;
  distillation and eviction keep both tiers bounded.
- **Divergence backstop:** serialization kills write-write conflicts but
  not the silent fork — two sessions superseding one fact land divergent
  duplicates with no conflict signal (#583). Detecting divergent-duplicate
  supersession is a named `audit-memory` build requirement, not an assumed
  capability.
- **Auth:** per-role static bearer tokens over HTTPS. Local sessions vend
  theirs per ADR-0041's model; hosted headless runners get OIDC-vended
  short-lived credentials (#582 Decision 2); **cloud surfaces (web/iOS)
  carry a static per-role bearer as a plain environment variable** — the
  sandbox has no secrets store. That asymmetry is accepted and named, with
  the OAuth claude.ai-connector path (flip `disableClaudeAiConnectors`,
  build OAuth into the server) as the revisit if the posture stops holding.
- **Privacy reconciliation (the ADR-0036 relaxation, made explicit).**
  ADR-0036's guarantee was by construction: nothing memory-shaped touched a
  public surface. This design relocates private memory onto a hosted store
  guarded by secrets — a leaked role token grants full read+write of that
  role's entire private memory, exactly ADR-0036's privacy driver. The
  guarantee downgrades from structural to operational: TLS + auth on the
  endpoint, encryption at rest, role-scoped rotatable tokens, no
  cross-role escalation surface. Accepted deliberately as the price of
  multi-surface memory, not folded into "low blast radius."
- **Cost/latency kill-switch (named thresholds):** (a) usage sustainably
  exceeding Neon's free tier — a meaningful recurring compute bill, not a
  baseline storage floor (Cloud Run's scale-to-zero Artifact Registry image
  storage isn't free-tier-covered and isn't itself a trigger; see
  infra#240) — or (b) p95 session-start retrieval above 2 s sustained over
  a week, forces an explicit keep-or-migrate decision; either trips →
  fall back to local JSONL. Pre-cutover, JSONL is still the live shadow
  and rollback is one line; post-cutover — the only case either threshold
  can actually fire, both being sustained-over-a-week conditions — JSONL
  is frozen and stale by every write since cutover, so rollback instead
  needs the Postgres→JSONL reverse dump (#634 build item), not a wiring
  flip. The fallback reverts multi-surface support — an accepted
  capability regression, not a free infra swap.
- **Cloud surface prerequisites:** project-level agent-definition
  distribution (#597 — cloud loads only repo-level `.claude/agents/`), the
  endpoint's domain on the environment's egress allowlist, project
  `.mcp.json` for wiring. Headless caveats carried from #582: static
  bearer only (OAuth is interactive-only), and `openai/codex#24135` blocks
  any unattended Codex runner.

**Roster runtime homes (the ADR-0042 amendment):** backlog-manager — local
Claude Code (subagent or standalone) plus the cloud surfaces above, GitHub
as trigger only; plan-reviewer — memoryless by design (fresh-eyes edge);
implementor — interactive session today, gaining the hosted/self-driving
leg (#596/#598); code reviewer — hosted and memoryless, unchanged. Hosted
runtimes reach their own stores over HTTPS with their own tokens; #582's
findings hold the full topology table.

**Plans this ADR commits, executed elsewhere:**

- **Infra:** Neon adoption in the infra repo — provider + account +
  credential bootstrap, credential → SSM `/infra` per ADR-0016 — and an
  infra ADR superseding infra-0018: the B2 JSONL-backup model either
  re-purposes for DB-dump DR or decommissions, decided by the
  Neon-PITR-vs-B2 question in the build epic.
- **Build epic (filed separately):** online write serialization,
  `audit-memory` divergence detection, the retrieval/latency observability
  hook, pinning the MCP server version (today's wiring runs an unpinned
  `npx -y @modelcontextprotocol/server-memory`), the DR decision, and the
  migration — JSONL stays source of truth until the hosted store verifies.
  PoC boundaries declared up front.

## Alternatives considered

- **Keep the local store, sync per surface** — no sync model reaches the
  managed sandbox; web/iOS fail on reachability, not protocol. Dead by
  Decision 1's premise, and #579's bi-machine sync closed moot with it.
- **Offline writes via op-log replay or LWW** — killed by #583: every real
  conflict is an add opposite a delete on the same key, composites
  (rename, supersession) carry intent no op log represents, and LWW fails
  at every granularity, landing silent loss exactly on curation ops.
  Intent-level primitives (`rename`, `supersede`) recorded as the one path
  that would make replay viable — rejected for now, not built.
- **Additive-subset offline queue** — permitted by the evidence but buys a
  rare surface at the cost of merge rules and replay testing; online-only
  is the grilling's call.
- **pgvector now** — reintroduces the embedding dependency (cost, latency,
  re-embedding) ADR-0036 rejected, without evidence substring fails.
  Deferred behind the named revisit trigger.
- **OAuth connector now** — docs-sanctioned for interactive surfaces but
  requires building an OAuth server and flipping
  `disableClaudeAiConnectors`; deferred as the static-bearer revisit path.
- **A parallel REST API for runtimes** — both target CLIs are first-class
  streamable-HTTP MCP clients; REST would be a second contract with no
  consumer. Store-level access covers DR and audit.
- **Retain ADR-0043's shared-reference tier with write-scoping** — needs
  the identity-gated enforcement layer that was never built, and keeps the
  cross-lane read surface ADR-0042's lane-keeping argues against. Per-role
  stores make ownership structural instead.

## Consequences

Memory follows the agent to every surface; sessions become disposable
because the store, not the session, is the continuity mechanism. Lane
ownership and write scoping hold by construction — no enforcement layer,
no anti-smuggling rule, `audit-memory` refocuses on content quality plus
the new divergence detection. The cost side: a hosted dependency with named
kill-switch tripwires, privacy resting on operational controls instead of
construction, decisionless facts duplicated per role, and cross-role
information paying a substrate round-trip through backlog-manager.

Until the build epic delivers, nothing changes at runtime: the local JSONL
store remains authoritative, and this ADR is the design of record for what
replaces it.

Revisit if: retrieval misses at episodic scale (pgvector trigger), the
static-bearer posture stops holding (OAuth connector trigger), a kill-switch
threshold trips (local-JSONL fallback), or a hosted memory-bearing agent
that can't speak MCP appears (the REST revisit).
