// Turns parsed diff line maps + the model's structured findings into the
// `comments` array `pulls.createReview` expects. Pure, no I/O — see
// build-review.test.mjs. run.mjs is the only caller that does real I/O.

import { parsePatch } from "./diff.mjs";

// Ordering + the set of accepted severities (a finding with any other value
// is dropped). "recommended" is the should-fix-but-not-blocking middle rung;
// "pre-existing" is a real issue the diff didn't introduce, flagged last.
const SEVERITY_RANK = { blocking: 0, recommended: 1, nit: 2, "pre-existing": 3 };

// Bound cost and prompt size: only this many files, and this many prompt
// characters total, go to the model. A PR bigger than this gets a partial
// review (first MAX_FILES files, truncated at MAX_PROMPT_CHARS) rather than
// an unbounded request — see #330's discussion for why a hard cap beats
// dynamic chunking here.
export const MAX_FILES = 25;
export const MAX_PROMPT_CHARS = 12000;

// Bound the intent context (PR description + linked issue bodies) fed to the
// model alongside the diff. Issue bodies here can be long — for a
// plan-approved issue, the body is the consolidated plan and acceptance
// criteria (backlog-manager's plan-review gate), which is exactly what a
// conformance review needs to check the diff against.
export const MAX_ISSUES = 3;
export const MAX_PR_BODY_CHARS = 2000;
export const MAX_ISSUE_BODY_CHARS = 3000;

// Bound the prior-findings fetch (#674) and the slice of it injected into
// the prompt. The fetch cap (MAX_PRIOR_THREADS/MAX_THREAD_COMMENTS) feeds
// the deterministic suppression filter, which is cheap regex/token work and
// runs over the full list; MAX_PRIOR_FINDINGS/MAX_PRIOR_CONTEXT_CHARS
// separately bound what's worth spending prompt tokens on.
export const MAX_PRIOR_THREADS = 100;
export const MAX_THREAD_COMMENTS = 20;
export const MAX_PRIOR_FINDINGS = 40;
export const MAX_PRIOR_CONTEXT_CHARS = 4000;

// Below this word-overlap ratio, two comments count as different findings
// rather than a reworded duplicate. Deliberately coarse (token-set Jaccard,
// no embeddings/deps) — the prompt-level "do not repeat, including
// reworded" instruction is what catches genuine paraphrase; this layer only
// needs to catch the model re-emitting a near-identical comment.
const DUPLICATE_SIMILARITY_THRESHOLD = 0.6;

/**
 * Decides whether a PR should get the advisory review (#458): auto-triggers
 * when it closes an issue carrying `plan-approved` — this repo's plan-review
 * gate consolidates the approved plan + acceptance criteria into that
 * issue's body, exactly what a conformance review needs — or on demand via
 * the PR's own `needs-review` label (#456), independent of `architecture`'s
 * ADR-required meaning.
 * @param {string[]} prLabels - the PR's own label names
 * @param {{labels: string[]}[]} issues - issues the PR closes, each with its label names
 * @returns {boolean}
 */
export function isEligibleForReview(prLabels, issues = []) {
  return prLabels.includes("needs-review") || issues.some((issue) => issue.labels.includes("plan-approved"));
}

/**
 * Renders the "Intent" block prepended to the review prompt: the PR's
 * title/description and the bodies of issues it closes (sourced from
 * GraphQL `closingIssuesReferences`, not a body-text regex — run.mjs's
 * `fetchPrContext`), each length-capped. This is the plan the model checks
 * the diff against — NOT trusted as proof the work is done (see the system
 * prompt). Returns "" when there's no PR context.
 * @param {{title?: string, body?: string}|null} pr
 * @param {{number: number, title: string, body?: string}[]} issues
 * @returns {string}
 */
export function buildContext(pr, issues = []) {
  if (!pr) return "";
  let out = "## Intent — the diff claims to implement this plan; flag divergences from the stated approach and unmet acceptance criteria\n";
  if (pr.title) out += `\nPR: ${pr.title}\n`;
  if (pr.body) out += `\n${pr.body.trim().slice(0, MAX_PR_BODY_CHARS)}\n`;
  for (const issue of issues) {
    out += `\nLinked issue #${issue.number}: ${issue.title}\n`;
    if (issue.body) out += `${issue.body.trim().slice(0, MAX_ISSUE_BODY_CHARS)}\n`;
  }
  return out.trim();
}

/**
 * @param {{filename: string, patch?: string}[]} files - GitHub's
 *   pulls.listFiles response entries.
 * @returns {{filename: string, lines: Map<number,string>}[]} text files
 *   only (binary/too-large files carry no `patch` and are dropped), capped
 *   at MAX_FILES.
 */
export function parseFiles(files) {
  return files
    .filter((f) => f.patch)
    .slice(0, MAX_FILES)
    .map((f) => ({ filename: f.filename, lines: parsePatch(f.patch) }));
}

/**
 * Renders the annotated-line-number prompt section the model sees: each
 * commentable line prefixed with its exact new-file line number, so the
 * model's response can only reference line numbers we already know are
 * valid review-comment anchors.
 */
export function buildPrompt(parsedFiles) {
  let out = "";
  for (const { filename, lines } of parsedFiles) {
    let section = `File: ${filename}\n`;
    for (const [line, content] of lines) {
      section += `${line}: ${content}\n`;
    }
    if (out.length + section.length > MAX_PROMPT_CHARS) {
      // A first file whose section alone overflows the budget still gets a
      // truncated slice, so a large single-file PR is reviewed partially
      // rather than not at all. buildReviewComments validates every finding
      // against the full parsed line map, so a mid-line cut here can't post
      // a comment on a bogus anchor.
      if (out.length === 0) {
        out = section.slice(0, MAX_PROMPT_CHARS);
      }
      out += "\n[truncated — remaining files omitted to bound prompt size]\n";
      break;
    }
    out += `\n${section}`;
  }
  return out.trim();
}

/**
 * Validates model findings against the actual diff (defense against a
 * hallucinated file/line/severity) and renders each into a review comment
 * body. Findings that don't anchor to a real diff line are dropped rather
 * than posted — GitHub's createReview API would 422 the whole review on a
 * single bad anchor otherwise.
 *
 * @param {{filename: string, lines: Map<number,string>}[]} parsedFiles
 * @param {{file: string, line: number, severity: string, comment: string, suggestion?: string|null}[]} findings
 * @returns {{comments: {path: string, line: number, side: 'RIGHT', body: string}[], dropped: number}}
 */
export function buildReviewComments(parsedFiles, findings) {
  const byFile = new Map(parsedFiles.map((f) => [f.filename, f.lines]));
  let dropped = 0;

  const valid = findings.filter((f) => {
    const lines = byFile.get(f.file);
    const ok = Boolean(lines) && lines.has(f.line) && SEVERITY_RANK[f.severity] !== undefined;
    if (!ok) dropped++;
    return ok;
  });

  valid.sort((a, b) => SEVERITY_RANK[a.severity] - SEVERITY_RANK[b.severity]);

  const comments = valid.map((f) => {
    let body = `**${f.severity}**: ${f.comment}`;
    if (f.suggestion) {
      body += `\n\n\`\`\`suggestion\n${f.suggestion}\n\`\`\``;
    }
    return { path: f.file, line: f.line, side: "RIGHT", body };
  });

  return { comments, dropped };
}

// Bound the reply prompt (#675): how much surrounding code to show around the
// finding's line when re-reading it at HEAD, how much of one thread comment
// to inject, and a hard char cap on the rendered code section so a giant
// file can't blow out the prompt.
export const REPLY_CODE_CONTEXT_LINES = 15;
export const MAX_CODE_CONTEXT_CHARS = 4000;
export const MAX_REPLY_COMMENT_CHARS = 1500;

// Strips this reviewer's own comment formatting (buildReviewComments' "**severity**: "
// prefix and a trailing ```suggestion``` block) back to the finding text, so a prior
// comment fetched from GitHub compares against a fresh model finding on the same terms.
function extractFindingText(body) {
  return body
    .replace(/^\*\*[\w-]+\*\*:\s*/, "")
    .replace(/\n\n```suggestion\n[\s\S]*```\s*$/, "")
    .trim();
}

// GraphQL renders the same Actions bot identity's login inconsistently by
// field: `viewer.login` on the token run.mjs posts with returns
// "github-actions[bot]", but that same bot's `author.login` on a comment it
// posted returns "github-actions" (no suffix) — confirmed live, not assumed
// (#674's live-proof run). Strip the suffix on both sides before comparing.
function normalizeLogin(login) {
  return login?.replace(/\[bot\]$/, "");
}

function tokenize(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter(Boolean);
}

// Word-set Jaccard similarity — good enough to catch a reworded repost
// without an embedding model; see DUPLICATE_SIMILARITY_THRESHOLD.
function commentSimilarity(a, b) {
  const tokensA = new Set(tokenize(a));
  const tokensB = new Set(tokenize(b));
  if (tokensA.size === 0 || tokensB.size === 0) return 0;
  let overlap = 0;
  for (const t of tokensA) if (tokensB.has(t)) overlap++;
  const union = new Set([...tokensA, ...tokensB]).size;
  return overlap / union;
}

/**
 * Classifies this reviewer's own prior review threads on the PR (#674) into
 * the three outcomes that matter for suppression, and drops the rest:
 * - "resolved": the author acted or explicitly dismissed the thread.
 * - "declined": unresolved, but the author replied — pushback counts as
 *   engagement regardless of what the reply says (errs toward silence,
 *   the right direction for an advisory tool).
 * - "open": unresolved, no reply — genuinely still pending, not reworded,
 *   just not worth reposting as a duplicate of the visible thread.
 *
 * A thread GitHub marks `isOutdated` (the surrounding diff hunk changed
 * since the comment was posted) is dropped entirely rather than classified:
 * if the author rewrote the code and reintroduced the same defect, that's a
 * new finding, not a repeat.
 *
 * @param {{path: string, line: number|null, originalLine: number|null,
 *   isResolved: boolean, isOutdated: boolean,
 *   comments: {nodes: {author: {login: string}|null, body: string}[]}}[]} threads
 *   - GraphQL `reviewThreads.nodes`.
 * @param {string} botLogin - this reviewer's own login (GraphQL `viewer.login`
 *   for the token run.mjs posts reviews with), so a thread someone else opened
 *   is never mistaken for a prior finding of ours.
 * @returns {{path: string, line: number, comment: string, status: 'resolved'|'declined'|'open'}[]}
 */
export function classifyPriorThreads(threads, botLogin) {
  const normalizedBotLogin = normalizeLogin(botLogin);
  const result = [];
  for (const thread of threads) {
    if (thread.isOutdated) continue;
    const comments = thread.comments?.nodes ?? [];
    const [first, ...replies] = comments;
    if (!first || normalizeLogin(first.author?.login) !== normalizedBotLogin) continue;
    const line = thread.line ?? thread.originalLine;
    if (!thread.path || line == null) continue;
    const hasAuthorReply = replies.some((c) => normalizeLogin(c.author?.login) !== normalizedBotLogin);
    result.push({
      path: thread.path,
      line,
      comment: extractFindingText(first.body),
      status: thread.isResolved ? "resolved" : hasAuthorReply ? "declined" : "open",
    });
  }
  return result;
}

/**
 * Deterministic half of #674's two-layer suppression: drops a fresh finding
 * that matches an already-classified prior one on the same file and a
 * near-identical comment. Line number is deliberately not part of the match
 * — it shifts between pushes, so anchoring on it alone would miss a
 * finding the model re-raised, reworded, at a slightly different line.
 *
 * @param {{file: string, line: number, severity: string, comment: string, suggestion?: string|null}[]} findings
 * @param {{path: string, comment: string}[]} priorFindings - from classifyPriorThreads
 * @returns {{findings: typeof findings, suppressed: number}}
 */
export function suppressAlreadyRaised(findings, priorFindings) {
  let suppressed = 0;
  const kept = findings.filter((f) => {
    const isDuplicate = priorFindings.some(
      (p) => p.path === f.file && commentSimilarity(p.comment, f.comment) >= DUPLICATE_SIMILARITY_THRESHOLD,
    );
    if (isDuplicate) suppressed++;
    return !isDuplicate;
  });
  return { findings: kept, suppressed };
}

const STATUS_LABEL = {
  resolved: "resolved",
  declined: "declined by the author",
  open: "still open, already visible in an existing review thread",
};

/**
 * Renders the prior-findings context block (#674's in-prompt suppression
 * layer): each classified prior finding, capped the same way `buildContext`
 * caps issue bodies, so a long-running PR's accumulated history can't crowd
 * the diff out of the prompt. Returns "" when there's nothing prior.
 * @param {{path: string, line: number, comment: string, status: string}[]} priorFindings
 * @returns {string}
 */
export function buildPriorFindingsSection(priorFindings) {
  if (priorFindings.length === 0) return "";
  let out = "## Findings already raised in earlier reviews — do not repeat these, including in reworded form\n";
  for (const f of priorFindings.slice(0, MAX_PRIOR_FINDINGS)) {
    const line = `- ${f.path}:${f.line} [${STATUS_LABEL[f.status]}] ${f.comment}\n`;
    if (out.length + line.length > MAX_PRIOR_CONTEXT_CHARS) break;
    out += line;
  }
  return out.trim();
}

// A carpet-stain-<role> login is one of this repo's own machine identities
// (agent-loop-guard.mjs's `machineLogin`) — distinct from this reviewer's own
// GITHUB_TOKEN login, which normalizeLogin/botLogin already excludes. Used
// only to decide whether a comment resets the reply cap below, never to
// filter who may trigger a reply at all (#675 — a blanket machine-account
// filter would also block the implementor, defeating the point).
const MACHINE_LOGIN_PATTERN = /^carpet-stain-/;

function isHumanLogin(login, botLogin) {
  const normalized = normalizeLogin(login);
  return normalized !== normalizeLogin(botLogin) && !MACHINE_LOGIN_PATTERN.test(normalized ?? "");
}

/**
 * Decides whether the reviewer should reply to a just-posted PR review
 * comment (#675). Three independent guards, all fail-closed (unmatched or
 * ambiguous input means don't reply):
 * - Only replies on a thread it opened itself — never one it didn't start.
 * - Self-spawn: never replies to its own comment (defense in depth; a
 *   GITHUB_TOKEN-posted comment doesn't retrigger the workflow in the first
 *   place, but the check stays cheap and explicit rather than assumed).
 * - Reply cap: never replies twice in a row without an intervening HUMAN
 *   comment — a rule, not a hard count, so a genuine back-and-forth with a
 *   human never gets capped, but two machine identities (this reviewer and
 *   an implementor agent) can't ping-pong with nobody watching.
 *
 * @param {{id: number|string, inReplyToId: number|string|null, authorLogin: string, body: string, path: string, line: number, createdAt: string}[]} comments
 *   - every review comment on the PR (all threads flattened together).
 * @param {number|string} triggeringCommentId - the comment that just fired
 *   the `pull_request_review_comment: created` event.
 * @param {string} botLogin - this reviewer's own posting identity (GraphQL
 *   `viewer.login` for the token this run posts with).
 * @returns {{reply: boolean, reason: string, thread?: typeof comments}}
 */
export function evaluateReplyGuard(comments, triggeringCommentId, botLogin) {
  const triggering = comments.find((c) => String(c.id) === String(triggeringCommentId));
  if (!triggering) {
    return { reply: false, reason: "triggering comment not found" };
  }
  if (!triggering.inReplyToId) {
    return { reply: false, reason: "not a reply to an existing review thread" };
  }

  const rootId = String(triggering.inReplyToId);
  const thread = comments
    .filter((c) => String(c.id) === rootId || String(c.inReplyToId) === rootId)
    .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));

  const root = thread[0];
  if (!root || normalizeLogin(root.authorLogin) !== normalizeLogin(botLogin)) {
    return { reply: false, reason: "thread was not opened by this reviewer", thread };
  }

  const idx = thread.findIndex((c) => String(c.id) === String(triggeringCommentId));
  if (idx <= 0) {
    return { reply: false, reason: "triggering comment not found in its own thread", thread };
  }
  if (normalizeLogin(triggering.authorLogin) === normalizeLogin(botLogin)) {
    return { reply: false, reason: "self-spawn: triggering comment is the reviewer's own", thread };
  }

  let botRepliedSinceHuman = false;
  for (let i = 1; i < idx; i++) {
    if (isHumanLogin(thread[i].authorLogin, botLogin)) botRepliedSinceHuman = false;
    else if (normalizeLogin(thread[i].authorLogin) === normalizeLogin(botLogin)) botRepliedSinceHuman = true;
  }
  if (botRepliedSinceHuman) {
    return { reply: false, reason: "reply cap: already replied once since the last human comment on this thread", thread };
  }

  return { reply: true, reason: "eligible: human/agent reply on a thread this reviewer opened", thread };
}

/**
 * Renders the thread's full comment history for the reply prompt (#675) —
 * the finding this reviewer raised, plus every reply since, in order. This
 * reviewer's own prior messages go through the same extractFindingText used
 * for suppression, so its comment-formatting markup doesn't leak into what
 * looks like a quote of its own words.
 * @param {{authorLogin: string, body: string}[]} thread - evaluateReplyGuard's `thread`.
 * @param {string} botLogin
 * @returns {string}
 */
export function buildThreadHistorySection(thread, botLogin) {
  let out = "## Thread history — the finding you raised, and every reply since\n\n";
  for (const c of thread) {
    const isBot = normalizeLogin(c.authorLogin) === normalizeLogin(botLogin);
    const role = isBot ? "Reviewer (you)" : c.authorLogin;
    const body = isBot ? extractFindingText(c.body) : c.body;
    out += `**${role}**: ${body.trim().slice(0, MAX_REPLY_COMMENT_CHARS)}\n\n`;
  }
  return out.trim();
}

/**
 * Renders the "current code" section of the reply prompt (#675): a window
 * around the finding's line in the file as it stands at the PR's current
 * HEAD, not the (possibly stale) diff hunk originally reviewed — what makes
 * "I've fixed this, look again" a question the model can actually answer.
 * @param {string} path
 * @param {number} line
 * @param {string|null} fileContent - full file text at HEAD, or null when it
 *   couldn't be fetched (deleted, renamed, or a transient API error).
 * @returns {string}
 */
export function buildCodeContextSection(path, line, fileContent) {
  if (fileContent == null) {
    return `## Current code at ${path}:${line}\n\n(could not be read at the current HEAD — it may have been deleted or renamed since the finding was posted; answer from the thread history alone)`;
  }
  const lines = fileContent.split("\n");
  const start = Math.max(1, line - REPLY_CODE_CONTEXT_LINES);
  const end = Math.min(lines.length, line + REPLY_CODE_CONTEXT_LINES);
  let out = `## Current code at ${path}, lines ${start}-${end} (current HEAD — may differ from the diff originally reviewed)\n\n`;
  for (let n = start; n <= end; n++) {
    out += `${n}: ${lines[n - 1]}\n`;
  }
  return out.slice(0, MAX_CODE_CONTEXT_CHARS).trim();
}
