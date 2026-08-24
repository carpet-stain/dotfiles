#!/usr/bin/env node
// Cross-repo "what's next" engine (#669 Phase 1): extracts ADR-0040's live
// computation (amended by ADR-0052) into a committed, reusable script
// instead of re-deriving it by hand every grooming session. Pure
// traversal/ordering logic below; `gh` I/O lives in the CLI shell at the
// bottom — see scripts/token-attribution/parse.mjs for the split this
// follows.
//
// Membership is the anchor's transitive closure over three native
// sources — (a) GraphQL sub-issues, (b) checkbox task-list leading-token
// references, (c) native blocked-by/blocking links — with no free-text body
// scraping outside (b)'s checkbox lines (ADR-0040, narrowed by #669's
// round-4/round-8 plan review: body-wide scraping would pull in every issue
// an epic's prose merely mentions). The ADR-0052 dedicated-repo manifest
// union (#669 Phase 3) is a second membership source behind the same
// interface — buildProjectReport wires it in via project-manifest.yaml.

const PRIORITY_LABELS = ["priority: high", "priority: medium", "priority: low"];
const PRIORITY_RANK = { high: 0, medium: 1, low: 2, none: 3 };

/** @param {{name: string}[]|undefined} labels */
export function priorityFromLabels(labels) {
  const names = new Set((labels ?? []).map((label) => label.name));
  for (const label of PRIORITY_LABELS) {
    if (names.has(label)) return label.slice("priority: ".length);
  }
  return "none";
}

// A GFM task-list line: "- [ ] ...", "* [ ] ...", or "+ [ ] ...", any
// indentation — GFM accepts all three unordered-list markers.
const CHECKBOX_LINE_RE = /^\s*[-*+]\s+\[[ xX]\]\s+(.*)$/;
// Leading issue reference: bare `#N` or `owner/repo#N` as the first token.
// Markdown-linked, bare-URL, and emphasis/emoji-prefixed forms are deferred
// to #669 Phase 1b's amendment ADR (not yet written) — unsupported here.
const LEADING_REF_RE = /^(?:([a-zA-Z0-9_.-]+)\/([a-zA-Z0-9_.-]+)#(\d+)|#(\d+))(?=\s|$)/;

// GitHub owner/repo names are case-insensitive; identity has to be too, or
// differently-cased references to one repo traverse as distinct nodes.
function refKey({ repo, number }) {
  return `${repo.toLowerCase()}#${number}`;
}

function dedupeRefs(refs) {
  const seen = new Set();
  const out = [];
  for (const ref of refs) {
    const key = refKey(ref);
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(ref);
  }
  return out;
}

/**
 * Source (b): checkbox task-list lines whose leading token is an issue
 * reference. A reference elsewhere in a checkbox's text — or in any
 * non-checkbox prose — doesn't count; this is what keeps a merely-mentioned
 * issue (e.g. an anchor's own parent) off the board.
 * @param {string|undefined} body
 * @param {string} containingRepo - repo a bare `#N` resolves to
 * @param {string} [ownerScope] - when set, an `owner/repo#N` ref outside
 *   this owner is dropped rather than resolved as same-owner (ADR-0040's
 *   system is single-org; a foreign-owner ref must never be silently
 *   treated as one of this org's repos)
 * @returns {{repo: string, number: number}[]}
 */
export function parseTaskListRefs(body, containingRepo, ownerScope) {
  const refs = [];
  for (const line of (body ?? "").split("\n")) {
    const checkbox = line.match(CHECKBOX_LINE_RE);
    if (!checkbox) continue;
    const match = checkbox[1].match(LEADING_REF_RE);
    if (!match) continue;
    if (match[1]) {
      if (ownerScope && match[1].toLowerCase() !== ownerScope.toLowerCase()) continue;
      refs.push({ repo: match[2], number: Number(match[3]) });
    } else {
      refs.push({ repo: containingRepo, number: Number(match[4]) });
    }
  }
  return dedupeRefs(refs);
}

/**
 * Recursive membership traversal (ADR-0040): from the anchor, collect
 * members from sub-issues, checkbox leading-refs, and native blocked-by/
 * blocking links, until no new issue appears. `fetchIssue(repo, number)` is
 * injected so this stays I/O-free and testable against fixtures; a target
 * that fails to fetch (404, access error) is recorded in `errored` rather
 * than silently dropped, so blockedness resolution can still see it.
 *
 * `fetchIssue` must return `subIssues`/`blockedBy`/`blocking` already
 * owner-scoped (a URL-parsing boundary concern — see `ghFetchIssue`'s
 * `toRefs`); this doesn't re-validate them. Only checkbox refs (source b,
 * parsed from raw body text) get re-validated here, via `ownerScope`.
 * @param {{repo: string, number: number}} anchor
 * @param {(repo: string, number: number) => Promise<object>} fetchIssue
 * @param {string} [ownerScope] - forwarded to parseTaskListRefs
 */
export async function computeMembership(anchor, fetchIssue, ownerScope) {
  const members = new Map();
  const errored = new Set();
  const queued = new Set([refKey(anchor)]);
  const queue = [anchor];

  while (queue.length > 0) {
    const ref = queue.shift();
    let node;
    try {
      node = await fetchIssue(ref.repo, ref.number);
    } catch {
      errored.add(refKey(ref));
      continue;
    }
    members.set(refKey(ref), node);

    const discovered = [
      ...(node.subIssues ?? []),
      ...parseTaskListRefs(node.body, node.repo, ownerScope),
      ...(node.blockedBy ?? []),
      ...(node.blocking ?? []),
    ];
    for (const next of discovered) {
      const key = refKey(next);
      if (queued.has(key)) continue;
      queued.add(key);
      queue.push(next);
    }
  }

  return { members, errored };
}

/**
 * Blockedness is a separate pass from membership: every blocked-by target's
 * live state decides status, whether or not that target ended up a member.
 * A target that never resolved (404/error) counts as blocking — never
 * defaulted to Ready.
 * @param {{state: string, blockedBy?: {repo: string, number: number}[]}} node
 * @param {Map<string, {state: string}>} membersByKey
 * @param {Set<string>} erroredKeys
 */
export function resolveStatus(node, membersByKey, erroredKeys) {
  if (node.state === "CLOSED") return "Done";
  const isBlocked = (node.blockedBy ?? []).some((ref) => {
    const key = refKey(ref);
    if (erroredKeys.has(key)) return true;
    const target = membersByKey.get(key);
    return target ? target.state !== "CLOSED" : true;
  });
  return isBlocked ? "Blocked" : "Ready";
}

/**
 * Priority-aware topological order over `blockedBy` edges restricted to the
 * member set (a blocker outside the set can't be ranked, so its edge is
 * ignored here — it still drove `resolveStatus` above). Ties break by the
 * `priority:` ladder, then by (repo, number). A cycle among the remaining
 * nodes stalls normal progress; broken deterministically by (repo, number)
 * and reported as a warning rather than looping forever.
 * @param {{repo: string, number: number, priority: string, blockedBy?: {repo: string, number: number}[]}[]} nodes
 */
export function orderQueue(nodes) {
  const byKey = new Map(nodes.map((node) => [refKey(node), node]));
  const indegree = new Map(nodes.map((node) => [refKey(node), 0]));
  const successors = new Map(nodes.map((node) => [refKey(node), []]));

  for (const node of nodes) {
    for (const blockerRef of node.blockedBy ?? []) {
      const blockerKey = refKey(blockerRef);
      const blocker = byKey.get(blockerKey);
      // A closed blocker imposes no ordering constraint — same live-state
      // read resolveStatus uses, so an already-done blocker doesn't hold a
      // dependent back from ranking early.
      if (!blocker || blocker.state === "CLOSED") continue;
      indegree.set(refKey(node), indegree.get(refKey(node)) + 1);
      successors.get(blockerKey).push(refKey(node));
    }
  }

  const byRepoNumber = (a, b) => {
    const na = byKey.get(a);
    const nb = byKey.get(b);
    if (na.repo !== nb.repo) return na.repo < nb.repo ? -1 : 1;
    return na.number - nb.number;
  };
  const byPriorityThenRepoNumber = (a, b) => {
    const pr = PRIORITY_RANK[byKey.get(a).priority] - PRIORITY_RANK[byKey.get(b).priority];
    return pr !== 0 ? pr : byRepoNumber(a, b);
  };

  const remaining = new Set(byKey.keys());
  const ordered = [];
  const warnings = [];

  while (remaining.size > 0) {
    const ready = [...remaining].filter((key) => indegree.get(key) === 0);
    let next;
    if (ready.length > 0) {
      next = ready.sort(byPriorityThenRepoNumber)[0];
    } else {
      next = [...remaining].sort(byRepoNumber)[0];
      warnings.push({ type: "cycle", forced: { repo: byKey.get(next).repo, number: byKey.get(next).number } });
    }
    ordered.push(next);
    remaining.delete(next);
    for (const successor of successors.get(next)) {
      if (remaining.has(successor)) indegree.set(successor, indegree.get(successor) - 1);
    }
  }

  const queue = ordered.map((key, index) => ({ ...byKey.get(key), rank: index + 1 }));
  return { queue, warnings };
}

function finalizeReport(members, errored) {
  const nodes = [...members.values()].map((node) => ({
    id: node.id,
    repo: node.repo,
    number: node.number,
    title: node.title,
    state: node.state,
    priority: priorityFromLabels(node.labels),
    blockedBy: node.blockedBy ?? [],
  }));
  const byKey = new Map(nodes.map((node) => [refKey(node), node]));
  for (const node of nodes) node.status = resolveStatus(node, byKey, errored);
  const { queue, warnings } = orderQueue(nodes);
  return { queue, warnings, errored: [...errored] };
}

/**
 * Full pipeline: traverse membership, resolve status, order the result. The
 * anchor itself failing to fetch throws — a report about nothing isn't a
 * result. A descendant reference failing doesn't throw (it's still recorded
 * in `errored`, still drives `resolveStatus`), but the caller gets it back
 * so a partial traversal can never be mistaken for a complete one.
 * @param {{repo: string, number: number}} anchor
 * @param {(repo: string, number: number) => Promise<object>} fetchIssue
 * @param {string} [ownerScope] - forwarded to computeMembership
 */
export async function buildReport(anchor, fetchIssue, ownerScope) {
  const { members, errored } = await computeMembership(anchor, fetchIssue, ownerScope);
  if (!members.has(refKey(anchor))) {
    throw new Error(`project-queue: couldn't fetch anchor ${refKey(anchor)}`);
  }
  return finalizeReport(members, errored);
}

// --- ADR-0052 dedicated-repo union (#669 Phase 3) --------------------------
//
// A dedicated repo exists solely to serve one project: every one of its
// open issues joins membership by default, no upward link to the anchor
// required. The manifest (project-manifest.yaml) is the authoritative,
// committed source for which repos are dedicated to which anchor — never
// the memory graph (ADR-0046 forbids a CI workflow reading the
// backlog-manager's private store).

const MANIFEST_ANCHOR_RE = /^\s*-\s*anchor:\s*(\S+)\s*$/;
const MANIFEST_DEDICATED_REPOS_HEADER_RE = /^\s*dedicated_repos:\s*$/;
const MANIFEST_REPO_ITEM_RE = /^\s*-\s*(\S+)\s*$/;

/**
 * Parses project-manifest.yaml's fixed, committed shape (ADR-0052):
 * `projects: [{anchor: "<repo>#<number>", dedicated_repos: [...]}]`. Not a
 * general YAML parser — the schema is small and fixed on purpose, and this
 * repo carries no YAML dependency (see check-project-manifest.sh, which
 * validates the same shape in bash for the same reason).
 * @param {string|undefined} yamlText
 * @returns {{anchor: string, dedicatedRepos: string[]}[]}
 */
export function parseProjectManifest(yamlText) {
  const projects = [];
  let current = null;
  let inRepos = false;
  for (const line of (yamlText ?? "").split("\n")) {
    if (/^\s*#/.test(line) || line.trim() === "") continue;
    const anchorMatch = line.match(MANIFEST_ANCHOR_RE);
    if (anchorMatch) {
      current = { anchor: anchorMatch[1], dedicatedRepos: [] };
      projects.push(current);
      inRepos = false;
      continue;
    }
    if (MANIFEST_DEDICATED_REPOS_HEADER_RE.test(line)) {
      inRepos = true;
      continue;
    }
    if (inRepos && current) {
      const repoMatch = line.match(MANIFEST_REPO_ITEM_RE);
      if (repoMatch) {
        current.dedicatedRepos.push(repoMatch[1]);
        continue;
      }
      inRepos = false;
    }
  }
  return projects;
}

/**
 * Wholesale membership from every open issue in each dedicated repo.
 * `listOpenIssues(repo)` failing marks that repo `errored` (as
 * `dedicated:<repo>`) rather than aborting the whole run — same
 * never-silently-complete contract as computeMembership's per-ref errors.
 * @param {string[]} dedicatedRepos
 * @param {(repo: string) => Promise<{repo: string, number: number}[]>} listOpenIssues
 * @param {(repo: string, number: number) => Promise<object>} fetchIssue
 */
export async function computeDedicatedMembers(dedicatedRepos, listOpenIssues, fetchIssue) {
  const members = new Map();
  const errored = new Set();
  for (const repo of dedicatedRepos) {
    let refs;
    try {
      refs = await listOpenIssues(repo);
    } catch {
      errored.add(`dedicated:${repo.toLowerCase()}`);
      continue;
    }
    for (const ref of refs) {
      const key = refKey(ref);
      if (members.has(key)) continue;
      try {
        members.set(key, await fetchIssue(ref.repo, ref.number));
      } catch {
        errored.add(key);
      }
    }
  }
  return { members, errored };
}

/**
 * buildReport's ADR-0040 closure, unioned with ADR-0052's dedicated-repo
 * members. Omit `dedicatedRepos` (or pass an empty array) to get exactly
 * buildReport's behavior — this is additive, not a replacement.
 * @param {{repo: string, number: number}} anchor
 * @param {(repo: string, number: number) => Promise<object>} fetchIssue
 * @param {string} [ownerScope]
 * @param {{dedicatedRepos?: string[], listOpenIssues?: (repo: string) => Promise<{repo: string, number: number}[]>}} [options]
 */
export async function buildProjectReport(anchor, fetchIssue, ownerScope, { dedicatedRepos = [], listOpenIssues } = {}) {
  const { members, errored } = await computeMembership(anchor, fetchIssue, ownerScope);
  if (!members.has(refKey(anchor))) {
    throw new Error(`project-queue: couldn't fetch anchor ${refKey(anchor)}`);
  }
  if (dedicatedRepos.length > 0) {
    if (!listOpenIssues) throw new Error("project-queue: dedicatedRepos given without a listOpenIssues fetcher");
    const dedicated = await computeDedicatedMembers(dedicatedRepos, listOpenIssues, fetchIssue);
    for (const [key, node] of dedicated.members) if (!members.has(key)) members.set(key, node);
    for (const key of dedicated.errored) errored.add(key);
  }
  return finalizeReport(members, errored);
}

// --- CLI shell (I/O) -------------------------------------------------------

// Parses via the URL API and checks an exact hostname, not a substring
// match — "notgithub.com" must never be accepted as "github.com".
function issueUrlParts(arg) {
  let parsed;
  try {
    parsed = new URL(arg);
  } catch {
    return null;
  }
  if (parsed.hostname !== "github.com") return null;
  const match = parsed.pathname.match(/^\/([^/]+)\/([^/]+)\/issues\/(\d+)$/);
  return match ? { owner: match[1], repo: match[2], number: Number(match[3]) } : null;
}

function parseAnchorArg(arg) {
  const url = issueUrlParts(arg);
  if (url) return url;
  const shortMatch = arg.match(/^([^/]+)\/([^/]+)#(\d+)$/);
  if (shortMatch) return { owner: shortMatch[1], repo: shortMatch[2], number: Number(shortMatch[3]) };
  throw new Error(`project-queue: anchor must be owner/repo#number or an issue URL, got: ${arg}`);
}

function ownerRepoFromIssueUrl(url) {
  const parts = issueUrlParts(url);
  if (!parts) throw new Error(`project-queue: couldn't parse owner/repo from url: ${url}`);
  return { owner: parts.owner, repo: parts.repo };
}

async function ghFetchIssue(execFileAsync, owner, repo, number) {
  const { stdout } = await execFileAsync("gh", [
    "issue",
    "view",
    `https://github.com/${owner}/${repo}/issues/${number}`,
    "--json",
    "id,number,title,state,body,labels,blockedBy,blocking,subIssues",
  ]);
  const raw = JSON.parse(stdout);
  // A ref outside `owner` is dropped, never silently fetched as if it were
  // this org's same-named repo — ADR-0040's system is single-org by design.
  const toRefs = (connection) =>
    (connection?.nodes ?? [])
      .map((node) => ({ ...ownerRepoFromIssueUrl(node.url), number: node.number }))
      .filter((ref) => {
        if (ref.owner.toLowerCase() === owner.toLowerCase()) return true;
        console.error(`project-queue: dropping cross-owner reference ${ref.owner}/${ref.repo}#${ref.number} (scoped to ${owner})`);
        return false;
      })
      .map(({ repo, number }) => ({ repo, number }));
  return {
    // GraphQL node id — carried through to the final report so #669 Phase
    // 3's sync can add a board item (addProjectV2ItemById) without a
    // second per-issue lookup.
    id: raw.id,
    repo,
    number: raw.number,
    title: raw.title,
    state: raw.state,
    body: raw.body,
    labels: raw.labels,
    blockedBy: toRefs(raw.blockedBy),
    blocking: toRefs(raw.blocking),
    subIssues: toRefs(raw.subIssues),
  };
}

async function ghListOpenIssues(execFileAsync, owner, repo) {
  const { stdout } = await execFileAsync("gh", ["issue", "list", "--repo", `${owner}/${repo}`, "--state", "open", "--json", "number", "--limit", "500"]);
  return JSON.parse(stdout).map((issue) => ({ repo, number: issue.number }));
}

// Relative to CWD, matching check-project-manifest.sh's own convention —
// both assume they run from the repo root. Missing file (most repos have
// none) is not an error: no dedicated-repo union for this anchor, same as
// buildReport's plain closure.
async function readProjectManifest() {
  const fs = await import("node:fs/promises");
  try {
    return parseProjectManifest(await fs.readFile("project-manifest.yaml", "utf8"));
  } catch {
    return [];
  }
}

async function main() {
  const arg = process.argv[2];
  if (!arg) throw new Error("usage: project-queue.mjs <owner>/<repo>#<number> | <issue-url>");

  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  const execFileAsync = promisify(execFile);

  const { owner, repo, number } = parseAnchorArg(arg);
  const fetchIssue = (r, n) => ghFetchIssue(execFileAsync, owner, r, n);
  const manifest = await readProjectManifest();
  const dedicatedRepos = manifest.find((p) => p.anchor === `${repo}#${number}`)?.dedicatedRepos ?? [];
  const listOpenIssues = (r) => ghListOpenIssues(execFileAsync, owner, r);

  const { queue, warnings, errored } =
    dedicatedRepos.length > 0
      ? await buildProjectReport({ repo, number }, fetchIssue, owner, { dedicatedRepos, listOpenIssues })
      : await buildReport({ repo, number }, fetchIssue, owner);

  for (const warning of warnings) {
    console.error(`project-queue: cycle detected, broke deterministically at ${warning.forced.repo}#${warning.forced.number}`);
  }
  for (const key of errored) {
    console.error(`project-queue: couldn't fetch ${key} — traversal is incomplete`);
  }
  console.log(JSON.stringify(queue, null, 2));
  if (errored.length > 0) process.exit(1);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err.stack || String(err));
    process.exit(1);
  });
}
