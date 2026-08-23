#!/usr/bin/env node
// Post-spawn artifact-mismatch check for agent-runner.yml (#691). Nothing
// structurally stops a spawned role from reading the whole thread —
// including the other role's past turns — and producing the OTHER role's
// artifact instead of its own: a drafter (backlog-manager) free-running into
// a critique is the exact failure observed on #669 (run 32652468923),
// posted as an apparently-independent review that wasn't. Mechanical,
// because trusting the model's own self-report is what already failed once.
//
// Scoped to the one direction seen in practice: backlog-manager producing a
// critique. plan-reviewer.md's Output contract documents a "Verdict" line
// as the reviewer's own artifact shape — a plan draft has no legitimate
// reason to carry one.

const VERDICT_LINE = /\*{0,2}verdict\*{0,2}\s*:/i;

export function detectArtifactMismatch(role, responseText) {
  if (role !== "backlog-manager") return { mismatched: false, reason: null };
  if (VERDICT_LINE.test(responseText)) {
    return {
      mismatched: true,
      reason:
        "backlog-manager's response carries a 'Verdict:' line — that's plan-reviewer's documented output contract (.claude/agents/plan-reviewer.md), not the drafter's own artifact",
    };
  }
  return { mismatched: false, reason: null };
}

// --- CLI shell (I/O) -------------------------------------------------------

async function main() {
  const { ROLE, RESPONSE_FILE } = process.env;
  if (!ROLE || !RESPONSE_FILE) {
    throw new Error("agent-artifact-guard: missing required env var ROLE or RESPONSE_FILE");
  }

  const fs = await import("node:fs");
  const responseText = fs.readFileSync(RESPONSE_FILE, "utf8");
  const result = detectArtifactMismatch(ROLE, responseText);

  if (result.mismatched) {
    console.error(`::error::agent-artifact-guard: ${result.reason} — refusing to post.`);
    process.exit(1);
  }
  console.log(`agent-artifact-guard: ${ROLE}'s response matches its own artifact`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err.stack || String(err));
    process.exit(1);
  });
}
