#!/usr/bin/env node
// Idempotent bootstrap for the materialized project board (#669 Phase 2):
// creates the user-owned Projects v2 board (#670's verdict — build
// user-owned now, not org-owned) and its Status/Priority/Blocked-by
// fields if missing, updates a field's options if they've drifted, and
// errors rather than silently coercing a field that already exists with
// the wrong type. Pure plan/diff logic below; GraphQL I/O in the CLI shell
// at the bottom — see scripts/project-queue.mjs for the split this follows.
//
// NOT AUTOMATABLE, VERIFIED VIA SCHEMA INTROSPECTION (2026-08-24): GitHub's
// Projects v2 GraphQL API has no mutation for a view's group-by/sort-by
// configuration — `ProjectV2ViewConfigurationInput` exposes only
// `visibleFieldIds`, and `ProjectV2View.groupByFields`/`sortByFields` are
// query-only. This script creates the Board view with the right visible
// fields; grouping by Status and sorting by Priority is a one-time manual
// step in the UI after the first run (the script's own output says so).
//
// Requires a `project`-scoped credential — the ambient routine token can't
// reach Projects v2 at all (infra#301's finding). Run with
// BOARD_SYNC_TOKEN set (docs/credentials.md's "Projects v2 board-sync PAT";
// in CI, fetched from SSM via the `dotfiles-board-sync-read` OIDC role).

const OWNER_LOGIN = "carpet-stain";
const BOARD_TITLE = "Agent operating model — what's next";

export const DESIRED_FIELDS = [
  {
    name: "Status",
    dataType: "SINGLE_SELECT",
    options: [
      { name: "Ready", color: "GREEN", description: "Open, not blocked" },
      { name: "Blocked", color: "RED", description: "Open, blocked on a native blocked-by link" },
      { name: "Done", color: "GRAY", description: "Closed" },
    ],
  },
  {
    name: "Priority",
    dataType: "SINGLE_SELECT",
    options: [
      { name: "high", color: "RED", description: "priority: high" },
      { name: "medium", color: "YELLOW", description: "priority: medium" },
      { name: "low", color: "BLUE", description: "priority: low" },
      { name: "none", color: "GRAY", description: "no priority: label on the issue" },
    ],
  },
  { name: "Blocked by", dataType: "TEXT" },
];

export const DESIRED_VIEW = { name: "Board", layout: "TABLE_LAYOUT" };

// #669 Phase 4's regenerated-fields contract, written where a board reader
// actually meets it — the project's own description — rather than a doc
// nobody opens. `shortDescription` shows in listings; `readme` is the
// project's own overview page.
export const DESIRED_SHORT_DESCRIPTION = "Derived board — every field regenerates on each sync; a hand-edit vanishes on the next run. See the readme.";

export const DESIRED_README = `This board is **derived, not authored**. Every field regenerates on each
scheduled sync (\`.github/workflows/board-sync.yml\`) from the live cross-repo
link graph — a hand-edit here vanishes silently on the next run. See
carpet-stain/dotfiles#669.

| Field | Derived from |
| --- | --- |
| Status | Issue state + open native \`blocked-by\` links (Ready/Blocked/Done) |
| Priority | The repo's \`priority:\` label, or \`none\` |
| Repo | The issue's own repository (GitHub's built-in field) |
| Blocked by | A rendered summary of native \`blocked-by\` links |

Membership: the anchor's link graph (sub-issues, checkbox leading refs,
native \`blocked-by\`/\`blocking\` links) unioned with every open issue in a
dedicated member repo. See ADR-0040 (amended by ADR-0052, ADR-0053) and
\`project-manifest.yaml\`.

This board is a filter and a sort, not a reasoner — it shows what's
*available*, not what's *worth doing*. That judgment stays a grooming
conversation.`;

/**
 * Decides whether the project's description needs writing. Unlike a
 * field's options (where an unrelated drift is worth investigating before
 * overwriting), the description is wholly owned by this contract text —
 * any mismatch just means it's stale, so this only ever says update/skip,
 * never error.
 * @param {{shortDescription: string, readme: string}} existingProject
 * @param {{shortDescription: string, readme: string}} desired
 */
export function planDescription(existingProject, desired) {
  const changed = existingProject.shortDescription !== desired.shortDescription || existingProject.readme !== desired.readme;
  return changed ? { action: "update" } : { action: "skip" };
}

/**
 * Merges an existing single-select field's options with the desired set:
 * preserves an existing option's id (so item values pointing at it survive
 * and its id doesn't churn every run) when the name matches, appends a new
 * option without an id for anything missing. `changed` is false only when
 * the existing and desired sets already match exactly (name/color/
 * description, same count) — the caller uses it to skip a no-op mutation.
 * @param {{id: string, name: string, color: string, description: string}[]} existingOptions
 * @param {{name: string, color: string, description: string}[]} desiredOptions
 */
export function diffSingleSelectOptions(existingOptions, desiredOptions) {
  const byName = new Map(existingOptions.map((o) => [o.name, o]));
  let changed = existingOptions.length !== desiredOptions.length;
  const options = desiredOptions.map((wanted) => {
    const existing = byName.get(wanted.name);
    if (!existing) {
      changed = true;
      return { name: wanted.name, color: wanted.color, description: wanted.description };
    }
    if (existing.color !== wanted.color || existing.description !== wanted.description) changed = true;
    return { id: existing.id, name: wanted.name, color: wanted.color, description: wanted.description };
  });
  return { options, changed };
}

/**
 * Decides what (if anything) a single field needs: create if missing,
 * error if it exists with a different `dataType` (never silently recreate
 * — that would drop item values), update if a single-select's options
 * drifted, else skip.
 * @param {{id: string, name: string, dataType: string, options?: object[]}|undefined} existingField
 * @param {{name: string, dataType: string, options?: object[]}} desiredField
 */
export function planField(existingField, desiredField) {
  if (!existingField) return { action: "create", field: desiredField };
  if (existingField.dataType !== desiredField.dataType) {
    return {
      action: "error",
      reason: `field "${desiredField.name}" already exists as ${existingField.dataType}, expected ${desiredField.dataType} — not touching it`,
    };
  }
  if (desiredField.dataType !== "SINGLE_SELECT") return { action: "skip" };
  const { options, changed } = diffSingleSelectOptions(existingField.options ?? [], desiredField.options);
  return changed ? { action: "update", fieldId: existingField.id, options } : { action: "skip" };
}

/** @param {object[]} existingFields @param {object[]} desiredFields */
export function planFields(existingFields, desiredFields) {
  const byName = new Map(existingFields.map((f) => [f.name, f]));
  return desiredFields.map((desired) => ({ name: desired.name, ...planField(byName.get(desired.name), desired) }));
}

/** @param {{name: string}[]} existingViews @param {{name: string}} desiredView */
export function planView(existingViews, desiredView) {
  return existingViews.some((v) => v.name === desiredView.name) ? { action: "skip" } : { action: "create" };
}

// --- CLI shell (I/O) -------------------------------------------------------

// `-f`/`-F` flags can't cleanly express a nested array-of-objects GraphQL
// variable (e.g. singleSelectOptions) — verified against gh's own flag
// semantics (only scalars, `@file`, and a limited key[]/key[subkey] REST-body
// syntax). `--input -` sends a hand-built {query, variables} JSON body
// instead, so this fully controls the shape (verified working via a live
// introspection query, 2026-08-24).
async function graphql(execFileAsync, token, query, variables) {
  const fs = await import("node:fs/promises");
  const os = await import("node:os");
  const path = await import("node:path");
  const tmpFile = path.join(os.tmpdir(), `board-bootstrap-${process.pid}-${Date.now()}.json`);
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

async function resolveOwnerId(execFileAsync, token, login) {
  const data = await graphql(execFileAsync, token, `query($login:String!){ user(login:$login) { id } }`, { login });
  if (!data.user) throw new Error(`board-bootstrap: no such user "${login}"`);
  return data.user.id;
}

async function findProject(execFileAsync, token, ownerLogin, title) {
  const data = await graphql(
    execFileAsync,
    token,
    `query($login:String!,$q:String!){
      user(login:$login) {
        projectsV2(first: 20, query: $q) {
          nodes { id title url shortDescription readme }
        }
      }
    }`,
    { login: ownerLogin, q: title },
  );
  return data.user.projectsV2.nodes.find((p) => p.title === title) ?? null;
}

async function createProject(execFileAsync, token, ownerId, title) {
  const data = await graphql(execFileAsync, token, `mutation($ownerId:ID!,$title:String!){ createProjectV2(input:{ownerId:$ownerId,title:$title}) { projectV2 { id title url shortDescription readme } } }`, { ownerId, title });
  return data.createProjectV2.projectV2;
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
              ... on ProjectV2SingleSelectField { options { id name color description } }
            }
          }
        }
      }
    }`,
    { id: projectId },
  );
  return data.node.fields.nodes;
}

async function fetchViews(execFileAsync, token, projectId) {
  const data = await graphql(execFileAsync, token, `query($id:ID!){ node(id:$id) { ... on ProjectV2 { views(first: 20) { nodes { id name } } } } }`, { id: projectId });
  return data.node.views.nodes;
}

async function createField(execFileAsync, token, projectId, field) {
  const data = await graphql(
    execFileAsync,
    token,
    `mutation($projectId:ID!,$name:String!,$dataType:ProjectV2CustomFieldType!,$options:[ProjectV2SingleSelectFieldOptionInput!]){
      createProjectV2Field(input:{projectId:$projectId,name:$name,dataType:$dataType,singleSelectOptions:$options}) {
        projectV2Field { ... on ProjectV2FieldCommon { id name } }
      }
    }`,
    { projectId, name: field.name, dataType: field.dataType, options: field.options ?? null },
  );
  return data.createProjectV2Field.projectV2Field;
}

async function updateFieldOptions(execFileAsync, token, fieldId, options) {
  await graphql(execFileAsync, token, `mutation($fieldId:ID!,$options:[ProjectV2SingleSelectFieldOptionInput!]){ updateProjectV2Field(input:{fieldId:$fieldId,singleSelectOptions:$options}) { clientMutationId } }`, { fieldId, options });
}

// ProjectV2View has no `url` field (verified against the live schema) —
// request `number` and build the URL the same way GitHub's own UI does:
// <project URL>/views/<view number>.
async function createView(execFileAsync, token, projectId, view) {
  const data = await graphql(execFileAsync, token, `mutation($projectId:ID!,$name:String!,$layout:ProjectV2ViewLayout!){ createProjectV2View(input:{projectId:$projectId,name:$name,layout:$layout}) { projectV2View { id name number } } }`, {
    projectId,
    name: view.name,
    layout: view.layout,
  });
  return data.createProjectV2View.projectV2View;
}

async function updateProjectDescription(execFileAsync, token, projectId, desired) {
  await graphql(execFileAsync, token, `mutation($projectId:ID!,$shortDescription:String!,$readme:String!){ updateProjectV2(input:{projectId:$projectId,shortDescription:$shortDescription,readme:$readme}) { clientMutationId } }`, {
    projectId,
    shortDescription: desired.shortDescription,
    readme: desired.readme,
  });
}

async function main() {
  const token = process.env.BOARD_SYNC_TOKEN;
  if (!token) throw new Error("board-bootstrap: BOARD_SYNC_TOKEN is required (docs/credentials.md's Projects v2 board-sync PAT)");

  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  const execFileAsync = promisify(execFile);

  let project = await findProject(execFileAsync, token, OWNER_LOGIN, BOARD_TITLE);
  if (!project) {
    const ownerId = await resolveOwnerId(execFileAsync, token, OWNER_LOGIN);
    project = await createProject(execFileAsync, token, ownerId, BOARD_TITLE);
    console.log(`created project: ${project.url}`);
  } else {
    console.log(`found existing project: ${project.url}`);
  }

  const desiredDescription = { shortDescription: DESIRED_SHORT_DESCRIPTION, readme: DESIRED_README };
  const descriptionPlan = planDescription(project, desiredDescription);
  if (descriptionPlan.action === "update") {
    await updateProjectDescription(execFileAsync, token, project.id, desiredDescription);
    console.log("updated project description (#669 Phase 4's regenerated-fields contract)");
  } else {
    console.log("project description already correct");
  }

  const existingFields = await fetchFields(execFileAsync, token, project.id);
  const fieldPlan = planFields(existingFields, DESIRED_FIELDS);
  for (const step of fieldPlan) {
    if (step.action === "create") {
      await createField(execFileAsync, token, project.id, step.field);
      console.log(`created field: ${step.name}`);
    } else if (step.action === "update") {
      await updateFieldOptions(execFileAsync, token, step.fieldId, step.options);
      console.log(`updated field options: ${step.name}`);
    } else if (step.action === "error") {
      throw new Error(`board-bootstrap: ${step.reason}`);
    } else {
      console.log(`field already correct: ${step.name}`);
    }
  }

  const existingViews = await fetchViews(execFileAsync, token, project.id);
  const viewPlan = planView(existingViews, DESIRED_VIEW);
  if (viewPlan.action === "create") {
    const view = await createView(execFileAsync, token, project.id, DESIRED_VIEW);
    console.log(`created view: ${view.name} (${project.url}/views/${view.number})`);
  } else {
    console.log(`view already exists: ${DESIRED_VIEW.name}`);
  }

  console.log(
    `\nboard-bootstrap done: ${project.url}\n` +
      `MANUAL STEP REQUIRED (not automatable via the GraphQL API — verified 2026-08-24,\n` +
      `see this file's header): open the "${DESIRED_VIEW.name}" view and set it to group by\n` +
      `Status and sort by Priority. This is a one-time UI action; it survives future syncs.`,
  );
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err.stack || String(err));
    process.exit(1);
  });
}
