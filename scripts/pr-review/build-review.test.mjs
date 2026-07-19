// Unit tests for the pure diff-parsing / review-building logic, run with
// Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/pr-review/
//
// This is the isolation-testable half of the DIY PR reviewer (#330) — the
// I/O half (run.mjs: real GitHub/OpenAI calls) can only really prove out
// on a live PR run, per this repo's AGENTS.md verification guidance.

import { test } from "node:test";
import assert from "node:assert/strict";
import { parsePatch } from "./diff.mjs";
import { parseFiles, buildPrompt, buildReviewComments } from "./build-review.mjs";

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
