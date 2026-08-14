# 45. Inline command fill network-context exfil policy

Date: 2026-08-14

## Status

Accepted

## Context

`_ai-fill` (#555, epic #557) sends part of the interactive shell's state — the command buffer —
to a third-party LLM API (OpenRouter, via `aichat`) on a manual trigger (Alt+I). That's new
exfil surface this repo didn't have before: #511's floating pane only ever sent what the user
typed into a REPL prompt, a request the user composed on purpose. `_ai-fill` sends the buffer
whether or not the user meant every character of it to leave the machine — a half-typed command
might contain a path, a hostname, a flag value copy-pasted from somewhere else. Phase 2 (#556)
plans to add read-only probe output (branch names, container/pod names, `gh` issue titles) to
the same request, widening the surface further. Both need one stated policy, decided once, so
"is this probe's output OK to send" has an answer instead of a per-tool re-litigation.

The `architecture` label requires an ADR for #555 specifically because this is the load-bearing
precedent: whatever this ADR accepts, #556 and any later AI-shell feature inherit without
re-deciding it.

## Decision

**What may leave the machine on an Alt+I trigger: the current command buffer, verbatim, and
nothing else.** No shell history, no `$PWD` contents, no environment variables, no file
contents. Phase 2's probes (#556) extend this under the same rule: a probe's output joins the
request only when it's read-only, bounded, and materially improves the specific completion it's
scoped to — "one row in the probe map" is a widening of _what_ gets sent, not a loosening of
_how much_ judgment gates it.

**Trigger is manual, not ambient.** Alt+I sends one request per keypress; nothing runs on a
timer, on every keystroke, or in the background. The user controls exactly when the buffer's
current contents leave the machine, and can see what's in the buffer before pressing the key —
this is the whole reason the epic exists instead of reviving IRIS's per-keystroke ambient
version (#399).

**Destination is the credential path #511 already established**, not a new one: OpenRouter,
via the same Keychain item (`openrouter-api-key`, `scripts/aichat-pane.sh`'s resolution order,
documented in AGENTS.md's Credentials section). No new API key, no new vendor, no new trust
boundary — `_ai-fill` is a second caller of an already-accepted destination.

**Output never auto-executes.** `_ai-fill` only ever replaces `BUFFER`; nothing it receives back
runs without the user separately pressing Enter. This bounds the blast radius of a compromised
or hallucinating response to "wrong text in the prompt," not "a command ran."

## Alternatives considered

- **No exfil policy — trust the per-feature review each time.** Rejected: #556 alone proposes
  five probes across five tools; deciding each one's acceptability from scratch invites
  inconsistent judgment calls and a probe that quietly ships something it shouldn't (e.g. `git
log` output beyond the last few subjects, or full `env`).
- **Send full context by default (cwd listing, recent history, `git status`) for better
  completions.** Rejected: the value has to be earned per probe, not assumed — #556's own text
  says "each probe must earn its place... many intents need none." Sending everything by default
  makes every buffer's contents (and, once probes land, every git branch, container name, and
  open PR title) leave the machine whether the completion needed it or not.
- **A separate, phase-1-only OpenRouter key or app registration**, to scope phase 1's blast
  radius independently of #511's pane. Rejected: same trust class, same machine, same user —
  a second credential to rotate and document for no isolation benefit, since both call paths
  already share the "routine-tier, `-A` Keychain read" trust level AGENTS.md assigns the existing
  key.

## Consequences

Phase 2 (#556) doesn't re-litigate what's acceptable to send — it cites this ADR and asks only
"does this probe's output earn its place," per row. Any later AI-shell feature (a new widget, a
new probe, a different trigger) answers the same question against the same three rules: buffer
plus earned probe output only, manual trigger only, no new destination without updating this
ADR.

The cost is that a probe proposal now needs an explicit justification, not just an implementation
— slower to add a tool row, but the alternative (silently expanding what leaves the machine) is
the outcome this ADR exists to prevent.

Revisit if a future feature needs an ambient (non-manual) trigger, a genuinely new LLM
destination, or a probe whose value can't be justified read-only/bounded/scoped under this
policy — any of those is a new decision, not a straightforward extension of this one.
