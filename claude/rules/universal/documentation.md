> ### GATE — applies always
>
> Applies everywhere; no placeholders, nothing to distill. Do NOT copy into repos.
> A repo's own docs bind the specifics (where ADRs live, its templates); this is the source.

# Documentation

## Documentation Is Part Of The Change

Update docs when behavior or architecture changes. Before a structural change, read the recorded
decisions and stay consistent; if one must change, supersede it explicitly rather than letting code
and intent drift. For a repo with real multi-session or multi-contributor handoff, keep a committed
status/next-task file current — a judgment call, not a mandate.

A major, cross-cutting, or expensive-to-reverse decision is _recorded_ in an ADR — the decision plus
what was considered and rejected, not just the outcome — so it stays walkable later instead of an
excavation of closed issues/PRs. The repo binds where the ADR lives and its exact template; this only
says the artifact belongs somewhere durable, not buried in ephemeral history.

## One home per fact, everything else points

Each kind of documentation owns one job. A fact lives in exactly one of these; everywhere else points
at it instead of restating it:

| Artifact                  | Owns                                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------------------- |
| Issue / tracker           | The problem, design exploration, spikes, acceptance — the plan, around the work.                  |
| PR / MR                   | The real-time journal: decisions, gotchas, retractions, forks as they happen.                     |
| ADR                       | The durable record of a major decision: what was chosen, what was rejected, why.                  |
| Agent guide (`AGENTS.md`) | How to work here; points at ADRs for the why instead of re-arguing it.                            |
| README                    | What this is, install, use — the front door for a human reader.                                   |
| Interface / API contract  | The consumption contract — inputs, outputs, types, behavior — in the code's types and docstrings. |
| Code comments             | The tripwire why at the point of edit, plus a pointer if more context exists.                     |
| Configs                   | The enforced spec — self-speaking; docs point at the config, not restate it.                      |

A generated interface spec (e.g. `openapi.json`) is a derived artifact of the code's contract —
regenerated from it, never a second hand-edited home.

Once a decision has an ADR, later docs cite it (`see ADR-0003`) rather than re-explaining it — and
never point back the other way (an ADR never says "see the AGENTS.md section for why"; that's the
circular-pointer trap). Cover every fact's home in as few words as it takes; over-documenting beats
leaving a decision unrecorded, but don't let restatement creep back in.
