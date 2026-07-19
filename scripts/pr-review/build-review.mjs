// Turns parsed diff line maps + the model's structured findings into the
// `comments` array `pulls.createReview` expects. Pure, no I/O — see
// build-review.test.mjs. run.mjs is the only caller that does real I/O.

import { parsePatch } from "./diff.mjs";

const SEVERITY_RANK = { blocking: 0, nit: 1, "pre-existing": 2 };

// Bound cost and prompt size: only this many files, and this many prompt
// characters total, go to the model. A PR bigger than this gets a partial
// review (first MAX_FILES files, truncated at MAX_PROMPT_CHARS) rather than
// an unbounded request — see PR #<this PR>'s discussion for why a hard cap
// beats dynamic chunking here.
export const MAX_FILES = 25;
export const MAX_PROMPT_CHARS = 12000;

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
