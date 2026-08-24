// Unit tests for the pure, no-I/O half of project-queue.mjs, run with
// Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/*.test.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  priorityFromLabels,
  parseTaskListRefs,
  computeMembership,
  resolveStatus,
  orderQueue,
  buildReport,
  parseProjectManifest,
  computeDedicatedMembers,
  buildProjectReport,
} from "./project-queue.mjs";

// --- priorityFromLabels ------------------------------------------------

test("priorityFromLabels reads the priority: ladder off label objects, defaulting to none", () => {
  assert.equal(priorityFromLabels([{ name: "priority: high" }]), "high");
  assert.equal(priorityFromLabels([{ name: "bug" }, { name: "priority: low" }]), "low");
  assert.equal(priorityFromLabels([{ name: "bug" }]), "none");
  assert.equal(priorityFromLabels(undefined), "none");
});

// --- parseTaskListRefs ---------------------------------------------------
//
// Reconstructs #669's own Prerequisites section as GFM checkboxes. #669's
// live body has since been edited to prose bullets once infra#301/#670/#668
// all closed, but plan-review round 4 and round 8 (the issue's own comment
// thread) confirm the section carried real checkboxes for infra#301 and
// #670 when the fixture claim in the issue body was validated — #668 was
// never one of them, entering membership solely via the native blocked-by
// link. This snapshot restores that shape rather than the current, already-
// resolved prose.
const FIXTURE_BODY_669 = `### Problem

The agent operating model (#545) spans five repos — dotfiles, infra, agents,
project-starter-template, agent-memory-server.

The 2026-08-22 traversal showed the cost of invisibility directly: three \`blocked\` labels had gone
stale, and infra#217 sat at \`priority: low\` while being the single blocker of two epics.

### Membership and ordering contract

Body-wide scraping would have pulled \`#545\`, \`infra#217\` and \`infra#208\` onto the board out of
this issue's own prose.

### Prerequisites

- [ ] carpet-stain/infra#301 — a credential carrying Projects v2 scope. Unconditional.
- [ ] #670 — does a Projects v2 board survive a user→org migration.
- #668 — the dedicated-member-repo union rule, and the committed project manifest it introduces.

### Acceptance

- [ ] Board membership honours #668's union rule, verified by the committed fixtures.
`;

test("parseTaskListRefs yields exactly {infra#301, #670} from #669's reconstructed checkboxes", () => {
  const refs = parseTaskListRefs(FIXTURE_BODY_669, "dotfiles");
  assert.deepEqual(refs, [
    { repo: "infra", number: 301 },
    { repo: "dotfiles", number: 670 },
  ]);
});

test("parseTaskListRefs excludes prose refs (#545, infra#217, infra#208) and a checkbox's non-leading ref (#668)", () => {
  const refs = parseTaskListRefs(FIXTURE_BODY_669, "dotfiles");
  const keys = refs.map((r) => `${r.repo}#${r.number}`);
  assert.equal(keys.includes("dotfiles#545"), false);
  assert.equal(keys.includes("infra#217"), false);
  assert.equal(keys.includes("infra#208"), false);
  assert.equal(keys.includes("dotfiles#668"), false);
});

test("parseTaskListRefs ignores non-checkbox bullets and checked boxes still count", () => {
  const body = `- not a checkbox #999
- [ ] #100 leading ref
- [x] #101 already checked, still leading
- [ ]#102 no space before the ref
`;
  const refs = parseTaskListRefs(body, "dotfiles");
  assert.deepEqual(refs, [
    { repo: "dotfiles", number: 100 },
    { repo: "dotfiles", number: 101 },
  ]);
});

test("parseTaskListRefs accepts all three GFM unordered-list markers, not just `-`", () => {
  const body = `- [ ] #200 dash marker
* [ ] #201 star marker
+ [ ] #202 plus marker
`;
  const refs = parseTaskListRefs(body, "dotfiles");
  assert.deepEqual(refs, [
    { repo: "dotfiles", number: 200 },
    { repo: "dotfiles", number: 201 },
    { repo: "dotfiles", number: 202 },
  ]);
});

test("parseTaskListRefs requires a token boundary after the number — a slug or extension attached to it doesn't count", () => {
  const body = `- [ ] #123-follow-up-notes
- [ ] carpet-stain/infra#456.md
- [ ] #789 a real leading ref
`;
  const refs = parseTaskListRefs(body, "dotfiles");
  assert.deepEqual(refs, [{ repo: "dotfiles", number: 789 }]);
});

test("parseTaskListRefs drops an owner/repo#N ref outside ownerScope instead of resolving it as same-owner", () => {
  const body = "- [ ] carpet-stain/infra#301 — same owner, counts\n- [ ] someoneelse/infra#1 — foreign owner, dropped\n";
  const refs = parseTaskListRefs(body, "dotfiles", "carpet-stain");
  assert.deepEqual(refs, [{ repo: "infra", number: 301 }]);
});

test("parseTaskListRefs compares ownerScope case-insensitively — GitHub owners are", () => {
  const body = "- [ ] Carpet-Stain/infra#301 — differently-cased owner, still counts\n";
  const refs = parseTaskListRefs(body, "dotfiles", "carpet-stain");
  assert.deepEqual(refs, [{ repo: "infra", number: 301 }]);
});

// --- computeMembership ----------------------------------------------------
//
// End-to-end membership union against #669's real link graph: sub-issue
// #670 (source a), checkbox refs infra#301/#670 (source b, via
// FIXTURE_BODY_669), and native blocked-by links infra#301/#668 (source c)
// — matching the issue's own stated union: {#668, #670, infra#301}.
function fixtureFetchIssue669(repo, number) {
  const graph = {
    "dotfiles#669": {
      repo: "dotfiles",
      number: 669,
      title: "epic(claude): materialized project board for the multi-repo overlay",
      state: "OPEN",
      body: FIXTURE_BODY_669,
      labels: [{ name: "priority: high" }],
      subIssues: [{ repo: "dotfiles", number: 670 }],
      blockedBy: [
        { repo: "infra", number: 301 },
        { repo: "dotfiles", number: 668 },
      ],
      blocking: [],
    },
    "dotfiles#670": {
      repo: "dotfiles",
      number: 670,
      title: "spike(claude): does a Projects v2 board survive a user→org migration?",
      state: "CLOSED",
      body: "",
      labels: [],
      subIssues: [],
      blockedBy: [],
      blocking: [],
    },
    "infra#301": {
      repo: "infra",
      number: 301,
      title: "feat(credentials): provision a credential with GitHub Projects v2 scope",
      state: "CLOSED",
      body: "",
      labels: [],
      subIssues: [],
      blockedBy: [],
      blocking: [],
    },
    "dotfiles#668": {
      repo: "dotfiles",
      number: 668,
      title: "docs(adr): amend ADR-0040 — dedicated member repos join a project wholesale",
      state: "CLOSED",
      body: "",
      labels: [],
      subIssues: [],
      blockedBy: [],
      blocking: [],
    },
  };
  const node = graph[`${repo}#${number}`];
  if (!node) return Promise.reject(new Error(`no fixture for ${repo}#${number}`));
  return Promise.resolve(node);
}

test("computeMembership on #669's real link graph unions to exactly {#668, #670, infra#301}", async () => {
  const { members, errored } = await computeMembership({ repo: "dotfiles", number: 669 }, fixtureFetchIssue669);
  assert.deepEqual(
    [...members.keys()].sort(),
    ["dotfiles#668", "dotfiles#669", "dotfiles#670", "infra#301"].sort(),
  );
  assert.equal(errored.size, 0);
});

test("computeMembership dedupes a cycle instead of looping forever", async () => {
  const graph = {
    "dotfiles#1": { repo: "dotfiles", number: 1, state: "OPEN", body: "", labels: [], blockedBy: [{ repo: "dotfiles", number: 2 }] },
    "dotfiles#2": { repo: "dotfiles", number: 2, state: "OPEN", body: "", labels: [], blockedBy: [{ repo: "dotfiles", number: 1 }] },
  };
  const fetchIssue = (r, n) => Promise.resolve(graph[`${r}#${n}`]);
  const { members } = await computeMembership({ repo: "dotfiles", number: 1 }, fetchIssue);
  assert.equal(members.size, 2);
});

test("computeMembership treats two differently-cased refs to the same issue as one member, not two", async () => {
  const graph = {
    "infra#1": {
      repo: "infra",
      number: 1,
      state: "OPEN",
      body: "",
      labels: [],
      blockedBy: [
        { repo: "Infra", number: 2 },
        { repo: "infra", number: 2 },
      ],
    },
    "infra#2": { repo: "infra", number: 2, state: "OPEN", body: "", labels: [], blockedBy: [] },
  };
  let fetchCount2 = 0;
  const fetchIssue = (r, n) => {
    if (n === 2) fetchCount2 += 1;
    return Promise.resolve(graph[`${r.toLowerCase()}#${n}`]);
  };
  const { members } = await computeMembership({ repo: "infra", number: 1 }, fetchIssue);
  assert.equal(members.size, 2);
  assert.equal(fetchCount2, 1, "the two differently-cased refs to #2 should fetch once, not twice");
});

test("computeMembership records a failed fetch in `errored` instead of throwing", async () => {
  const fetchIssue = (repo, number) =>
    number === 1 ? Promise.resolve({ repo, number, state: "OPEN", body: "", labels: [], blockedBy: [{ repo, number: 2 }] }) : Promise.reject(new Error("404"));
  const { members, errored } = await computeMembership({ repo: "dotfiles", number: 1 }, fetchIssue);
  assert.equal(members.size, 1);
  assert.equal(errored.has("dotfiles#2"), true);
});

// --- buildReport: fetch failures never masquerade as a complete result -----

test("buildReport throws when the anchor itself fails to fetch — a report about nothing isn't a result", async () => {
  const fetchIssue = () => Promise.reject(new Error("404"));
  await assert.rejects(() => buildReport({ repo: "dotfiles", number: 1 }, fetchIssue), /couldn't fetch anchor dotfiles#1/);
});

test("buildReport surfaces a descendant fetch failure in `errored` instead of silently completing", async () => {
  const fetchIssue = (repo, number) =>
    number === 1
      ? Promise.resolve({ repo, number, state: "OPEN", body: "", labels: [], blockedBy: [{ repo, number: 2 }] })
      : Promise.reject(new Error("404"));
  const { queue, errored } = await buildReport({ repo: "dotfiles", number: 1 }, fetchIssue);
  assert.deepEqual(errored, ["dotfiles#2"]);
  assert.equal(queue.find((n) => n.number === 1).status, "Blocked");
});

// --- resolveStatus ---------------------------------------------------------

test("resolveStatus: closed issue is Done regardless of blockers", () => {
  const node = { state: "CLOSED", blockedBy: [{ repo: "infra", number: 1 }] };
  assert.equal(resolveStatus(node, new Map(), new Set()), "Done");
});

test("resolveStatus: open issue with no blockers is Ready", () => {
  const node = { state: "OPEN", blockedBy: [] };
  assert.equal(resolveStatus(node, new Map(), new Set()), "Ready");
});

test("resolveStatus: an open blocked-by target blocks; a closed one doesn't", () => {
  const members = new Map([
    ["infra#1", { state: "OPEN" }],
    ["infra#2", { state: "CLOSED" }],
  ]);
  const blockedByOpen = { state: "OPEN", blockedBy: [{ repo: "infra", number: 1 }] };
  const blockedByClosed = { state: "OPEN", blockedBy: [{ repo: "infra", number: 2 }] };
  assert.equal(resolveStatus(blockedByOpen, members, new Set()), "Blocked");
  assert.equal(resolveStatus(blockedByClosed, members, new Set()), "Ready");
});

test("resolveStatus: a blocked-by target that 404s/errors blocks — never defaults to Ready", () => {
  const node = { state: "OPEN", blockedBy: [{ repo: "infra", number: 1 }] };
  assert.equal(resolveStatus(node, new Map(), new Set(["infra#1"])), "Blocked");
});

// --- orderQueue -------------------------------------------------------------

test("orderQueue ranks a blocker before what it blocks", () => {
  const nodes = [
    { repo: "dotfiles", number: 1, priority: "none", blockedBy: [] },
    { repo: "dotfiles", number: 2, priority: "none", blockedBy: [{ repo: "dotfiles", number: 1 }] },
  ];
  const { queue, warnings } = orderQueue(nodes);
  const rank1 = queue.find((n) => n.number === 1).rank;
  const rank2 = queue.find((n) => n.number === 2).rank;
  assert.ok(rank1 < rank2);
  assert.deepEqual(warnings, []);
});

test("orderQueue breaks ties by the priority: ladder, then by (repo, number)", () => {
  const nodes = [
    { repo: "infra", number: 5, priority: "low", blockedBy: [] },
    { repo: "dotfiles", number: 1, priority: "high", blockedBy: [] },
    { repo: "dotfiles", number: 2, priority: "high", blockedBy: [] },
  ];
  const { queue } = orderQueue(nodes);
  assert.deepEqual(
    queue.map((n) => `${n.repo}#${n.number}`),
    ["dotfiles#1", "dotfiles#2", "infra#5"],
  );
});

test("orderQueue breaks a cycle deterministically by (repo, number) and reports it", () => {
  const nodes = [
    { repo: "dotfiles", number: 2, priority: "none", blockedBy: [{ repo: "dotfiles", number: 1 }] },
    { repo: "dotfiles", number: 1, priority: "none", blockedBy: [{ repo: "dotfiles", number: 2 }] },
  ];
  const { queue, warnings } = orderQueue(nodes);
  assert.deepEqual(
    queue.map((n) => `${n.repo}#${n.number}`),
    ["dotfiles#1", "dotfiles#2"],
  );
  assert.deepEqual(warnings, [{ type: "cycle", forced: { repo: "dotfiles", number: 1 } }]);
});

test("orderQueue ignores a blocked-by edge to an issue outside the member set", () => {
  const nodes = [{ repo: "dotfiles", number: 1, priority: "none", blockedBy: [{ repo: "infra", number: 999 }] }];
  const { queue, warnings } = orderQueue(nodes);
  assert.equal(queue[0].rank, 1);
  assert.deepEqual(warnings, []);
});

// --- buildReport: the 2026-08-22 hand traversal ----------------------------
//
// Reconstructed from the READY/BLOCKED chains backlog-manager's memory
// recorded for the 2026-08-22 traversal of #545 ("26 nodes, 14 open, 4
// active repos... READY: agent-memory-server#17 (high)... dotfiles#634
// (high, NOW UNBLOCKED — infra#240/infra#248/ams#1 all closed)... infra#217
// (unblocked)... ams#28/#27/#2. BLOCKED behind #634: #636 → #635/#639/#642/
// infra#250. Behind infra#217: #576 → #598. #612 behind #602... #637 and
// #638 CLOSED."). The full per-node state was never durably recorded
// anywhere accessible — this fixture encodes only the explicitly-stated
// relationships (21 of the 26 nodes), not a byte-exact replay of the whole
// traversal.
const TRAVERSAL_20260822_NODES = [
  // #545 has no real edge to each root below — this fixture stitches
  // connectivity with `blocking` links purely so computeMembership's
  // traversal reaches every node from one anchor; it isn't claiming #545
  // itself blocks them. Everything past a root is discovered transitively
  // via its own real `blockedBy` chain, same as the recorded traversal.
  {
    repo: "dotfiles",
    number: 545,
    state: "OPEN",
    labels: [],
    blockedBy: [],
    blocking: [
      { repo: "agent-memory-server", number: 17 },
      { repo: "dotfiles", number: 634 },
      { repo: "infra", number: 217 },
      { repo: "agent-memory-server", number: 28 },
      { repo: "agent-memory-server", number: 27 },
      { repo: "agent-memory-server", number: 2 },
      { repo: "dotfiles", number: 602 },
      { repo: "dotfiles", number: 637 },
      { repo: "dotfiles", number: 638 },
    ],
  },
  { repo: "agent-memory-server", number: 17, state: "OPEN", labels: [{ name: "priority: high" }], blockedBy: [] },
  {
    repo: "dotfiles",
    number: 634,
    state: "OPEN",
    labels: [{ name: "priority: high" }],
    blockedBy: [
      { repo: "infra", number: 240 },
      { repo: "infra", number: 248 },
      { repo: "agent-memory-server", number: 1 },
    ],
    // Reciprocal of #636's blockedBy — real GitHub blockedBy/blocking links
    // are bidirectional; this is what lets traversal reach #636 from #634.
    blocking: [{ repo: "dotfiles", number: 636 }],
  },
  { repo: "infra", number: 217, state: "OPEN", labels: [], blockedBy: [], blocking: [{ repo: "infra", number: 576 }] },
  { repo: "agent-memory-server", number: 28, state: "OPEN", labels: [], blockedBy: [] },
  { repo: "agent-memory-server", number: 27, state: "OPEN", labels: [], blockedBy: [] },
  { repo: "agent-memory-server", number: 2, state: "OPEN", labels: [], blockedBy: [] },
  {
    repo: "dotfiles",
    number: 636,
    state: "OPEN",
    labels: [],
    blockedBy: [{ repo: "dotfiles", number: 634 }],
    blocking: [
      { repo: "dotfiles", number: 635 },
      { repo: "dotfiles", number: 639 },
      { repo: "dotfiles", number: 642 },
      { repo: "infra", number: 250 },
    ],
  },
  { repo: "dotfiles", number: 635, state: "OPEN", labels: [], blockedBy: [{ repo: "dotfiles", number: 636 }] },
  { repo: "dotfiles", number: 639, state: "OPEN", labels: [], blockedBy: [{ repo: "dotfiles", number: 636 }] },
  { repo: "dotfiles", number: 642, state: "OPEN", labels: [], blockedBy: [{ repo: "dotfiles", number: 636 }] },
  { repo: "infra", number: 250, state: "OPEN", labels: [], blockedBy: [{ repo: "dotfiles", number: 636 }] },
  { repo: "infra", number: 576, state: "OPEN", labels: [], blockedBy: [{ repo: "infra", number: 217 }], blocking: [{ repo: "infra", number: 598 }] },
  { repo: "infra", number: 598, state: "OPEN", labels: [], blockedBy: [{ repo: "infra", number: 576 }] },
  { repo: "dotfiles", number: 602, state: "OPEN", labels: [], blockedBy: [], blocking: [{ repo: "dotfiles", number: 612 }] },
  { repo: "dotfiles", number: 612, state: "OPEN", labels: [], blockedBy: [{ repo: "dotfiles", number: 602 }] },
  { repo: "dotfiles", number: 637, state: "CLOSED", labels: [], blockedBy: [] },
  { repo: "dotfiles", number: 638, state: "CLOSED", labels: [], blockedBy: [] },
  { repo: "infra", number: 240, state: "CLOSED", labels: [], blockedBy: [] },
  { repo: "infra", number: 248, state: "CLOSED", labels: [], blockedBy: [] },
  { repo: "agent-memory-server", number: 1, state: "CLOSED", labels: [], blockedBy: [] },
];

function traversalFetchIssue(repo, number) {
  const node = TRAVERSAL_20260822_NODES.find((n) => n.repo === repo && n.number === number);
  return node
    ? Promise.resolve({ subIssues: [], blocking: [], body: "", ...node, title: `${repo}#${number}` })
    : Promise.reject(new Error("not in fixture"));
}

test("buildReport reproduces the 2026-08-22 traversal's Ready/Blocked/Done split", async () => {
  const { queue } = await buildReport({ repo: "dotfiles", number: 545 }, traversalFetchIssue);
  const statusOf = (repo, number) => queue.find((n) => n.repo === repo && n.number === number).status;

  for (const [repo, number] of [
    ["agent-memory-server", 17],
    ["dotfiles", 634],
    ["infra", 217],
    ["agent-memory-server", 28],
    ["agent-memory-server", 27],
    ["agent-memory-server", 2],
    ["dotfiles", 602],
    ["dotfiles", 545],
  ]) {
    assert.equal(statusOf(repo, number), "Ready", `${repo}#${number} should be Ready`);
  }
  for (const [repo, number] of [
    ["dotfiles", 636],
    ["dotfiles", 635],
    ["dotfiles", 639],
    ["dotfiles", 642],
    ["infra", 250],
    ["infra", 576],
    ["infra", 598],
    ["dotfiles", 612],
  ]) {
    assert.equal(statusOf(repo, number), "Blocked", `${repo}#${number} should be Blocked`);
  }
  for (const [repo, number] of [
    ["dotfiles", 637],
    ["dotfiles", 638],
    ["infra", 240],
    ["infra", 248],
    ["agent-memory-server", 1],
  ]) {
    assert.equal(statusOf(repo, number), "Done", `${repo}#${number} should be Done`);
  }
});

test("buildReport ranks the 2026-08-22 traversal's blocking chains in dependency order", async () => {
  const { queue } = await buildReport({ repo: "dotfiles", number: 545 }, traversalFetchIssue);
  const rankOf = (repo, number) => queue.find((n) => n.repo === repo && n.number === number).rank;

  assert.ok(rankOf("dotfiles", 634) < rankOf("dotfiles", 636));
  assert.ok(rankOf("dotfiles", 636) < rankOf("dotfiles", 635));
  assert.ok(rankOf("dotfiles", 636) < rankOf("infra", 250));
  assert.ok(rankOf("infra", 217) < rankOf("infra", 576));
  assert.ok(rankOf("infra", 576) < rankOf("infra", 598));
  assert.ok(rankOf("dotfiles", 602) < rankOf("dotfiles", 612));

  // The two `priority: high` Ready items outrank every lower-priority node.
  const highRanks = [rankOf("agent-memory-server", 17), rankOf("dotfiles", 634)];
  const restRanks = queue.filter((n) => n.priority !== "high").map((n) => n.rank);
  assert.ok(Math.max(...highRanks) < Math.min(...restRanks));
});

// --- parseProjectManifest ---------------------------------------------------
//
// The real project-manifest.yaml content (ADR-0052) as a fixture — the most
// realistic input this parser will ever see.
const REAL_MANIFEST = `# Anchor-keyed dedicated-member-repo manifest (ADR-0052, amending ADR-0040).
#
# A dedicated repo exists solely to serve one project — every one of its
# issues is a project member by default, no upward link to the anchor
# required. This list is authoritative for that union (ADR-0040's
# probe-before-trust rule does not apply here — the link graph structurally
# cannot express "all of this repo"). Editing this file wholesale-imports a
# repo's entire backlog into a project's view: human or backlog-manager
# sign-off, not a schema check alone. Validated by
# scripts/check-project-manifest.sh.
projects:
  - anchor: dotfiles#545
    dedicated_repos:
      - agent-memory-server
`;

test("parseProjectManifest parses the real project-manifest.yaml content", () => {
  const projects = parseProjectManifest(REAL_MANIFEST);
  assert.deepEqual(projects, [{ anchor: "dotfiles#545", dedicatedRepos: ["agent-memory-server"] }]);
});

test("parseProjectManifest handles multiple anchors and multiple dedicated repos each, ignoring comments/blank lines", () => {
  const body = `# a leading comment

projects:
  - anchor: dotfiles#545
    dedicated_repos:
      - agent-memory-server
      - some-other-repo
  - anchor: infra#1
    dedicated_repos:
      - infra-only-repo
`;
  const projects = parseProjectManifest(body);
  assert.deepEqual(projects, [
    { anchor: "dotfiles#545", dedicatedRepos: ["agent-memory-server", "some-other-repo"] },
    { anchor: "infra#1", dedicatedRepos: ["infra-only-repo"] },
  ]);
});

test("parseProjectManifest returns an empty list for missing/empty input", () => {
  assert.deepEqual(parseProjectManifest(undefined), []);
  assert.deepEqual(parseProjectManifest(""), []);
  assert.deepEqual(parseProjectManifest("projects:\n"), []);
});

// --- computeDedicatedMembers -------------------------------------------------

test("computeDedicatedMembers unions every open issue from each dedicated repo", async () => {
  const repoIssues = {
    "agent-memory-server": [
      { repo: "agent-memory-server", number: 1 },
      { repo: "agent-memory-server", number: 2 },
    ],
  };
  const issues = {
    "agent-memory-server#1": { repo: "agent-memory-server", number: 1, state: "OPEN", labels: [], blockedBy: [] },
    "agent-memory-server#2": { repo: "agent-memory-server", number: 2, state: "OPEN", labels: [], blockedBy: [] },
  };
  const listOpenIssues = (repo) => Promise.resolve(repoIssues[repo] ?? []);
  const fetchIssue = (repo, number) => Promise.resolve(issues[`${repo}#${number}`]);
  const { members, errored } = await computeDedicatedMembers(["agent-memory-server"], listOpenIssues, fetchIssue);
  assert.deepEqual([...members.keys()].sort(), ["agent-memory-server#1", "agent-memory-server#2"]);
  assert.equal(errored.size, 0);
});

test("computeDedicatedMembers marks a repo whose issue list fails to fetch as errored, without aborting other repos", async () => {
  const listOpenIssues = (repo) => (repo === "broken-repo" ? Promise.reject(new Error("404")) : Promise.resolve([{ repo, number: 1 }]));
  const fetchIssue = (repo, number) => Promise.resolve({ repo, number, state: "OPEN", labels: [], blockedBy: [] });
  const { members, errored } = await computeDedicatedMembers(["broken-repo", "working-repo"], listOpenIssues, fetchIssue);
  assert.equal(members.size, 1);
  assert.ok(members.has("working-repo#1"));
  assert.ok(errored.has("dedicated:broken-repo"));
});

// --- buildProjectReport ------------------------------------------------------

test("buildProjectReport unions the ADR-0040 closure with the dedicated-repo members", async () => {
  const graph = {
    "dotfiles#545": { repo: "dotfiles", number: 545, state: "OPEN", body: "", labels: [], blockedBy: [], blocking: [], subIssues: [] },
  };
  const repoIssues = {
    "agent-memory-server": [{ repo: "agent-memory-server", number: 17 }],
  };
  const dedicatedIssues = {
    "agent-memory-server#17": { repo: "agent-memory-server", number: 17, state: "OPEN", labels: [{ name: "priority: high" }], blockedBy: [] },
  };
  const fetchIssue = (repo, number) => Promise.resolve(graph[`${repo}#${number}`] ?? dedicatedIssues[`${repo}#${number}`]);
  const listOpenIssues = (repo) => Promise.resolve(repoIssues[repo] ?? []);

  const { queue } = await buildProjectReport({ repo: "dotfiles", number: 545 }, fetchIssue, "carpet-stain", {
    dedicatedRepos: ["agent-memory-server"],
    listOpenIssues,
  });
  assert.deepEqual(
    queue.map((n) => `${n.repo}#${n.number}`).sort(),
    ["agent-memory-server#17", "dotfiles#545"],
  );
});

test("buildProjectReport with no dedicatedRepos behaves exactly like buildReport", async () => {
  const graph = {
    "dotfiles#1": { repo: "dotfiles", number: 1, state: "OPEN", body: "", labels: [], blockedBy: [], blocking: [], subIssues: [] },
  };
  const fetchIssue = (repo, number) => Promise.resolve(graph[`${repo}#${number}`]);
  const viaProjectReport = await buildProjectReport({ repo: "dotfiles", number: 1 }, fetchIssue);
  const viaBuildReport = await buildReport({ repo: "dotfiles", number: 1 }, fetchIssue);
  assert.deepEqual(viaProjectReport.queue, viaBuildReport.queue);
});
