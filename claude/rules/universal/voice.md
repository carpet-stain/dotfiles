<!-- Universal voice. Canonical source: my dotfiles. Loaded globally.
     Maintainer output only: how shipped work posted under his own GitHub identity sounds.
     Agent-voiced output and in-session dialog follow communication.md's baseline instead. -->

> ### GATE — applies always
>
> Applies everywhere; no placeholders, nothing to distill. Do NOT copy into repos.
> Always loaded — the maintainer-only narrowing below is a content-scope test, not a load gate.

# Voice

Applicability test: **does this text ship as work posted under the maintainer's own identity?**
If yes — his commits, PRs, issues, comments — this file governs how it sounds: to everyone
else it reads as if he'd typed it, so it sounds like him. If it posts as an agent, or it's
in-session dialog, this file does not apply — `communication.md`'s baseline does; agents read
as AI, never as him. The git author field is orthogonal: author is mechanical blame, voice is
the owner's narrative — a commit authored by the implementor identity still ships as his work
and sounds like him (ADR-0038). Seeded 2026-07-31 from his own prompts across this repo's
session transcripts (spike #474) — corpus is his messages only, never agent drafts.

## Traits

- **Leads with the point, no throat-clearing.** States the thing first; skips "I wanted to reach
  out" or "just a heads up" openers.
- **First person, unhedged.** "I think," "I don't think," "I don't foresee" — stated as a
  position, not softened into "it might be worth considering."
- **"Let's X" over "we should consider X."** Decisions and proposals read as an imperative
  invitation, not a tentative suggestion.
- **Trailing tag questions for confirmation.** "...no?", "...right?" appended to a stated
  position, instead of a standalone "Do you think that makes sense?"
- **Flat acknowledgments.** "yes.", "merged.", "done, what's next" — no pleasantries padding a
  status update.
- **Judgments stated plainly.** "I like it, ship it." / "this is getting out of hand" — evaluative
  and unhedged, not wrapped in "I think perhaps this could potentially..."
- **Names the specific thing.** The tool, the file, the issue number — never a generic stand-in
  ("this change," "the relevant module") when the concrete noun is one word longer.

Match the structure and directness above, not the typing shortcuts — real prompts run terser and
looser (typos, dropped articles) than anything that should ship in an issue or PR; GitHub-facing
text still has to be spelled and read correctly.

## Before / after

### PR description

> Before: This PR introduces a comprehensive set of improvements to the authentication flow,
> delving into token refresh handling while ensuring backward compatibility is seamlessly
> maintained throughout.

> After: Refactors token refresh in the auth flow. No API changes — old tokens still work.

### Code comment

Verbatim from a real PR the maintainer flagged as over-written:

Before:

```hcl
# Installs the App on every managed repo — the same for_each-over-the-map
# shape main.tf's other per-repo resources already use (github_repository.this,
# github_issue_label.this). A new local.repos entry gets the App installed
# on its next apply, no manual step.
#
# Not compatible with app_auth provider authentication (the resource's own
# docs say so explicitly — managing an installation's own membership can't
# be done with that installation's own token). Runs under the elevated
# session, same as every other Administration-scope apply.
```

After:

```hcl
# for_each over local.repos, same shape as the other per-repo resources.
# Needs the elevated session — app_auth can't manage its own installation.
```

### Status update

> Before: I have successfully completed the implementation, verified that all tests pass, and
> pushed the changes to the remote branch for your review.

> After: Done. Pushed, tests pass — ready for review.

### Proposing a decision

Grounded in a real prompt from the shaping conversation for this file:

> Before: Would it make sense to consider deprioritizing the timebox metric, given the increased
> efficiency AI-assisted research now provides?

> After: I don't think we should care about timebox anymore — AI does research-heavy work in
> under 30 minutes now. Track tokens instead.

### Declining or closing something

> Before: After careful consideration, it has been determined that this issue is no longer
> necessary and can be safely closed.

> After: No need, close it.

## Live capture

A wording correction or a distinctive phrasing from him, mid-session, is a voice sample —
capture it as a feedback memory tagged `voice` the moment it happens, same as any other
correction. Periodically fold durable, repeated patterns from those memories into the Before/after
list above; a one-off tweak isn't durable, don't graduate it. No recurring batch sweep beyond
that — transcript mining was the one-time seed, this is the sustaining loop.
