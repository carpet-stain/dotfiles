#!/usr/bin/env node
// I/O half of #517's attribution parser: finds this repo's transcript JSONL
// under ~/.claude/projects/ (main checkout + every worktree session, since
// Claude Code buckets transcripts per encoded cwd) and prints buildReport's
// JSON to stdout. All parsing/attribution logic is pure — see parse.mjs.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { execSync } from "node:child_process";
import { buildReport } from "./parse.mjs";

// Mirrors Claude Code's own project-directory encoding (cwd with `/` and `.`
// both flattened to `-`) — verified against real ~/.claude/projects entries.
function encodeProjectPath(path) {
  return path.replaceAll("/", "-").replaceAll(".", "-");
}

function repoRoot() {
  const commonDir = execSync("git rev-parse --path-format=absolute --git-common-dir", { encoding: "utf8" }).trim();
  return commonDir.replace(/\/\.git$/, "");
}

function findProjectDirs(claudeProjectsDir, repoPath) {
  const prefix = encodeProjectPath(repoPath);
  let entries;
  try {
    entries = readdirSync(claudeProjectsDir);
  } catch {
    return [];
  }
  return entries.filter((name) => name.startsWith(prefix)).map((name) => join(claudeProjectsDir, name));
}

function findJsonlFiles(dir) {
  const out = [];
  let entries;
  try {
    entries = readdirSync(dir);
  } catch {
    return out;
  }
  for (const name of entries) {
    const full = join(dir, name);
    const stat = statSync(full);
    if (stat.isDirectory()) out.push(...findJsonlFiles(full));
    else if (name.endsWith(".jsonl")) out.push(full);
  }
  return out;
}

function readRecords(path) {
  const records = [];
  const text = readFileSync(path, "utf8");
  for (const line of text.split("\n")) {
    if (!line.trim()) continue;
    try {
      records.push(JSON.parse(line));
    } catch {
      // Tolerate a truncated/corrupt line (e.g. a killed session mid-write)
      // rather than failing the whole report over one record.
    }
  }
  return records;
}

const claudeProjectsDir = join(homedir(), ".claude", "projects");
const repoPath = process.argv[2] ?? repoRoot();
const projectDirs = findProjectDirs(claudeProjectsDir, repoPath);
const records = projectDirs.flatMap((dir) => findJsonlFiles(dir).flatMap(readRecords));

console.log(JSON.stringify(buildReport(records), null, 2));
