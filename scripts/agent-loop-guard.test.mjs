// Unit tests for the pure, no-I/O half of agent-loop-guard.mjs, run with
// Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/*.test.mjs
//
// The I/O half (timeline fetch, $GITHUB_OUTPUT) can only really prove out on
// a live Actions run, per this repo's AGENTS.md verification guidance — same
// split as scripts/pr-review's build-review.test.mjs.

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  parseRoutingConfig,
  machineLogin,
  resolveRoute,
  findRoute,
  countTurnSignalRounds,
  evaluateGuard,
} from "./agent-loop-guard.mjs";

const ROUTING_YAML = `# comment line, ignored
turn_signal_label: awaiting-plan-critique
round_cap: 3

routes:
  - event: issues
    action: labeled
    label: needs-plan-review
    role: backlog-manager
    max_turns: 12
  - event: issues
    action: labeled
    label: awaiting-plan-critique
    role: plan-reviewer
    max_turns: 24
  - event: issues
    action: unlabeled
    label: awaiting-plan-critique
    role: backlog-manager
    max_turns: 12
`;

test("parseRoutingConfig reads top-level scalars and the routes list", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  assert.equal(routing.turn_signal_label, "awaiting-plan-critique");
  assert.equal(routing.round_cap, 3);
  assert.equal(routing.routes.length, 3);
  assert.deepEqual(routing.routes[0], {
    event: "issues",
    action: "labeled",
    label: "needs-plan-review",
    role: "backlog-manager",
    max_turns: 12,
  });
});

test("findRoute returns the full matching route, including its own max_turns", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  assert.deepEqual(
    findRoute(routing, { eventType: "issues", eventAction: "labeled", label: "awaiting-plan-critique" }),
    {
      event: "issues",
      action: "labeled",
      label: "awaiting-plan-critique",
      role: "plan-reviewer",
      max_turns: 24,
    },
  );
  assert.equal(
    findRoute(routing, { eventType: "issue_comment", eventAction: "created", label: "" }),
    null,
  );
});

test("machineLogin derives the machine-user login from the role name", () => {
  assert.equal(machineLogin("plan-reviewer"), "carpet-stain-plan-reviewer");
  assert.equal(machineLogin("backlog-manager"), "carpet-stain-backlog-manager");
});

test("resolveRoute matches the first route for a mapped event", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  assert.equal(
    resolveRoute(routing, { eventType: "issues", eventAction: "labeled", label: "needs-plan-review" }),
    "backlog-manager",
  );
  assert.equal(
    resolveRoute(routing, { eventType: "issues", eventAction: "labeled", label: "awaiting-plan-critique" }),
    "plan-reviewer",
  );
});

test("resolveRoute returns null for an unmapped event (e.g. a plain human comment)", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  assert.equal(
    resolveRoute(routing, { eventType: "issue_comment", eventAction: "created", label: "" }),
    null,
  );
});

test("countTurnSignalRounds counts label-add events only, not comments or removals", () => {
  const timeline = [
    { event: "labeled", label: { name: "awaiting-plan-critique" } },
    { event: "commented" },
    { event: "unlabeled", label: { name: "awaiting-plan-critique" } },
    { event: "labeled", label: { name: "needs-plan-review" } },
    { event: "labeled", label: { name: "awaiting-plan-critique" } },
  ];
  assert.equal(countTurnSignalRounds(timeline, "awaiting-plan-critique"), 2);
});

test("evaluateGuard spawns the routed role on a fresh gate-open event", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  const decision = evaluateGuard({
    routing,
    event: { eventType: "issues", eventAction: "labeled", label: "needs-plan-review", actorLogin: "carpet-stain" },
    roundCount: 0,
  });
  assert.equal(decision.spawn, true);
  assert.equal(decision.role, "backlog-manager");
  assert.equal(decision.maxTurns, 12);
});

test("evaluateGuard surfaces the spawned role's own max_turns, not a flat value", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  const decision = evaluateGuard({
    routing,
    event: { eventType: "issues", eventAction: "labeled", label: "awaiting-plan-critique", actorLogin: "carpet-stain-backlog-manager" },
    roundCount: 1,
  });
  assert.equal(decision.spawn, true);
  assert.equal(decision.role, "plan-reviewer");
  assert.equal(decision.maxTurns, 24);
});

test("evaluateGuard filters an event authored by the role it would spawn (self-spawn recursion)", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  const decision = evaluateGuard({
    routing,
    event: {
      eventType: "issues",
      eventAction: "unlabeled",
      label: "awaiting-plan-critique",
      actorLogin: "carpet-stain-backlog-manager",
    },
    roundCount: 1,
  });
  assert.equal(decision.spawn, false);
  assert.match(decision.reason, /self-spawn recursion/);
});

test("evaluateGuard does NOT filter the reviewer's turn-ending event even though a machine user authored it upstream (F1: scoped to the spawned role, not a blanket drop)", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  // The runner itself flips the label (actor is the workflow's own token
  // identity, never a machine-user login) — this is the realistic actor for
  // a turn-signal event, exercised here as the general non-self case.
  const decision = evaluateGuard({
    routing,
    event: {
      eventType: "issues",
      eventAction: "unlabeled",
      label: "awaiting-plan-critique",
      actorLogin: "github-actions[bot]",
    },
    roundCount: 1,
  });
  assert.equal(decision.spawn, true);
  assert.equal(decision.role, "backlog-manager");
});

test("evaluateGuard trips the round cap pre-spawn once round_cap is exceeded", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  const decision = evaluateGuard({
    routing,
    event: {
      eventType: "issues",
      eventAction: "labeled",
      label: "awaiting-plan-critique",
      actorLogin: "github-actions[bot]",
    },
    roundCount: 4, // round_cap is 3
  });
  assert.equal(decision.spawn, false);
  assert.match(decision.reason, /round cap tripped/);
});

test("evaluateGuard allows exactly round_cap rounds through", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  const decision = evaluateGuard({
    routing,
    event: {
      eventType: "issues",
      eventAction: "labeled",
      label: "awaiting-plan-critique",
      actorLogin: "github-actions[bot]",
    },
    roundCount: 3, // round_cap is 3 — the third round still runs
  });
  assert.equal(decision.spawn, true);
});

test("evaluateGuard returns no spawn for an event with no route", () => {
  const routing = parseRoutingConfig(ROUTING_YAML);
  const decision = evaluateGuard({
    routing,
    event: { eventType: "issue_comment", eventAction: "created", label: "", actorLogin: "carpet-stain" },
    roundCount: 0,
  });
  assert.equal(decision.spawn, false);
  assert.equal(decision.role, null);
});
