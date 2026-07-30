---
name: grilling
description: >-
  Extracts decisions one at a time before committing to a plan, instead of guessing a batch of
  assumptions. Looks up anything discoverable in the environment itself rather than asking; puts
  each real decision to the human as a single question with a recommended answer, and doesn't act
  until it's confirmed. Use when scope, structure, or approach is genuinely undecided and guessing
  would waste a round — shaping a new epic, splitting an overgrown issue, defining a spike's
  question and deliverable, weighing a spike's verdict, or pre-gating an issue with thin
  acceptance criteria. Not for routine, already-clear work.
---

# Grilling

A protocol for extracting decisions, not a form to fill out. The failure mode this replaces:
guessing a batch of assumptions up front and burning a round when one is wrong.

## Rules

1. **Look it up before you ask.** Anything discoverable from the environment — an existing file,
   a label taxonomy, a past decision in memory, prior art in the repo — isn't a question. Read it.
2. **One question at a time.** Ask, wait, incorporate the answer, ask the next. Never a numbered
   batch of unrelated questions in one message — each answer can change what's worth asking next.
3. **Every question carries a recommendation.** State the decision, your recommended answer, and
   why in one or two sentences. The human is confirming or redirecting a specific call, not
   opening a blank design discussion.
4. **Don't act until confirmed.** No drafting the epic body, splitting the issue, or writing the
   plan ahead of the answer — grilling ends when the open decisions run out, not when you get
   tired of asking.

## When to stop

Once every genuinely open decision has an answer, the interview is done — hand off to whatever
comes next (drafting the epic, writing the split, defining the spike). Don't manufacture more
questions once nothing is actually undecided.
