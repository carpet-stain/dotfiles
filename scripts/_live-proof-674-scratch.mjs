// Throwaway file for a live proof of #674 (suppress repeated PR-review
// findings) — deliberately vulnerable, never intended to merge. Deleted
// before this branch's PR is closed.
import { exec } from "node:child_process";

export function listUserFiles(userDir, callback) {
  exec(`ls -la ${userDir}`, (err, stdout) => {
    callback(err, stdout);
  });
}
