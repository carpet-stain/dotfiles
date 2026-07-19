// Parses a GitHub API unified-diff "patch" string into per-line info for
// the new (RIGHT-side) file. Pure, no I/O — see build-review.test.mjs.

/**
 * @param {string} patch - the `patch` field GitHub's pulls.listFiles API
 *   returns for one file (hunks only, no `--- a/`/`+++ b/` file headers).
 * @returns {Map<number, string>} new-file line number -> line content, for
 *   every line GitHub allows a RIGHT-side review comment on (context lines
 *   and added lines). Deleted lines have no RIGHT-side line number and are
 *   omitted.
 */
export function parsePatch(patch) {
  const lines = new Map();
  if (!patch) return lines;

  let newLine = 0;
  for (const raw of patch.split("\n")) {
    if (raw.startsWith("@@")) {
      const match = raw.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
      if (!match) continue;
      newLine = Number(match[1]);
      continue;
    }
    if (raw.length === 0) continue; // trailing split() artifact
    if (raw.startsWith("\\")) continue; // "\ No newline at end of file"
    if (raw.startsWith("-")) continue; // old-file-only line, no RIGHT anchor
    if (raw.startsWith("+")) {
      lines.set(newLine, raw.slice(1));
      newLine++;
      continue;
    }
    // context line: starts with the diff's single leading space marker
    lines.set(newLine, raw.slice(1));
    newLine++;
  }
  return lines;
}
