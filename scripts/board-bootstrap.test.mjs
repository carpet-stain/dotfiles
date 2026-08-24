// Unit tests for the pure, no-I/O half of board-bootstrap.mjs, run with
// Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/*.test.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import { diffSingleSelectOptions, planField, planFields, planView, planDescription, DESIRED_FIELDS, DESIRED_VIEW, DESIRED_SHORT_DESCRIPTION, DESIRED_README } from "./board-bootstrap.mjs";

// --- diffSingleSelectOptions -------------------------------------------

test("diffSingleSelectOptions reports unchanged when existing options already match", () => {
  const existing = [{ id: "o1", name: "Ready", color: "GREEN", description: "Open, not blocked" }];
  const desired = [{ name: "Ready", color: "GREEN", description: "Open, not blocked" }];
  const { options, changed } = diffSingleSelectOptions(existing, desired);
  assert.equal(changed, false);
  assert.deepEqual(options, [{ id: "o1", name: "Ready", color: "GREEN", description: "Open, not blocked" }]);
});

test("diffSingleSelectOptions preserves an existing option's id and flags a missing option as changed", () => {
  const existing = [{ id: "o1", name: "Ready", color: "GREEN", description: "Open, not blocked" }];
  const desired = [
    { name: "Ready", color: "GREEN", description: "Open, not blocked" },
    { name: "Blocked", color: "RED", description: "Open, blocked" },
  ];
  const { options, changed } = diffSingleSelectOptions(existing, desired);
  assert.equal(changed, true);
  assert.deepEqual(options, [
    { id: "o1", name: "Ready", color: "GREEN", description: "Open, not blocked" },
    { name: "Blocked", color: "RED", description: "Open, blocked" },
  ]);
});

test("diffSingleSelectOptions flags a color/description drift on an existing option as changed", () => {
  const existing = [{ id: "o1", name: "Ready", color: "GRAY", description: "old description" }];
  const desired = [{ name: "Ready", color: "GREEN", description: "Open, not blocked" }];
  const { options, changed } = diffSingleSelectOptions(existing, desired);
  assert.equal(changed, true);
  assert.deepEqual(options, [{ id: "o1", name: "Ready", color: "GREEN", description: "Open, not blocked" }]);
});

// --- planField / planFields --------------------------------------------

test("planField creates a field that doesn't exist yet", () => {
  const desired = { name: "Blocked by", dataType: "TEXT" };
  assert.deepEqual(planField(undefined, desired), { action: "create", field: desired });
});

test("planField skips a TEXT field that already exists", () => {
  const existing = { id: "f1", name: "Blocked by", dataType: "TEXT" };
  const desired = { name: "Blocked by", dataType: "TEXT" };
  assert.deepEqual(planField(existing, desired), { action: "skip" });
});

test("planField errors rather than silently recreating a field with a mismatched dataType", () => {
  const existing = { id: "f1", name: "Priority", dataType: "TEXT" };
  const desired = { name: "Priority", dataType: "SINGLE_SELECT", options: [] };
  const result = planField(existing, desired);
  assert.equal(result.action, "error");
  assert.match(result.reason, /already exists as TEXT, expected SINGLE_SELECT/);
});

test("planField updates a single-select field whose options drifted", () => {
  const existing = { id: "f1", name: "Status", dataType: "SINGLE_SELECT", options: [{ id: "o1", name: "Ready", color: "GRAY", description: "" }] };
  const desired = { name: "Status", dataType: "SINGLE_SELECT", options: [{ name: "Ready", color: "GREEN", description: "Open, not blocked" }] };
  const result = planField(existing, desired);
  assert.equal(result.action, "update");
  assert.equal(result.fieldId, "f1");
});

test("planFields resolves the real DESIRED_FIELDS list against an empty project — every field creates", () => {
  const plan = planFields([], DESIRED_FIELDS);
  assert.deepEqual(
    plan.map((p) => [p.name, p.action]),
    [
      ["Status", "create"],
      ["Priority", "create"],
      ["Blocked by", "create"],
    ],
  );
});

test("planFields resolves the real DESIRED_FIELDS list against an already-correct project — everything skips", () => {
  const existingFields = DESIRED_FIELDS.map((f) => ({
    id: `id-${f.name}`,
    name: f.name,
    dataType: f.dataType,
    options: f.options?.map((o, i) => ({ id: `opt-${i}`, ...o })),
  }));
  const plan = planFields(existingFields, DESIRED_FIELDS);
  assert.deepEqual(
    plan.map((p) => p.action),
    ["skip", "skip", "skip"],
  );
});

// --- planView -------------------------------------------------------------

test("planView creates the Board view when no view has that name yet", () => {
  assert.deepEqual(planView([], DESIRED_VIEW), { action: "create" });
  assert.deepEqual(planView([{ name: "Some other view" }], DESIRED_VIEW), { action: "create" });
});

test("planView skips when a view with the desired name already exists", () => {
  assert.deepEqual(planView([{ name: DESIRED_VIEW.name }], DESIRED_VIEW), { action: "skip" });
});

// --- planDescription (#669 Phase 4) ----------------------------------------

const DESIRED_DESCRIPTION = { shortDescription: DESIRED_SHORT_DESCRIPTION, readme: DESIRED_README };

test("planDescription updates when the project has no description set yet", () => {
  assert.deepEqual(planDescription({ shortDescription: "", readme: "" }, DESIRED_DESCRIPTION), { action: "update" });
});

test("planDescription skips when the project's description already matches exactly", () => {
  assert.deepEqual(planDescription(DESIRED_DESCRIPTION, DESIRED_DESCRIPTION), { action: "skip" });
});

test("planDescription updates when only the readme drifted, short description unchanged", () => {
  const existing = { shortDescription: DESIRED_SHORT_DESCRIPTION, readme: "stale readme text" };
  assert.deepEqual(planDescription(existing, DESIRED_DESCRIPTION), { action: "update" });
});
