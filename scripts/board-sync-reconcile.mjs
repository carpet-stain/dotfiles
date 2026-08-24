#!/usr/bin/env node
// #669 Phase 3: reconciles the materialized project board's ITEMS against a
// pre-computed project-queue.mjs report. Adds a missing member, removes a
// non-member, and overwrites every remaining item's Status/Priority/
// Blocked-by fields unconditionally — the board never holds authored
// state, only what this reconcile last wrote. Single-select option ids are
// resolved by field+option NAME at the start of every run (no bootstrap/
// sync id handshake — a rerun of board-bootstrap.mjs never breaks sync).
//
// This script only WRITES — it consumes a report file, it never itself
// queries the member repos. That's the credential boundary board-sync.yml
// enforces at the job level (mirroring agents-sync.yml's two-job split):
// the job that talks to every member repo (project-queue.mjs, routine
// token) and the job that holds the write-capable BOARD_SYNC_TOKEN never
// overlap.
//
// Requires BOARD_SYNC_TOKEN — same credential as board-bootstrap.mjs (see
// its header and docs/credentials.md's "Projects v2 board-sync PAT").

// Kept in sync with board-bootstrap.mjs by hand, not by importing from it:
// #669 Phase 2 (board-bootstrap.mjs) isn't merged yet as this is written,
// and a cross-file import would make Phase 3 depend on Phase 2's PR
// landing in a specific shape rather than the shared, documented contract
// (title, field names) both scripts already target. Same duplication
// precedent as the graphql() helper below.
const OWNER_LOGIN = "carpet-stain";
const BOARD_TITLE = "Agent operating model — what's next";

const STATUS_FIELD_NAME = "Status";
const PRIORITY_FIELD_NAME = "Priority";
const BLOCKED_BY_FIELD_NAME = "Blocked by";

function memberKey(repo, number) {
  return `${repo.toLowerCase()}#${number}`;
}

/**
 * Decides the item-level reconcile: `toAdd` is a desired member missing
 * from the board, `toRemove` is a board item no longer a desired member,
 * `toUpdate` pairs every remaining item's id with the desired member whose
 * field values it should be overwritten with.
 * @param {{itemId: string, repo: string, number: number}[]} existingItems
 * @param {{id: string, repo: string, number: number}[]} desiredMembers
 */
export function planItemSync(existingItems, desiredMembers) {
  const existingByKey = new Map(existingItems.map((item) => [memberKey(item.repo, item.number), item]));
  const desiredByKey = new Map(desiredMembers.map((member) => [memberKey(member.repo, member.number), member]));

  const toAdd = desiredMembers.filter((member) => !existingByKey.has(memberKey(member.repo, member.number)));
  const toRemove = existingItems.filter((item) => !desiredByKey.has(memberKey(item.repo, item.number)));
  const toUpdate = existingItems
    .filter((item) => desiredByKey.has(memberKey(item.repo, item.number)))
    .map((item) => ({ itemId: item.itemId, member: desiredByKey.get(memberKey(item.repo, item.number)) }));

  return { toAdd, toRemove, toUpdate };
}

/**
 * The Blocked-by text field: a comma-joined "repo#number" list, or empty
 * when not blocked — a blank cell reads as "not blocked" without inventing
 * prose no field-value data backs.
 * @param {{repo: string, number: number}[]|undefined} blockedBy
 */
export function renderBlockedBy(blockedBy) {
  return (blockedBy ?? []).map((ref) => `${ref.repo}#${ref.number}`).join(", ");
}

/**
 * Resolves a single-select option's id by name. Throws rather than
 * skipping silently — a missing option means the board's fields have
 * drifted from what board-bootstrap.mjs creates, a config bug worth
 * surfacing loudly, not writing around.
 * @param {{id: string, name: string}[]|undefined} options
 * @param {string} name
 */
export function resolveOptionId(options, name) {
  const match = (options ?? []).find((o) => o.name === name);
  if (!match) throw new Error(`board-sync: no option named "${name}" among [${(options ?? []).map((o) => o.name).join(", ")}] — did board-bootstrap.mjs run?`);
  return match.id;
}

// --- CLI shell (I/O) -------------------------------------------------------

// Same --input-file GraphQL invocation as board-bootstrap.mjs — see its
// header comment for why -f/-F can't express this cleanly.
async function graphql(execFileAsync, token, query, variables) {
  const fs = await import("node:fs/promises");
  const os = await import("node:os");
  const path = await import("node:path");
  const tmpFile = path.join(os.tmpdir(), `board-sync-${process.pid}-${Date.now()}.json`);
  await fs.writeFile(tmpFile, JSON.stringify({ query, variables: variables ?? {} }));
  try {
    const { stdout } = await execFileAsync("gh", ["api", "graphql", "--input", tmpFile], {
      env: { ...process.env, GH_TOKEN: token },
      maxBuffer: 10 * 1024 * 1024,
    });
    const parsed = JSON.parse(stdout);
    if (parsed.errors?.length) throw new Error(`GraphQL error: ${parsed.errors.map((e) => e.message).join("; ")}`);
    return parsed.data;
  } finally {
    await fs.unlink(tmpFile).catch(() => {});
  }
}

async function findProject(execFileAsync, token, ownerLogin, title) {
  const data = await graphql(
    execFileAsync,
    token,
    `query($login:String!,$q:String!){
      user(login:$login) {
        projectsV2(first: 20, query: $q) {
          nodes { id title }
        }
      }
    }`,
    { login: ownerLogin, q: title },
  );
  return data.user.projectsV2.nodes.find((p) => p.title === title) ?? null;
}

async function fetchFields(execFileAsync, token, projectId) {
  const data = await graphql(
    execFileAsync,
    token,
    `query($id:ID!){
      node(id:$id) {
        ... on ProjectV2 {
          fields(first: 50) {
            nodes {
              __typename
              ... on ProjectV2FieldCommon { id name dataType }
              ... on ProjectV2SingleSelectField { options { id name } }
            }
          }
        }
      }
    }`,
    { id: projectId },
  );
  return data.node.fields.nodes;
}

async function fetchItems(execFileAsync, token, projectId) {
  const items = [];
  let after = null;
  for (;;) {
    const data = await graphql(
      execFileAsync,
      token,
      `query($id:ID!,$after:String){
        node(id:$id) {
          ... on ProjectV2 {
            items(first: 100, after: $after) {
              pageInfo { hasNextPage endCursor }
              nodes {
                id
                content { ... on Issue { number repository { name } } }
              }
            }
          }
        }
      }`,
      { id: projectId, after },
    );
    const page = data.node.items;
    for (const node of page.nodes) {
      // A draft issue or PR content has no `repository`/isn't an Issue —
      // out of scope for a board whose whole contract is issue membership.
      if (!node.content?.repository) continue;
      items.push({ itemId: node.id, repo: node.content.repository.name, number: node.content.number });
    }
    if (!page.pageInfo.hasNextPage) break;
    after = page.pageInfo.endCursor;
  }
  return items;
}

async function addItem(execFileAsync, token, projectId, contentId) {
  const data = await graphql(execFileAsync, token, `mutation($projectId:ID!,$contentId:ID!){ addProjectV2ItemById(input:{projectId:$projectId,contentId:$contentId}) { item { id } } }`, { projectId, contentId });
  return data.addProjectV2ItemById.item.id;
}

async function removeItem(execFileAsync, token, projectId, itemId) {
  await graphql(execFileAsync, token, `mutation($projectId:ID!,$itemId:ID!){ deleteProjectV2Item(input:{projectId:$projectId,itemId:$itemId}) { deletedItemId } }`, { projectId, itemId });
}

async function setFieldValue(execFileAsync, token, projectId, itemId, fieldId, value) {
  await graphql(execFileAsync, token, `mutation($projectId:ID!,$itemId:ID!,$fieldId:ID!,$value:ProjectV2FieldValue!){ updateProjectV2ItemFieldValue(input:{projectId:$projectId,itemId:$itemId,fieldId:$fieldId,value:$value}) { clientMutationId } }`, {
    projectId,
    itemId,
    fieldId,
    value,
  });
}

async function main() {
  const token = process.env.BOARD_SYNC_TOKEN;
  if (!token) throw new Error("board-sync-reconcile: BOARD_SYNC_TOKEN is required (docs/credentials.md's Projects v2 board-sync PAT)");
  const reportPath = process.argv[2];
  if (!reportPath) throw new Error("usage: board-sync-reconcile.mjs <project-queue-report.json>");

  const fs = await import("node:fs/promises");
  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  const execFileAsync = promisify(execFile);

  const desiredMembers = JSON.parse(await fs.readFile(reportPath, "utf8"));

  const project = await findProject(execFileAsync, token, OWNER_LOGIN, BOARD_TITLE);
  if (!project) throw new Error(`board-sync-reconcile: no project titled "${BOARD_TITLE}" — run board-bootstrap.mjs first`);

  const fields = await fetchFields(execFileAsync, token, project.id);
  const statusField = fields.find((f) => f.name === STATUS_FIELD_NAME);
  const priorityField = fields.find((f) => f.name === PRIORITY_FIELD_NAME);
  const blockedByField = fields.find((f) => f.name === BLOCKED_BY_FIELD_NAME);
  if (!statusField || !priorityField || !blockedByField) {
    throw new Error(`board-sync-reconcile: missing one of "${STATUS_FIELD_NAME}"/"${PRIORITY_FIELD_NAME}"/"${BLOCKED_BY_FIELD_NAME}" — run board-bootstrap.mjs first`);
  }

  async function writeFields(itemId, member) {
    await setFieldValue(execFileAsync, token, project.id, itemId, statusField.id, { singleSelectOptionId: resolveOptionId(statusField.options, member.status) });
    await setFieldValue(execFileAsync, token, project.id, itemId, priorityField.id, { singleSelectOptionId: resolveOptionId(priorityField.options, member.priority) });
    await setFieldValue(execFileAsync, token, project.id, itemId, blockedByField.id, { text: renderBlockedBy(member.blockedBy) });
  }

  const existingItems = await fetchItems(execFileAsync, token, project.id);
  const { toAdd, toRemove, toUpdate } = planItemSync(existingItems, desiredMembers);

  for (const member of toAdd) {
    const itemId = await addItem(execFileAsync, token, project.id, member.id);
    await writeFields(itemId, member);
    console.log(`added: ${member.repo}#${member.number}`);
  }
  for (const item of toRemove) {
    await removeItem(execFileAsync, token, project.id, item.itemId);
    console.log(`removed: ${item.repo}#${item.number}`);
  }
  for (const { itemId, member } of toUpdate) {
    await writeFields(itemId, member);
  }

  console.log(`board-sync-reconcile done: +${toAdd.length} -${toRemove.length} ~${toUpdate.length} (${desiredMembers.length} desired members total)`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err.stack || String(err));
    process.exit(1);
  });
}
