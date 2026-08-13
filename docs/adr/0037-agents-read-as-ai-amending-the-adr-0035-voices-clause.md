# 37. Agents read as AI, amending the ADR-0035 voices clause

Date: 2026-08-13

## Status

Accepted

Amends ADR-0035's "voices are corpus-seeded" clause only; ADR-0035 stays Accepted.

## Context

ADR-0035 splits GitHub-facing content by ownership: deliberation posts under named agent
identities, shipped work stays the maintainer's. Its voices clause then seeds each agent a
corpus-based voice by `voice.md`'s method — distilled from real output so the prose reads as a
person's. That is the identity laundering ADR-0035 itself fixed at the attribution layer,
recreated one layer up: `author = agent` is honest blame, but `voice = human-corpus` is
dishonest prose. An agent's writing should read as what it is (#548).

## Decision

Agents read as AI. The corpus-distillation method is struck: no agent gets a seeded personal
voice, and `voice.md` narrows to shipped work posted under the maintainer's own identity (its
header carries the applicability test). Tone stays managed by a floor, not a persona:
`communication.md`'s always-loaded baseline — clarity, terseness, the anti-slop rules — now
explicitly owns agent GitHub prose. Honest AI is not sloppy AI; spike #474's anti-slop work
applies to agent prose as much as the maintainer's.

Kept from the amended clause: differentiation by **role posture** — verdict-first adversarial
(plan-reviewer) vs problem/acceptance-first PM (backlog-manager) — which ADR-0035 already named
as the real differentiator. Each agent definition states its posture in one line; no new rules
file.

## Alternatives considered

- **Keep the corpus-seeded voices** — the prose keeps masquerading as a person's; rejected as
  the same dishonesty the named identities were built to remove.
- **A new shared `lexicon.md`** — the floor already lives always-loaded in `communication.md`
  and the posture already lives in each agent definition; a third file restates both homes.
- **Supersede ADR-0035** — wrong relation: the named-identities decision is live; superseding
  marks it dead. A clause amendment keeps the rest standing.
- **No managed tone at all** — reverts the anti-slop floor along with the personas; the floor
  was never the dishonest part.

This also neutralizes ADR-0035's "attribution without voices → sock puppets" rejected
alternative: agents that read as AI don't puppet a person, so accounts without human voices no
longer read as three flavors of the same writer.

## Consequences

Deliberation threads read as AI participants with distinct role postures, the maintainer
deciding. Two fewer voice specs to maintain; `voice.md` has one unambiguous scope. #540's
Phase-1 voice-distillation tasks are struck and replaced by the role-posture lines. Revisit
only if a posture line proves too thin to keep agent output distinguishable in practice.
