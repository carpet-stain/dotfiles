#!/usr/bin/env node
// DIY advisory PR reviewer (issue #330): calls a non-Anthropic model on the
// PR diff and posts genuine per-line review comments — with real
// `suggestion` blocks GitHub renders as one-click-applyable — via
// pulls.createReview. Replaces anc95/ChatGPT-CodeReview, whose comments
// batch per-file with no real suggestion anchoring (see #304's PR
// discussion). Wired from ../../.github/workflows/pr-code-review.yml;
// stays advisory-only per docs/adr/0025 — posts a COMMENT-event review,
// never APPROVE/REQUEST_CHANGES, so it can't gate a merge on its own.
//
// Talks to the GitHub and OpenAI REST APIs directly with the platform
// `fetch` (no octokit/openai SDK, no third-party Action in the request
// path — the whole point of #330 over the prior action). All I/O lives
// here; the parsing/formatting logic in diff.mjs and build-review.mjs is
// pure and unit-tested in isolation (build-review.test.mjs) since this
// workflow can't be exercised end-to-end outside a real PR run.

import { parseFiles, buildPrompt, buildReviewComments } from "./build-review.mjs";

const {
  GITHUB_TOKEN,
  OPENAI_API_KEY,
  OPENAI_MODEL = "gpt-4o-mini",
  GITHUB_REPOSITORY,
  PR_NUMBER,
  GITHUB_API_URL = "https://api.github.com",
  OPENAI_API_URL = "https://api.openai.com/v1/chat/completions",
} = process.env;

for (const [name, value] of Object.entries({
  GITHUB_TOKEN,
  OPENAI_API_KEY,
  GITHUB_REPOSITORY,
  PR_NUMBER,
})) {
  if (!value) {
    console.error(`pr-review: missing required env var ${name}`);
    process.exit(1);
  }
}

const [owner, repo] = GITHUB_REPOSITORY.split("/");

async function githubRequest(path, options = {}) {
  const res = await fetch(`${GITHUB_API_URL}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${GITHUB_TOKEN}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      ...options.headers,
    },
  });
  if (!res.ok) {
    throw new Error(`GitHub API ${options.method ?? "GET"} ${path} failed: ${res.status} ${await res.text()}`);
  }
  return res.status === 204 ? null : res.json();
}

async function fetchPrFiles() {
  const files = [];
  for (let page = 1; ; page++) {
    const batch = await githubRequest(`/repos/${owner}/${repo}/pulls/${PR_NUMBER}/files?per_page=100&page=${page}`);
    files.push(...batch);
    if (batch.length < 100) break;
  }
  return files;
}

// Structured Outputs schema: forces the model to return exactly this
// shape instead of free text to re-parse (the acceptance criterion #330
// leads with). `strict: true` makes the API itself reject a malformed
// response rather than us discovering it at JSON.parse time.
const FINDINGS_SCHEMA = {
  name: "review_findings",
  strict: true,
  schema: {
    type: "object",
    properties: {
      findings: {
        type: "array",
        items: {
          type: "object",
          properties: {
            file: { type: "string" },
            line: { type: "integer" },
            severity: { type: "string", enum: ["blocking", "nit", "pre-existing"] },
            comment: { type: "string" },
            suggestion: { type: ["string", "null"] },
          },
          required: ["file", "line", "severity", "comment", "suggestion"],
          additionalProperties: false,
        },
      },
    },
    required: ["findings"],
    additionalProperties: false,
  },
};

const SYSTEM_PROMPT = `You are an independent code reviewer looking at a pull request diff — a
different model than the one that wrote the change, so bring genuinely
independent eyes. Each file is shown as its changed lines, prefixed with
the exact line number in the new version of the file; only those numbered
lines can be commented on.

For each real issue, report: the file, the exact line number shown, a
severity (blocking / nit / pre-existing), a one-to-two sentence comment
explaining what's wrong and why, and — only when the fix is a mechanical,
single-line replacement — the exact replacement text for that one line
(no line-number prefix) as "suggestion"; otherwise set "suggestion" to
null. Most severe first. Say nothing about lines that are fine — return an
empty findings array if the diff has no real issues. Do not invent a file
or line number that wasn't shown to you.`;

async function callOpenAI(prompt) {
  const res = await fetch(OPENAI_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: prompt },
      ],
      response_format: { type: "json_schema", json_schema: FINDINGS_SCHEMA },
    }),
  });
  if (!res.ok) {
    throw new Error(`OpenAI API request failed: ${res.status} ${await res.text()}`);
  }
  const body = await res.json();
  const content = body.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI response had no message content");
  return JSON.parse(content).findings ?? [];
}

async function postReview(comments, dropped) {
  const summary =
    `Advisory review (non-Anthropic model, see docs/adr/0025) — ${comments.length} finding` +
    `${comments.length === 1 ? "" : "s"}` +
    (dropped ? `, ${dropped} dropped (referenced a file/line outside the diff)` : "") +
    `. Advisory only — a human approves the merge.`;

  await githubRequest(`/repos/${owner}/${repo}/pulls/${PR_NUMBER}/reviews`, {
    method: "POST",
    body: JSON.stringify({ event: "COMMENT", body: summary, comments }),
  });
}

async function main() {
  const rawFiles = await fetchPrFiles();
  const parsedFiles = parseFiles(rawFiles);
  if (parsedFiles.length === 0) {
    console.log("pr-review: no reviewable (text, non-binary) file changes — skipping.");
    return;
  }

  const prompt = buildPrompt(parsedFiles);
  const findings = await callOpenAI(prompt);
  const { comments, dropped } = buildReviewComments(parsedFiles, findings);

  if (comments.length === 0) {
    console.log(`pr-review: no findings to post${dropped ? ` (${dropped} dropped)` : ""}.`);
    return;
  }

  await postReview(comments, dropped);
  console.log(`pr-review: posted ${comments.length} comment(s), ${dropped} dropped.`);
}

main().catch((err) => {
  // Advisory reviewer: a transient OpenAI/GitHub outage or rate-limit must
  // never fail the check (docs/adr/0025 — human approval is the gate and
  // this job is deliberately not a required check). Log the full error for
  // diagnosis, surface a warning annotation so a real misconfig (bad key,
  // missing perms) stays visible in the PR checks UI, then exit 0 so the run
  // stays green. Wiring errors in our own env are still caught loud above
  // (missing required env var -> exit 1) before any of this runs.
  console.error(err);
  console.log(`::warning title=PR advisory review::skipped after error: ${err.message}`);
  process.exit(0);
});
