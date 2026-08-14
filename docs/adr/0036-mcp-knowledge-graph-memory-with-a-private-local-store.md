# 36. MCP knowledge-graph memory with a private local store

Date: 2026-08-10

## Status

Accepted

Supercedes [27. Scoped PR-based self-commit for backlog-manager memory](0027-scoped-pr-based-self-commit-for-backlog-manager-memory.md)

Supercedes [32. Rolling draft PR for backlog-manager memory sync](0032-rolling-draft-pr-for-backlog-manager-memory-sync.md)

Supercedes [33. Memory is a pointer layer — the content contract](0033-memory-is-a-pointer-layer-the-content-contract.md)

Shared-write clause amended 2026-08-14 by [ADR-0043](0043-per-role-memory-write-ownership-amending-the-adr-0036-shared-write-clause.md).

## Context

Backlog-manager's memory is committed markdown in every repo's
`.claude/agent-memory/backlog-manager/`, synced through `git memory-pr`'s
rolling draft PR (ADR-0027/0032) under ADR-0033's content contract. Two
problems forced a redesign (#527, decisions grilled 2026-08-09):

- **Privacy.** The repos are public, so the memory — including how the
  maintainer works with the agent — is world-readable.
- **Mechanics.** Background sessions can't write the memory dir under
  worktree isolation (hit twice in one session), and sync timing is
  invisible to the human.

A gitignore alone would fix privacy, so the ambition is explicit: gain a
runtime-queryable memory capability and hands-on MCP experience, not just
move the files.

The spike's POC (#527, PR #541) drove the reference MCP memory server
(`@modelcontextprotocol/server-memory` 0.6.3) over stdio JSON-RPC: typed
entities, relations, `search_nodes`/`open_nodes` runtime queries,
incremental `add_observations`/`delete_observations`, and persistence
across server restarts all verified against a local JSONL store. Every
write flushes to disk immediately — auto-persist is the server's native
behavior, not something added.

## Decision

Replace committed-markdown memory with the reference MCP memory server
backed by a machine-global private JSONL store, wired inline in the
agent's frontmatter. Backlog-manager is the guinea pig; rollout is the
build epic's job (#542).

- **Server**: `@modelcontextprotocol/server-memory` via `npx`, declared in
  `mcpServers:` frontmatter of `claude/agents/backlog-manager.md` — inline
  so it rides the agent everywhere it runs (subagent or `claude --agent`),
  with no per-repo `.mcp.json`.
- **Store**: `~/.claude/agent-memory-mcp/backlog-manager.jsonl`. Outside
  every repo, so private by construction; `~/.claude` is already the
  sanctioned `$HOME` exception. Human-readable JSONL — greppable, and the
  future backup client ships one file to infra's R2 bucket (infra#159).
- **Auto-persist, no review gate.** Writes land immediately; `git
memory-pr`'s draft-PR checkpoint retires with the mechanism. The
  checkpoint guarded a _public commit_ (secrets, regressions); a private
  local store removes the exposure the review existed for. Nothing reviews
  memory content anymore — accepted deliberately, with `audit-memory`
  generalization to the new store as epic work.
- **ADR-0033's content contract survives translated**, enforcement staying
  instruction as it always was: the four frontmatter types map verbatim to
  `entityType`; each observation stays a one-line pointer-shaped fact
  ("decision — see repo#N"), never restated issue status.
- **Residency retires.** ADR-0033's per-repo residency existed because only
  the invoking repo's store auto-loads and stores were committed per repo.
  A single machine-global, queryable graph removes the asymmetry: repo
  scoping becomes `repo-map` entities plus relations from facts to their
  repo (POC-validated), and the `map_<repo>.md` files retire.
- **Recall becomes pull, not push.** No `MEMORY.md` auto-load; the agent
  queries at session start: `search_nodes` with short keywords — the
  reference server AND-matches literal substrings, so a natural-language
  query silently returns empty even when matching data exists (#570) —
  and falls back to `read_graph` when a scoped query returns empty.
  Named trade: a session that skips the query starts colder than
  auto-load ever let it.
- **Transition is a parallel run.** The trial instructions sit alongside
  the committed-file flow, which stays authoritative until the build epic
  cuts over (rollout to the other memory-bearing surfaces, R2 backup
  client, retire `git memory-pr` and `memory: project`, #528's cleanup of
  the already-public files).

ADR-0009's backlog-manager charter stands untouched — only its memory
mechanism is superseded through this chain.

## Alternatives considered

- **Gitignored local markdown** (platform-native `memory: local`) — fixes
  privacy in one line, but no runtime queries and no MCP capability; the
  grilling explicitly chose the ambitious path. Recorded as the fallback
  if the MCP model disappoints in the trial.
- **A SQLite-backed community server** (doobidoo/mcp-memory-service) —
  rejected: a Python service with ONNX embeddings, memory-consolidation
  daemons, and OAuth is the opposite of Simplicity First; semantic search
  buys nothing at hundreds-of-facts scale where substring search already
  hits.
- **basic-memory** (markdown-first, SQLite index) — closest to today's
  model and human-editable, but a heavier install with its own sync
  semantics; the point was to leave the file-sync model, not rebuild it
  under MCP.
- **A thin custom server** — could enforce ADR-0033's contract in code
  instead of instruction, but is new code to own; the reference server
  already models types, pointers, and repo scoping adequately. Revisit if
  the trial shows contract drift that instruction can't hold.
- **A private git repo as the store** — paid rulesets for branch
  protection, and all the sync mechanics this decision retires.

## Consequences

Privacy holds by construction, not discipline — nothing memory-shaped
touches a public repo. The worktree-isolation write failures and invisible
sync timing disappear with `git memory-pr`. Memory becomes queryable at
runtime (short-keyword `search_nodes`, not natural-language questions —
those silently match nothing, #570), and the store stays a single
human-readable file.

The human review checkpoint is gone; content quality now rides on the
translated ADR-0033 contract plus a future `audit-memory` pass over the
graph. The store is single-machine — cross-machine sync is accepted lost
(#527's grilling), with the R2 backup as disaster recovery, not sync.
`npx -y` fetches the server on a cold cache, so a fresh machine needs
network before first memory access.

Verify at rollout: `${HOME}` expansion inside frontmatter `mcpServers.env`
— documented for `.mcp.json`, unconfirmed for inline agent definitions; if
it doesn't expand, the server falls back to a store relative to its own
install dir and the fix is an absolute path or a wrapper script.

Revisit if: the trial shows sessions repeatedly re-deriving what a pointer
entry should have held (the contract's lesson clause should widen — the
same trigger ADR-0033 carried), the graph grows past what substring search
serves, or a second machine enters daily use and backup-as-sync pressure
appears.
