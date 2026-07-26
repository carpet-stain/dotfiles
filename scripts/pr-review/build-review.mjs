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
// model alongside the diff. Issue bodies here can be long (they hold the plan).
export const MAX_ISSUES = 3;
export const MAX_PR_BODY_CHARS = 2000;
export const MAX_ISSUE_BODY_CHARS = 3000;

// GitHub's closing keywords tie a PR to the issue it resolves.
const CLOSING_REF = /\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\b[:\s]+#(\d+)/gi;

/**
 * Extracts the issue numbers a PR body says it closes (GitHub closing
 * keywords close/fix/resolve + #N). Deduped, first-seen order, capped at
 * MAX_ISSUES. Plain "#N" mentions without a closing keyword are ignored — we
 * follow only the issue the PR claims to resolve, not every cross-reference.
 * @param {string} body - the PR description
 * @param {number} [selfNumber] - the PR's own number, excluded if referenced
 * @returns {number[]}
 */
export function parseLinkedIssues(body, selfNumber) {
  if (!body) return [];
  const seen = [];
  for (const m of body.matchAll(CLOSING_REF)) {
    const n = Number(m[1]);
    if (n !== selfNumber && !seen.includes(n)) seen.push(n);
  }
  return seen.slice(0, MAX_ISSUES);
}

/**
 * Renders the "Intent" block prepended to the review prompt: the PR's
 * title/description and any linked issue bodies, each length-capped. This is
 * the spec the model checks the diff against — NOT trusted as proof the work
 * is done (see the system prompt). Returns "" when there's no PR context.
 * @param {{title?: string, body?: string}|null} pr
 * @param {{number: number, title: string, body?: string}[]} issues
 * @returns {string}
 */
export function buildContext(pr, issues = []) {
  if (!pr) return "";
  let out = "## Intent — the diff is supposed to achieve this; verify it does, don't assume it\n";
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
