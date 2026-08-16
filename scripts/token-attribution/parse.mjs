// Pure parsing/attribution logic over Claude Code transcript JSONL — the data
// engine #476 (per-spike accounting) and the #431 weekly snapshot consume.
// No I/O here; see cli.mjs for reading real transcript files.
//
// Claude Code writes one JSONL line per content block, not per message: a
// three-block assistant turn (thinking + text + tool_use) appears as three
// lines sharing the same message.id and an identical, already-final
// message.usage. Naively summing every line triple-counts tokens — dedupeMessages
// collapses those lines back into one message per id before any attribution math.

const ISSUE_BRANCH_RE = /(?:^|[/-])(?:issue|fix)-(\d+)(?:[-/]|$)/;

/**
 * Best-effort text length of a content block, used only to weight the
 * per-activity split (no real tokenizer — see #517's acceptance: approximate
 * is fine, the split just needs to be real).
 *
 * Caveat verified against real transcripts: stored `thinking` blocks always
 * carry empty text (redacted; only the signature is kept), so this always
 * weights them at 0 — their real output tokens land on whichever other
 * block shares the message, or in activitySplit's fallback bucket if none
 * does. Thinking is systematically undercounted as its own axis; there's no
 * way to recover it from the transcript as currently written.
 * @param {object} block
 * @returns {number}
 */
function blockWeight(block) {
  if (!block || typeof block !== "object") return 0;
  if (typeof block.thinking === "string") return block.thinking.length;
  if (typeof block.text === "string") return block.text.length;
  if (block.type === "tool_use") {
    try {
      return JSON.stringify(block.input ?? {}).length + (block.name?.length ?? 0);
    } catch {
      return 0;
    }
  }
  return 0;
}

/**
 * Collapses per-block transcript lines into one entry per assistant message
 * id. Tolerant of unrelated record types, missing fields, and unrecognized
 * block types — those contribute zero weight rather than throwing.
 * @param {object[]} records - parsed JSONL records (any `type`)
 * @returns {{id: string, cwd: string|null, gitBranch: string|null, usage: object, weights: Record<string, number>}[]}
 */
export function dedupeMessages(records) {
  const byId = new Map();
  for (const record of records) {
    if (record?.type !== "assistant") continue;
    const message = record.message;
    const id = message?.id;
    const usage = message?.usage;
    if (!id || !usage) continue;

    let entry = byId.get(id);
    if (!entry) {
      entry = {
        id,
        cwd: record.cwd ?? null,
        gitBranch: record.gitBranch ?? null,
        usage,
        weights: { thinking: 0, text: 0, tool_use: 0 },
      };
      byId.set(id, entry);
    }

    for (const block of message.content ?? []) {
      const bucket = block?.type;
      if (bucket === "thinking" || bucket === "text" || bucket === "tool_use") {
        entry.weights[bucket] += blockWeight(block);
      }
    }
  }
  return [...byId.values()];
}

/**
 * Aggregates output tokens by activity (thinking/text/tool_use, split
 * proportional to each message's block-length weights) plus the
 * context-carriage axes (cache_read, cache_creation, input) as message-level
 * totals — cache reuse isn't a block, so it isn't split across activities.
 * @param {ReturnType<typeof dedupeMessages>} messages
 */
export function activitySplit(messages) {
  const totals = { thinking: 0, text: 0, tool_use: 0, cache_read: 0, cache_creation: 0, input: 0 };
  for (const { usage, weights } of messages) {
    const output = usage.output_tokens ?? 0;
    const totalWeight = weights.thinking + weights.text + weights.tool_use;
    if (totalWeight > 0) {
      totals.thinking += (output * weights.thinking) / totalWeight;
      totals.text += (output * weights.text) / totalWeight;
      totals.tool_use += (output * weights.tool_use) / totalWeight;
    } else {
      // No recognized block carried this message's output — attribute it to
      // `text` rather than silently dropping tokens from the total.
      totals.text += output;
    }
    totals.cache_read += usage.cache_read_input_tokens ?? 0;
    totals.cache_creation += usage.cache_creation_input_tokens ?? 0;
    totals.input += usage.input_tokens ?? 0;
  }
  for (const key of Object.keys(totals)) totals[key] = Math.round(totals[key]);
  return totals;
}

/**
 * Extracts an issue number from this repo's `issue-NNN`/`fix-NNN` branch
 * convention. Returns null for branches that don't carry one (e.g. `main`,
 * `feat/inline-fill`) rather than guessing.
 * @param {string|null} branch
 * @returns {number|null}
 */
export function issueFromBranch(branch) {
  if (!branch) return null;
  const match = branch.match(ISSUE_BRANCH_RE);
  return match ? Number(match[1]) : null;
}

/**
 * Per-issue rollup: total output + cache-read tokens per branch, keyed by
 * issue number where the branch matches the convention, else by the raw
 * branch name (so nothing silently vanishes from the total).
 * @param {ReturnType<typeof dedupeMessages>} messages
 */
export function issueRollup(messages) {
  const byKey = new Map();
  for (const { usage, gitBranch } of messages) {
    const issue = issueFromBranch(gitBranch);
    const key = issue !== null ? `issue-${issue}` : (gitBranch ?? "unknown");
    const entry = byKey.get(key) ?? { issue, branch: gitBranch, output_tokens: 0, cache_read_tokens: 0 };
    entry.output_tokens += usage.output_tokens ?? 0;
    entry.cache_read_tokens += usage.cache_read_input_tokens ?? 0;
    byKey.set(key, entry);
  }
  return [...byKey.values()].sort((a, b) => b.output_tokens - a.output_tokens);
}

/**
 * Builds the full JSON report from raw parsed transcript records — the
 * shape #476 and the weekly snapshot consume.
 * @param {object[]} records
 */
export function buildReport(records) {
  const messages = dedupeMessages(records);
  return {
    message_count: messages.length,
    activity: activitySplit(messages),
    by_issue: issueRollup(messages),
  };
}
