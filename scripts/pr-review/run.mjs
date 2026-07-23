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
            severity: { type: "string", enum: ["blocking", "recommended", "nit", "pre-existing"] },
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

// The rubric, severity ladder, and anti-noise rules below are distilled from
// established review guidance (Google eng-practices; Netlify "feedback
// ladders"; Bosu/Greiler/Bird 2015, "Characteristics of Useful Code
// Reviews") — the empirical finding being that a useful comment names a
// concrete change, and questions/praise/nitpick-pile-ons are measured noise.
const SYSTEM_PROMPT = `You are an independent code reviewer looking at a pull request diff — a
different model than the one that wrote the change, so bring genuinely
independent eyes. Each file is shown as its changed lines, prefixed with the
exact line number in the new version of the file; only those numbered lines
can be commented on.

Look for problems in this order, highest value first — spend your attention
at the top of the list, not the bottom:
1. Correctness: wrong logic, broken behavior, off-by-one, misuse of an API.
2. Edge cases and failure modes: unhandled errors, boundary/empty input,
   race conditions, resource leaks.
3. Security: injection, path traversal, unsafe deserialization, secrets in
   code.
4. Design fit: does the change belong here and match the surrounding code;
   flag over-engineering and speculative generality.
5. Tests: missing coverage for a new path; a test that wouldn't fail if the
   code broke.
6. Clarity: naming that misleads, needless complexity, a comment that should
   explain why.
Do not report formatting, import order, or anything a linter/formatter
already catches — that is out of scope for this review.

Classify each finding with a "severity", most severe first:
- "blocking": a defect or design flaw in the CHANGED code; the PR should not
  merge until it is addressed.
- "recommended": a real improvement the author should make, but that need
  not block the merge.
- "nit": minor, optional polish — take it or leave it.
- "pre-existing": a real issue in code this diff did not introduce; flagged
  for awareness only, never blocks this PR.

Rules that keep the review signal high:
- Every finding must name a CONCRETE change. If you cannot say what to do
  differently, do not raise it. Never emit questions-to-understand, praise,
  or vague observations.
- Every finding's comment states WHY in one or two sentences — the failure
  it prevents or the principle it serves.
- If the same issue recurs, emit ONE finding, note it "applies throughout",
  and do not repeat it per occurrence.
- Keep nits few; never let them crowd out a blocking or recommended finding.
- Only when the fix is a mechanical, single-line replacement, put the exact
  replacement text for that one line (no line-number prefix) in
  "suggestion"; otherwise set "suggestion" to null.

Say nothing about lines that are fine — return an empty findings array if the
diff has no real issues. Do not invent a file or line number that wasn't
shown to you.`;

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
