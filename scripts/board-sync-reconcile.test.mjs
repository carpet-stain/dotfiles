// Unit tests for the pure, no-I/O half of board-sync-reconcile.mjs, run
// with Node's built-in test runner (no dependency, no package.json needed):
//   node --test scripts/*.test.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import { planItemSync, renderBlockedBy, resolveOptionId } from "./board-sync-reconcile.mjs";

// --- planItemSync -----------------------------------------------------

test("planItemSync adds a desired member missing from the board", () => {
  const { toAdd, toRemove, toUpdate } = planItemSync([], [{ id: "I_1", repo: "dotfiles", number: 1 }]);
  assert.deepEqual(toAdd, [{ id: "I_1", repo: "dotfiles", number: 1 }]);
  assert.deepEqual(toRemove, []);
  assert.deepEqual(toUpdate, []);
});

test("planItemSync removes a board item no longer a desired member", () => {
  const existing = [{ itemId: "PVTI_1", repo: "dotfiles", number: 1 }];
  const { toAdd, toRemove, toUpdate } = planItemSync(existing, []);
  assert.deepEqual(toAdd, []);
  assert.deepEqual(toRemove, existing);
  assert.deepEqual(toUpdate, []);
});

test("planItemSync pairs an existing item's id with its desired member for update, matched case-insensitively", () => {
  const existing = [{ itemId: "PVTI_1", repo: "Dotfiles", number: 1 }];
  const desired = [{ id: "I_1", repo: "dotfiles", number: 1, status: "Ready" }];
  const { toAdd, toRemove, toUpdate } = planItemSync(existing, desired);
  assert.deepEqual(toAdd, []);
  assert.deepEqual(toRemove, []);
  assert.deepEqual(toUpdate, [{ itemId: "PVTI_1", member: desired[0] }]);
});

test("planItemSync handles add/remove/update together against a real-shaped set", () => {
  const existing = [
    { itemId: "PVTI_1", repo: "dotfiles", number: 1 },
    { itemId: "PVTI_2", repo: "dotfiles", number: 2 },
  ];
  const desired = [
    { id: "I_1", repo: "dotfiles", number: 1, status: "Ready" },
    { id: "I_3", repo: "dotfiles", number: 3, status: "Blocked" },
  ];
  const { toAdd, toRemove, toUpdate } = planItemSync(existing, desired);
  assert.deepEqual(toAdd, [{ id: "I_3", repo: "dotfiles", number: 3, status: "Blocked" }]);
  assert.deepEqual(toRemove, [{ itemId: "PVTI_2", repo: "dotfiles", number: 2 }]);
  assert.deepEqual(toUpdate, [{ itemId: "PVTI_1", member: desired[0] }]);
});

// --- renderBlockedBy ----------------------------------------------------

test("renderBlockedBy joins repo#number pairs and is empty when not blocked", () => {
  assert.equal(renderBlockedBy([]), "");
  assert.equal(renderBlockedBy(undefined), "");
  assert.equal(
    renderBlockedBy([
      { repo: "infra", number: 301 },
      { repo: "dotfiles", number: 668 },
    ]),
    "infra#301, dotfiles#668",
  );
});

// --- resolveOptionId ------------------------------------------------------

test("resolveOptionId finds an option by name", () => {
  const options = [
    { id: "opt1", name: "Ready" },
    { id: "opt2", name: "Blocked" },
  ];
  assert.equal(resolveOptionId(options, "Blocked"), "opt2");
});

test("resolveOptionId throws rather than skipping when an option is missing — a config drift bug, not a no-op", () => {
  const options = [{ id: "opt1", name: "Ready" }];
  assert.throws(() => resolveOptionId(options, "Blocked"), /no option named "Blocked"/);
});
