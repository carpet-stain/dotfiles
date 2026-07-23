// Unit tests for the pure diff-parsing / review-building logic, run with
// Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/pr-review/*.test.mjs
//
// This is the isolation-testable half of the DIY PR reviewer (#330) — the
// I/O half (run.mjs: real GitHub/OpenAI calls) can only really prove out
// on a live PR run, per this repo's AGENTS.md verification guidance.

import { test } from "node:test";
import assert from "node:assert/strict";
import { parsePatch } from "./diff.mjs";
import { parseFiles, buildPrompt, buildReviewComments, MAX_PROMPT_CHARS } from "./build-review.mjs";

const SAMPLE_PATCH = [
  "@@ -10,3 +10,4 @@ function greet() {",
  " function greet() {",
  "-  console.log('hi')",
  "+  console.log('hello')",
  "+  return true",
  " }",
].join("\n");

test("parsePatch maps RIGHT-side line numbers, skips removed lines", () => {
  const lines = parsePatch(SAMPLE_PATCH);
  assert.equal(lines.get(10), "function greet() {");
  assert.equal(lines.get(11), "  console.log('hello')");
  assert.equal(lines.get(12), "  return true");
  assert.equal(lines.get(13), "}");
  assert.equal(lines.size, 4);
});

test("parsePatch returns an empty map for a binary/no-patch file", () => {
  assert.equal(parsePatch(undefined).size, 0);
  assert.equal(parsePatch("").size, 0);
});

test("parsePatch keeps line numbers in sync across a blank context line", () => {
  // A blank unchanged line is a bare " " (leading-space marker) in a unified
  // diff — it must map to its line number and advance the counter, or every
  // later anchor desyncs.
  const patch = ["@@ -1,4 +1,4 @@", " first", " ", "-old", "+new"].join("\n");
  const lines = parsePatch(patch);
  assert.equal(lines.get(1), "first");
  assert.equal(lines.get(2), ""); // blank context line, still counted
  assert.equal(lines.get(3), "new"); // stays line 3, not shifted to 2
  assert.equal(lines.size, 3);
});

test("parsePatch handles multiple hunks in one file", () => {
  const patch = ["@@ -1,2 +1,2 @@", " a", "+b", "@@ -10,2 +20,2 @@", " x", "+y"].join("\n");
  const lines = parsePatch(patch);
  assert.equal(lines.get(1), "a");
  assert.equal(lines.get(2), "b");
  assert.equal(lines.get(20), "x");
  assert.equal(lines.get(21), "y");
  assert.equal(lines.size, 4);
});

test("parseFiles drops binary/no-patch files", () => {
  const files = [
    { filename: "a.ts", patch: SAMPLE_PATCH },
    { filename: "b.png", patch: undefined },
  ];
  const parsed = parseFiles(files);
  assert.equal(parsed.length, 1);
  assert.equal(parsed[0].filename, "a.ts");
});

test("buildPrompt renders annotated line numbers per file", () => {
  const parsed = parseFiles([{ filename: "a.ts", patch: SAMPLE_PATCH }]);
  const prompt = buildPrompt(parsed);
  assert.match(prompt, /File: a\.ts/);
  assert.match(prompt, /11:   console\.log\('hello'\)/);
});

test("buildPrompt still includes a truncated slice when the first file alone exceeds the cap", () => {
  // A single file bigger than the whole budget must be reviewed partially,
  // not skipped into an empty prompt (which would silently review nothing).
  const lines = new Map();
  const lineLen = 40;
  for (let i = 1; i <= Math.ceil((MAX_PROMPT_CHARS * 2) / lineLen); i++) {
    lines.set(i, "x".repeat(lineLen));
  }
  const prompt = buildPrompt([{ filename: "big.ts", lines }]);
  assert.ok(prompt.length > 0, "prompt must not be empty");
  assert.match(prompt, /File: big\.ts/);
  assert.match(prompt, /\[truncated/);
});

test("buildReviewComments keeps findings anchored to real diff lines, drops hallucinated ones", () => {
  const parsed = parseFiles([{ filename: "a.ts", patch: SAMPLE_PATCH }]);
  const findings = [
    {
      file: "a.ts",
      line: 11,
      severity: "nit",
      comment: "use a template literal here",
      suggestion: "  console.log(`hello`)",
    },
    { file: "a.ts", line: 999, severity: "blocking", comment: "hallucinated line", suggestion: null },
    { file: "missing.ts", line: 1, severity: "nit", comment: "hallucinated file", suggestion: null },
  ];
  const { comments, dropped } = buildReviewComments(parsed, findings);
  assert.equal(comments.length, 1);
  assert.equal(dropped, 2);
  assert.equal(comments[0].path, "a.ts");
  assert.equal(comments[0].line, 11);
  assert.equal(comments[0].side, "RIGHT");
  assert.match(comments[0].body, /```suggestion\n {2}console\.log\(`hello`\)\n```/);
});

test("buildReviewComments sorts blocking before nit before pre-existing", () => {
  const parsed = parseFiles([{ filename: "a.ts", patch: SAMPLE_PATCH }]);
  const findings = [
    { file: "a.ts", line: 10, severity: "nit", comment: "n", suggestion: null },
    { file: "a.ts", line: 11, severity: "blocking", comment: "b", suggestion: null },
    { file: "a.ts", line: 12, severity: "pre-existing", comment: "p", suggestion: null },
  ];
  const { comments } = buildReviewComments(parsed, findings);
  assert.deepEqual(
    comments.map((c) => c.line),
    [11, 10, 12],
  );
});

test("buildReviewComments drops a finding with an unknown severity", () => {
  const parsed = parseFiles([{ filename: "a.ts", patch: SAMPLE_PATCH }]);
  const findings = [{ file: "a.ts", line: 10, severity: "catastrophic", comment: "x", suggestion: null }];
  const { comments, dropped } = buildReviewComments(parsed, findings);
  assert.equal(comments.length, 0);
  assert.equal(dropped, 1);
});
