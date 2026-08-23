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
import {
  parseFiles,
  buildPrompt,
  buildReviewComments,
  buildContext,
  isEligibleForReview,
  classifyPriorThreads,
  suppressAlreadyRaised,
  buildPriorFindingsSection,
  evaluateReplyGuard,
  buildThreadHistorySection,
  buildCodeContextSection,
  MAX_PROMPT_CHARS,
  MAX_ISSUE_BODY_CHARS,
  MAX_PRIOR_FINDINGS,
  MAX_PRIOR_CONTEXT_CHARS,
  REPLY_CODE_CONTEXT_LINES,
  MAX_CODE_CONTEXT_CHARS,
} from "./build-review.mjs";

const BOT_LOGIN = "github-actions[bot]";

function thread({ path = "a.ts", line = 11, isResolved = false, isOutdated = false, comments }) {
  return { path, line, originalLine: line, isResolved, isOutdated, comments: { nodes: comments } };
}

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

test("buildReviewComments sorts blocking < recommended < nit < pre-existing", () => {
  const parsed = parseFiles([{ filename: "a.ts", patch: SAMPLE_PATCH }]);
  const findings = [
    { file: "a.ts", line: 10, severity: "nit", comment: "n", suggestion: null },
    { file: "a.ts", line: 11, severity: "blocking", comment: "b", suggestion: null },
    { file: "a.ts", line: 12, severity: "pre-existing", comment: "p", suggestion: null },
    { file: "a.ts", line: 13, severity: "recommended", comment: "r", suggestion: null },
  ];
  const { comments } = buildReviewComments(parsed, findings);
  assert.deepEqual(
    comments.map((c) => c.line),
    [11, 13, 10, 12],
  );
});

test("buildReviewComments drops a finding with an unknown severity", () => {
  const parsed = parseFiles([{ filename: "a.ts", patch: SAMPLE_PATCH }]);
  const findings = [{ file: "a.ts", line: 10, severity: "catastrophic", comment: "x", suggestion: null }];
  const { comments, dropped } = buildReviewComments(parsed, findings);
  assert.equal(comments.length, 0);
  assert.equal(dropped, 1);
});

test("buildContext renders PR title/body and linked issues, empty for no PR", () => {
  const ctx = buildContext(
    { title: "feat: add widget", body: "Adds the widget.\nCloses #5" },
    [{ number: 5, title: "Need a widget", body: "We should have a widget." }],
  );
  assert.match(ctx, /## Intent/);
  assert.match(ctx, /PR: feat: add widget/);
  assert.match(ctx, /Adds the widget\./);
  assert.match(ctx, /Linked issue #5: Need a widget/);
  assert.match(ctx, /We should have a widget\./);
  assert.equal(buildContext(null), "");
});

test("buildContext caps an over-long issue body", () => {
  const huge = "y".repeat(MAX_ISSUE_BODY_CHARS * 2);
  const ctx = buildContext({ title: "t" }, [{ number: 1, title: "big", body: huge }]);
  assert.ok(!ctx.includes(huge), "full oversized body must not appear verbatim");
  assert.ok(ctx.includes("y".repeat(MAX_ISSUE_BODY_CHARS)), "a capped slice should appear");
});

test("isEligibleForReview triggers on the PR's own needs-review label", () => {
  assert.equal(isEligibleForReview(["needs-review"], []), true);
  assert.equal(isEligibleForReview(["architecture"], []), false);
});

test("isEligibleForReview triggers when a closed issue carries plan-approved", () => {
  assert.equal(isEligibleForReview([], [{ labels: ["plan-approved"] }]), true);
  assert.equal(isEligibleForReview([], [{ labels: ["needs-plan-review"] }]), false);
});

test("isEligibleForReview is false when neither the label nor a closed issue qualifies", () => {
  assert.equal(isEligibleForReview([], []), false);
  assert.equal(isEligibleForReview(["bug"], [{ labels: ["enhancement"] }]), false);
});

test("classifyPriorThreads marks a resolved bot thread resolved", () => {
  const threads = [
    thread({
      isResolved: true,
      comments: [{ author: { login: BOT_LOGIN }, body: "**blocking**: null check missing" }],
    }),
  ];
  const [finding] = classifyPriorThreads(threads, BOT_LOGIN);
  assert.equal(finding.status, "resolved");
  assert.equal(finding.path, "a.ts");
  assert.equal(finding.line, 11);
  assert.equal(finding.comment, "null check missing");
});

test("classifyPriorThreads marks an unresolved thread with an author reply declined", () => {
  const threads = [
    thread({
      isResolved: false,
      comments: [
        { author: { login: BOT_LOGIN }, body: "**nit**: prefer const here" },
        { author: { login: "the-author" }, body: "disagree, leaving as-is" },
      ],
    }),
  ];
  const [finding] = classifyPriorThreads(threads, BOT_LOGIN);
  assert.equal(finding.status, "declined");
});

test("classifyPriorThreads marks an unresolved thread with no reply open", () => {
  const threads = [
    thread({
      isResolved: false,
      comments: [{ author: { login: BOT_LOGIN }, body: "**recommended**: add a test" }],
    }),
  ];
  const [finding] = classifyPriorThreads(threads, BOT_LOGIN);
  assert.equal(finding.status, "open");
});

test("classifyPriorThreads ignores a reply from the bot itself when checking for author pushback", () => {
  const threads = [
    thread({
      isResolved: false,
      comments: [
        { author: { login: BOT_LOGIN }, body: "**nit**: prefer const here" },
        { author: { login: BOT_LOGIN }, body: "still applies" },
      ],
    }),
  ];
  const [finding] = classifyPriorThreads(threads, BOT_LOGIN);
  assert.equal(finding.status, "open");
});

test("classifyPriorThreads drops a thread this reviewer didn't open", () => {
  const threads = [
    thread({ comments: [{ author: { login: "someone-else" }, body: "manual review comment" }] }),
  ];
  assert.deepEqual(classifyPriorThreads(threads, BOT_LOGIN), []);
});

test("classifyPriorThreads matches despite a [bot]-suffix mismatch between viewer.login and comment author.login", () => {
  // Confirmed live (#674's live-proof run): GraphQL's viewer.login for the
  // Actions token returns "github-actions[bot]", but that same identity's
  // author.login on a comment it posted returns "github-actions" — no
  // suffix. Passing the viewer-shaped login in as botLogin must still match
  // the un-suffixed author login on the thread's own comments.
  const threads = [
    thread({
      isResolved: true,
      comments: [{ author: { login: "github-actions" }, body: "**blocking**: null check missing" }],
    }),
  ];
  const [finding] = classifyPriorThreads(threads, "github-actions[bot]");
  assert.equal(finding.status, "resolved");
});

test("classifyPriorThreads drops an outdated thread — its finding is eligible again", () => {
  const threads = [
    thread({
      isResolved: true,
      isOutdated: true,
      comments: [{ author: { login: BOT_LOGIN }, body: "**blocking**: null check missing" }],
    }),
  ];
  assert.deepEqual(classifyPriorThreads(threads, BOT_LOGIN), []);
});

test("suppressAlreadyRaised drops a finding matching a prior one on path + similar comment", () => {
  const prior = [{ path: "a.ts", comment: "missing a null check before dereferencing user" }];
  const findings = [
    { file: "a.ts", line: 40, severity: "blocking", comment: "add a null check before dereferencing the user object", suggestion: null },
  ];
  const { findings: kept, suppressed } = suppressAlreadyRaised(findings, prior);
  assert.equal(kept.length, 0);
  assert.equal(suppressed, 1);
});

test("suppressAlreadyRaised keeps a finding on a different file even with the same comment", () => {
  const prior = [{ path: "a.ts", comment: "missing a null check before dereferencing user" }];
  const findings = [
    { file: "b.ts", line: 40, severity: "blocking", comment: "missing a null check before dereferencing user", suggestion: null },
  ];
  const { findings: kept, suppressed } = suppressAlreadyRaised(findings, prior);
  assert.equal(kept.length, 1);
  assert.equal(suppressed, 0);
});

test("suppressAlreadyRaised keeps a genuinely different finding on the same file", () => {
  const prior = [{ path: "a.ts", comment: "missing a null check before dereferencing user" }];
  const findings = [{ file: "a.ts", line: 40, severity: "nit", comment: "prefer a template literal here", suggestion: null }];
  const { findings: kept, suppressed } = suppressAlreadyRaised(findings, prior);
  assert.equal(kept.length, 1);
  assert.equal(suppressed, 0);
});

test("buildPriorFindingsSection is empty with no prior findings", () => {
  assert.equal(buildPriorFindingsSection([]), "");
});

test("buildPriorFindingsSection labels each status and includes path:line", () => {
  const section = buildPriorFindingsSection([
    { path: "a.ts", line: 11, comment: "null check", status: "resolved" },
    { path: "b.ts", line: 5, comment: "prefer const", status: "declined" },
    { path: "c.ts", line: 9, comment: "add a test", status: "open" },
  ]);
  assert.match(section, /## Findings already raised in earlier reviews/);
  assert.match(section, /a\.ts:11 \[resolved\] null check/);
  assert.match(section, /b\.ts:5 \[declined by the author\] prefer const/);
  assert.match(section, /c\.ts:9 \[still open, already visible in an existing review thread\] add a test/);
});

test("buildPriorFindingsSection caps output at MAX_PRIOR_FINDINGS / MAX_PRIOR_CONTEXT_CHARS", () => {
  const many = Array.from({ length: MAX_PRIOR_FINDINGS + 20 }, (_, i) => ({
    path: `f${i}.ts`,
    line: 1,
    comment: "x".repeat(200),
    status: "open",
  }));
  const section = buildPriorFindingsSection(many);
  assert.ok(section.length <= MAX_PRIOR_CONTEXT_CHARS + 200, "section must stay near the char cap");
  assert.ok(!section.includes(`f${MAX_PRIOR_FINDINGS + 19}.ts`), "must not include entries far past the cap");
});

// --- #675: thread-reply guard + prompt rendering ---------------------------

const BOT_VIEWER_LOGIN = "github-actions[bot]"; // GraphQL viewer.login shape
const BOT_AUTHOR_LOGIN = "github-actions"; // that same identity's comment author.login (#674)

// Builds a flat, chronologically-ordered comment list for one thread: the
// first row opens it (inReplyToId: null), every later row replies to it.
// Real ids/timestamps don't matter to evaluateReplyGuard beyond ordering and
// identity, so both are synthesized here.
function mkThread(rows) {
  const rootId = 100;
  return rows.map((r, i) => ({
    id: rootId + i,
    inReplyToId: i === 0 ? null : rootId,
    authorLogin: r.author,
    body: r.body ?? `comment ${i}`,
    path: r.path ?? "a.ts",
    line: r.line ?? 11,
    createdAt: `2026-01-01T00:${String(i).padStart(2, "0")}:00Z`,
  }));
}

test("evaluateReplyGuard allows the first reply on a thread the reviewer opened", () => {
  const comments = mkThread([{ author: BOT_AUTHOR_LOGIN }, { author: "the-author" }]);
  const decision = evaluateReplyGuard(comments, comments[1].id, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, true);
  assert.deepEqual(decision.thread, comments);
});

test("evaluateReplyGuard refuses a comment that isn't a reply to any thread", () => {
  const comments = [
    { id: 1, inReplyToId: null, authorLogin: "someone", body: "x", path: "a.ts", line: 1, createdAt: "2026-01-01T00:00:00Z" },
  ];
  const decision = evaluateReplyGuard(comments, 1, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, false);
  assert.match(decision.reason, /not a reply/);
});

test("evaluateReplyGuard refuses a thread the reviewer didn't open", () => {
  const comments = mkThread([{ author: "someone-else" }, { author: "the-author" }]);
  const decision = evaluateReplyGuard(comments, comments[1].id, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, false);
  assert.match(decision.reason, /not opened by this reviewer/);
});

test("evaluateReplyGuard self-spawn guard refuses when the triggering comment is the reviewer's own", () => {
  const comments = mkThread([{ author: BOT_AUTHOR_LOGIN }, { author: BOT_AUTHOR_LOGIN }]);
  const decision = evaluateReplyGuard(comments, comments[1].id, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, false);
  assert.match(decision.reason, /self-spawn/);
});

test("evaluateReplyGuard lets an implementor's reply through — not a blanket machine-account filter", () => {
  const comments = mkThread([{ author: BOT_AUTHOR_LOGIN }, { author: "carpet-stain-implementor" }]);
  const decision = evaluateReplyGuard(comments, comments[1].id, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, true);
});

test("evaluateReplyGuard reply cap refuses a second reply with no intervening human comment", () => {
  const comments = mkThread([
    { author: BOT_AUTHOR_LOGIN }, // root finding
    { author: "carpet-stain-implementor" }, // reply 1
    { author: BOT_AUTHOR_LOGIN }, // reviewer's answer
    { author: "carpet-stain-implementor" }, // reply 2 (trigger) — no human in between
  ]);
  const decision = evaluateReplyGuard(comments, comments[3].id, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, false);
  assert.match(decision.reason, /reply cap/);
});

test("evaluateReplyGuard reply cap resets after a human comment", () => {
  const comments = mkThread([
    { author: BOT_AUTHOR_LOGIN }, // root finding
    { author: "carpet-stain-implementor" }, // reply 1
    { author: BOT_AUTHOR_LOGIN }, // reviewer's answer
    { author: "carpet-stain" }, // a human weighs in
    { author: "carpet-stain-implementor" }, // reply 2 (trigger) — allowed again
  ]);
  const decision = evaluateReplyGuard(comments, comments[4].id, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, true);
});

test("evaluateReplyGuard fails closed when the triggering comment isn't present in the fetched list", () => {
  const comments = mkThread([{ author: BOT_AUTHOR_LOGIN }, { author: "the-author" }]);
  const decision = evaluateReplyGuard(comments, 99999, BOT_VIEWER_LOGIN);
  assert.equal(decision.reply, false);
  assert.match(decision.reason, /not found/);
});

test("buildThreadHistorySection renders the reviewer's own message via extractFindingText, others verbatim", () => {
  const thread = mkThread([
    { author: BOT_AUTHOR_LOGIN, body: "**blocking**: null check missing" },
    { author: "the-author", body: "already fixed, please check" },
  ]);
  const section = buildThreadHistorySection(thread, BOT_VIEWER_LOGIN);
  assert.match(section, /## Thread history/);
  assert.match(section, /\*\*Reviewer \(you\)\*\*: null check missing/);
  assert.match(section, /\*\*the-author\*\*: already fixed, please check/);
});

test("buildThreadHistorySection caps an over-long comment", () => {
  const huge = "y".repeat(3000);
  const thread = mkThread([{ author: BOT_AUTHOR_LOGIN, body: "finding" }, { author: "the-author", body: huge }]);
  const section = buildThreadHistorySection(thread, BOT_VIEWER_LOGIN);
  assert.ok(!section.includes(huge), "full oversized comment must not appear verbatim");
});

test("buildCodeContextSection renders a window of lines around the target line", () => {
  const total = 50;
  const content = Array.from({ length: total }, (_, i) => `line ${i + 1}`).join("\n");
  const targetLine = 25;
  const section = buildCodeContextSection("a.ts", targetLine, content);
  const expectedStart = Math.max(1, targetLine - REPLY_CODE_CONTEXT_LINES);
  const expectedEnd = Math.min(total, targetLine + REPLY_CODE_CONTEXT_LINES);
  assert.match(section, new RegExp(`lines ${expectedStart}-${expectedEnd}`));
  assert.match(section, /^25: line 25$/m);
  assert.ok(!new RegExp(`^${expectedStart - 1}: `, "m").test(section), "must not include a line outside the window");
});

test("buildCodeContextSection clamps the window to file bounds near the start of a short file", () => {
  const content = Array.from({ length: 5 }, (_, i) => `line ${i + 1}`).join("\n");
  const section = buildCodeContextSection("a.ts", 2, content);
  assert.match(section, /lines 1-5/);
});

test("buildCodeContextSection reports an unreadable file without crashing", () => {
  const section = buildCodeContextSection("a.ts", 10, null);
  assert.match(section, /could not be read/);
});

test("buildCodeContextSection stays within MAX_CODE_CONTEXT_CHARS for a huge window", () => {
  const content = Array.from({ length: 5000 }, (_, i) => `line ${i + 1} `.repeat(20)).join("\n");
  const section = buildCodeContextSection("a.ts", 2500, content);
  assert.ok(section.length <= MAX_CODE_CONTEXT_CHARS, "section must stay within the char cap");
});
