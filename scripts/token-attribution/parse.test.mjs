// Unit tests for the pure transcript-attribution logic, run with Node's
// built-in test runner (no dependency, no package.json needed):
//   node --test scripts/token-attribution/*.test.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { dedupeMessages, activitySplit, issueFromBranch, issueRollup, buildReport } from "./parse.mjs";

const FIXTURES_DIR = join(dirname(fileURLToPath(import.meta.url)), "fixtures");

function loadFixture(name) {
  return readFileSync(join(FIXTURES_DIR, name), "utf8")
    .split("\n")
    .filter((line) => line.trim())
    .map((line) => JSON.parse(line));
}

test("dedupeMessages collapses per-block lines into one message per id", () => {
  const records = loadFixture("transcript-2.1.212.jsonl");
  const messages = dedupeMessages(records);
  assert.equal(messages.length, 2);
  const first = messages.find((m) => m.id === "msg_fixture001");
  assert.ok(first.weights.thinking > 0);
  assert.ok(first.weights.text > first.weights.thinking, "the longer text block should carry more weight");
});

test("activitySplit doesn't double-count output tokens across duplicate lines", () => {
  const messages = dedupeMessages(loadFixture("transcript-2.1.212.jsonl"));
  const totals = activitySplit(messages);
  // msg_fixture001 contributes 40 output tokens once (not once per block
  // line); msg_fixture002 contributes 10 via the unrecognized-block fallback.
  assert.equal(totals.thinking + totals.text + totals.tool_use, 50);
  assert.equal(totals.cache_read, 950);
});

test("activitySplit falls back to `text` when no recognized block carries the output", () => {
  const totals = activitySplit(
    dedupeMessages([
      {
        type: "assistant",
        message: { id: "m1", content: [{ type: "redacted_thinking" }], usage: { output_tokens: 10, cache_read_input_tokens: 0 } },
      },
    ]),
  );
  assert.equal(totals.text, 10);
  assert.equal(totals.thinking, 0);
});

test("issueFromBranch matches this repo's issue-NNN/fix-NNN convention, not feature branches", () => {
  assert.equal(issueFromBranch("issue-517-token-parser"), 517);
  assert.equal(issueFromBranch("fix-42"), 42);
  assert.equal(issueFromBranch("feat/inline-fill-remaining-probes"), null);
  assert.equal(issueFromBranch("main"), null);
  assert.equal(issueFromBranch(null), null);
});

test("issueRollup buckets by issue where the branch matches, else by raw branch name", () => {
  const messages = dedupeMessages(loadFixture("transcript-2.1.212.jsonl"));
  const rollup = issueRollup(messages);
  const issue517 = rollup.find((r) => r.issue === 517);
  const mainBucket = rollup.find((r) => r.branch === "main");
  assert.equal(issue517.output_tokens, 40);
  assert.equal(mainBucket.issue, null);
  assert.equal(mainBucket.output_tokens, 10);
});

test("buildReport tolerates unrelated record types and unknown/added fields without crashing (pinned 2.1.212 fixture)", () => {
  const report = buildReport(loadFixture("transcript-2.1.212.jsonl"));
  assert.equal(report.message_count, 2);
  assert.equal(report.activity.thinking + report.activity.text + report.activity.tool_use, 50);
  assert.equal(report.by_issue.length, 2);
});

test("buildReport tolerates a record with no message.content at all", () => {
  const report = buildReport([{ type: "assistant", message: { id: "m1", usage: { output_tokens: 5 } } }]);
  assert.equal(report.message_count, 1);
  assert.equal(report.activity.text, 5);
});
