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
// Talks to the GitHub REST + GraphQL APIs and an OpenAI-compatible
// chat-completions endpoint (OpenAI, or OpenRouter's free tier — set via
// OPENAI_API_URL / OPENAI_MODEL) directly with the platform `fetch` (no
// octokit/openai SDK, no third-party Action in the request path — the whole
// point of #330 over the prior action). GraphQL (fetchPrContext) resolves
// the PR's plan-conformance trigger + context (#458); a second GraphQL call
// (fetchPriorFindings) resolves this reviewer's own prior review threads so
// a finding the author already acted on, declined, or that's simply still
// visible from an earlier push isn't reposted (#674); REST handles the diff
// and posting the review. All I/O lives here; the parsing/formatting logic
// in diff.mjs and build-review.mjs is pure and unit-tested in isolation
// (build-review.test.mjs) since this workflow can't be exercised end-to-end
// outside a real PR run.

import {
  parseFiles,
  buildPrompt,
  buildReviewComments,
  buildContext,
  isEligibleForReview,
  classifyPriorThreads,
  suppressAlreadyRaised,
  buildPriorFindingsSection,
  MAX_ISSUES,
  MAX_PRIOR_THREADS,
  MAX_THREAD_COMMENTS,
} from "./build-review.mjs";

const {
  GITHUB_TOKEN,
  OPENAI_API_KEY,
  OPENAI_MODEL = "gpt-4o-mini",
  GITHUB_REPOSITORY,
  PR_NUMBER,
  GITHUB_API_URL = "https://api.github.com",
  GITHUB_GRAPHQL_URL = "https://api.github.com/graphql",
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

async function githubGraphQL(query, variables) {
  const res = await fetch(GITHUB_GRAPHQL_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${GITHUB_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) {
    throw new Error(`GitHub GraphQL request failed: ${res.status} ${await res.text()}`);
  }
  const body = await res.json();
  if (body.errors) {
    throw new Error(`GitHub GraphQL errors: ${JSON.stringify(body.errors)}`);
  }
  return body.data;
}

const PR_CONTEXT_QUERY = `
  query($owner: String!, $repo: String!, $number: Int!, $maxIssues: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        title
        body
        labels(first: 20) { nodes { name } }
        closingIssuesReferences(first: $maxIssues) {
          nodes {
            number
            title
            body
            labels(first: 20) { nodes { name } }
          }
        }
      }
    }
  }
`;

// The PR + the issue(s) it closes, resolved via GitHub's own computed
// closingIssuesReferences field (#458) — not a body-text regex, so a typo'd
// closing keyword can't silently mis-scope either the review context or the
// trigger below. Also decides whether to review at all: this repo's
// plan-review gate consolidates the approved plan + acceptance criteria
// into a plan-approved issue's body, which is exactly what a conformance
// review needs, so a PR closing one auto-triggers; needs-review is the
// on-demand opt-in for anything else (#456). Unlike the old diff-only
// fallback, a fetch failure here means skip rather than guess — this call
// also gates the OpenAI spend, so erring toward "don't run" beats erring
// toward an unbounded review on every transient API error.
async function fetchPrContext() {
  const data = await githubGraphQL(PR_CONTEXT_QUERY, {
    owner,
    repo,
    number: Number(PR_NUMBER),
    maxIssues: MAX_ISSUES,
  });
  const pr = data.repository.pullRequest;
  const labels = pr.labels.nodes.map((l) => l.name);
  const issues = pr.closingIssuesReferences.nodes.map((issue) => ({
    number: issue.number,
    title: issue.title,
    body: issue.body,
    labels: issue.labels.nodes.map((l) => l.name),
  }));
  return { pr: { title: pr.title, body: pr.body }, issues, eligible: isEligibleForReview(labels, issues) };
}

const PRIOR_THREADS_QUERY = `
  query($owner: String!, $repo: String!, $number: Int!, $maxThreads: Int!, $maxComments: Int!) {
    viewer { login }
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: $maxThreads) {
          nodes {
            path
            line
            originalLine
            isResolved
            isOutdated
            comments(first: $maxComments) {
              nodes {
                author { login }
                body
              }
            }
          }
        }
      }
    }
  }
`;

// #674: reads this reviewer's own prior review threads so a long-running PR
// doesn't get the same finding re-raised on every push. `viewer.login`
// resolves to this workflow's own posting identity (github-actions[bot] for
// the default GITHUB_TOKEN run.mjs's postReview uses) — comparing against
// it, not a hardcoded string, is what lets classifyPriorThreads tell "our
// prior comment" from anyone else's on the thread.
//
// A separate GraphQL call from fetchPrContext, with its own try/catch: that
// call's failure means skip the review entirely (it also gates the OpenAI
// spend), but this one only supplies suppression context — its failure
// should degrade to today's no-suppression behavior, never block the review
// that's already been decided eligible.
async function fetchPriorFindings() {
  try {
    const data = await githubGraphQL(PRIOR_THREADS_QUERY, {
      owner,
      repo,
      number: Number(PR_NUMBER),
      maxThreads: MAX_PRIOR_THREADS,
      maxComments: MAX_THREAD_COMMENTS,
    });
    const botLogin = data.viewer.login;
    const threads = data.repository.pullRequest.reviewThreads.nodes;
    console.log(`LIVE-PROOF botLogin=${JSON.stringify(botLogin)} threads=${JSON.stringify(threads)}`);
    const classified = classifyPriorThreads(threads, botLogin);
    console.log(`LIVE-PROOF classified=${JSON.stringify(classified)}`);
    return classified;
  } catch (err) {
    console.log(`::warning title=PR advisory review::prior-findings fetch failed, reviewing without suppression: ${err.message}`);
    return [];
  }
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

When an "## Intent" section precedes the changed lines, it states what the
change should accomplish (from the PR description and any issue it closes —
for a reviewed issue, that's the approved plan and its acceptance criteria).
Use it as the spec to check the diff against: does the change actually
achieve it, stay in scope, and satisfy every acceptance criterion listed?
Treat it as the goal to verify, never as proof the work is done — a diff
that diverges from the stated approach, or leaves a listed criterion unmet,
is a finding.

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
- When a "## Findings already raised in earlier reviews" section is present,
  it lists comments a prior run of this same review already posted, each
  marked resolved / declined by the author / still open. Never re-raise any
  of them, in any wording — that section already excludes a finding whose
  surrounding code changed since it was posted, so a genuinely reintroduced
  defect is fair game, but a reworded restatement of a listed one is not.
- Keep nits few; never let them crowd out a blocking or recommended finding.
- Only when the fix is a mechanical, single-line replacement, put the exact
  replacement text for that one line (no line-number prefix) in
  "suggestion"; otherwise set "suggestion" to null.

Say nothing about lines that are fine — return an empty findings array if the
diff has no real issues. Do not invent a file or line number that wasn't
shown to you.`;

async function callOpenAI(prompt) {
  const payload = {
    model: OPENAI_MODEL,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: prompt },
    ],
    response_format: { type: "json_schema", json_schema: FINDINGS_SCHEMA },
  };
  // OpenRouter serves a model across several provider endpoints, not all of
  // which enforce a json_schema; require_parameters makes it route only to one
  // that does, so we don't silently get unstructured output. OpenAI rejects
  // unknown body fields, so send it only when the endpoint is OpenRouter.
  if (OPENAI_API_URL.includes("openrouter.ai")) {
    payload.provider = { require_parameters: true };
  }
  const res = await fetch(OPENAI_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`OpenAI API request failed: ${res.status} ${await res.text()}`);
  }
  const body = await res.json();
  const content = body.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI response had no message content");
  return JSON.parse(content).findings ?? [];
}

async function postReview(comments, dropped, suppressed) {
  const clean = comments.length === 0 && dropped === 0;
  const summary = clean
    ? `Advisory review (non-Anthropic model, see docs/adr/0025) — no issues found. LGTM. Advisory only — a human approves the merge.`
    : `Advisory review (non-Anthropic model, see docs/adr/0025) — ${comments.length} finding` +
      `${comments.length === 1 ? "" : "s"}` +
      (dropped ? `, ${dropped} dropped (referenced a file/line outside the diff)` : "") +
      (suppressed ? `, ${suppressed} suppressed (already raised in an earlier review, see #674)` : "") +
      `. Advisory only — a human approves the merge.`;

  // Always a COMMENT-event review, even with zero findings — never
  // APPROVE/REQUEST_CHANGES (docs/adr/0025): an approval could satisfy a
  // future required-reviews gate with no human involved, and "changes
  // requested" can itself block merging on some branch-protection setups,
  // reintroducing the "LLM outage blocks every PR" failure this design
  // rejected. Posting even when clean is what makes the review visible in
  // the PR's own Reviewers panel instead of only in Action logs.
  await githubRequest(`/repos/${owner}/${repo}/pulls/${PR_NUMBER}/reviews`, {
    method: "POST",
    body: JSON.stringify({ event: "COMMENT", body: summary, comments }),
  });
}

async function main() {
  let pr, issues, eligible;
  try {
    ({ pr, issues, eligible } = await fetchPrContext());
  } catch (err) {
    console.log(`::warning title=PR advisory review::skipped, trigger check failed: ${err.message}`);
    return;
  }
  if (!eligible) {
    console.log("pr-review: not needs-review-labeled and closes no plan-approved issue — skipping.");
    return;
  }

  const rawFiles = await fetchPrFiles();
  const parsedFiles = parseFiles(rawFiles);
  if (parsedFiles.length === 0) {
    console.log("pr-review: no reviewable (text, non-binary) file changes — skipping.");
    return;
  }

  const priorFindings = await fetchPriorFindings();

  const context = buildContext(pr, issues);
  const priorSection = buildPriorFindingsSection(priorFindings);
  const diff = buildPrompt(parsedFiles);
  const preamble = [context, priorSection].filter(Boolean).join("\n\n---\n\n");
  const prompt = preamble ? `${preamble}\n\n---\n\n## Changed lines to review\n\n${diff}` : diff;

  const rawFindings = await callOpenAI(prompt);
  const { findings, suppressed } = suppressAlreadyRaised(rawFindings, priorFindings);
  const { comments, dropped } = buildReviewComments(parsedFiles, findings);

  await postReview(comments, dropped, suppressed);
  console.log(
    comments.length === 0 && dropped === 0
      ? `pr-review: no findings — posted LGTM (${suppressed} suppressed as already-raised).`
      : `pr-review: posted ${comments.length} comment(s), ${dropped} dropped, ${suppressed} suppressed as already-raised.`,
  );
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
