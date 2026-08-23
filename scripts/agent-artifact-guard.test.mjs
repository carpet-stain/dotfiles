// Unit tests for the pure, no-I/O half of agent-artifact-guard.mjs, run with
// Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/*.test.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import { detectArtifactMismatch } from "./agent-artifact-guard.mjs";

test("detectArtifactMismatch flags a backlog-manager response carrying plan-reviewer's Verdict: line", () => {
  const response = "## Plan-review round 2 — verdict: **REVISE** (plan-reviewer, independent)\n\nFindings...";
  const result = detectArtifactMismatch("backlog-manager", response);
  assert.equal(result.mismatched, true);
  assert.match(result.reason, /Verdict/);
});

test("detectArtifactMismatch matches a plain '**Verdict:**' line too, not just a heading", () => {
  const response = "**Verdict:** ship\n\nNothing blocking.";
  const result = detectArtifactMismatch("backlog-manager", response);
  assert.equal(result.mismatched, true);
});

test("detectArtifactMismatch passes a backlog-manager response with no verdict line", () => {
  const response = "# Plan draft\n\nRevised approach: do X, then Y.";
  const result = detectArtifactMismatch("backlog-manager", response);
  assert.equal(result.mismatched, false);
});

test("detectArtifactMismatch never flags plan-reviewer's own Verdict: line — that's its documented artifact", () => {
  const response = "**Verdict:** fix-then-ship\n\nOne blocking finding...";
  const result = detectArtifactMismatch("plan-reviewer", response);
  assert.equal(result.mismatched, false);
});
