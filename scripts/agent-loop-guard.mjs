#!/usr/bin/env node
// Deterministic (no-LLM) loop-safety pre-step for agent-runner.yml (#576).
// Every Actions run is a fresh, stateless process, so round count / whose-
// turn / the recursion filter are reconstructed from GitHub on every wake —
// never carried in memory (#545 invocation-gating block).
//
// The decision logic below is pure and unit-tested against fixtures
// (agent-loop-guard.test.mjs); this file's tail is the I/O shell that reads
// the triggering event from env vars agent-runner.yml sets, queries the
// issue's timeline over the GitHub REST API with the platform `fetch` (same
// approach as scripts/pr-review/run.mjs — no octokit, no `gh` shellout),
// and writes the decision to $GITHUB_OUTPUT.

// --- .github/agent-routing.yml parsing -----------------------------------

// Hand-rolled, not a general YAML parser: the routing config's shape is
// deliberately flat (top-level scalars + one list of flat maps under
// `routes:`), and this repo carries no JS dependency manager to vendor a
// real YAML library for that alone.
export function parseRoutingConfig(text) {
  const top = {};
  const routes = [];
  let current = null;

  for (const raw of text.split("\n")) {
    const line = raw.split("#")[0];
    if (!line.trim()) continue;

    const routeStart = line.match(/^ {2}- (\w+):\s*(.+)$/);
    if (routeStart) {
      current = { [routeStart[1]]: routeStart[2].trim() };
      routes.push(current);
      continue;
    }

    const routeField = line.match(/^ {4}(\w+):\s*(.+)$/);
    if (routeField && current) {
      current[routeField[1]] = routeField[2].trim();
      continue;
    }

    const topField = line.match(/^(\w+):\s*(.*)$/);
    if (topField) {
      current = null;
      const [, key, value] = topField;
      if (key === "routes") continue;
      top[key] = /^\d+$/.test(value) ? Number(value) : value;
    }
  }

  return { ...top, routes };
}

// --- pure decision logic --------------------------------------------------

// Every role posts under carpet-stain-<role> (#540) — deriving the login
// instead of a hardcoded roster list means the recursion filter needs no
// edit when a new role (e.g. the architect) joins (named nit F1, #576).
export function machineLogin(role) {
  return `carpet-stain-${role}`;
}

// Which role, if any, this event maps to. First matching route wins; an
// event nothing maps to (e.g. a human's plain comment) returns null.
export function resolveRoute(routing, event) {
  for (const route of routing.routes) {
    if (
      route.event === event.eventType &&
      route.action === event.eventAction &&
      route.label === event.label
    ) {
      return route.role;
    }
  }
  return null;
}

// A completed round is one reviewer turn: one time the turn-signal label
// was added. Counting label-add timeline events, never a raw comment tally,
// is what makes this survive the reviewer posting more than one comment in
// a turn (#5 in #576's converged plan).
export function countTurnSignalRounds(timelineEvents, turnSignalLabel) {
  return timelineEvents.filter(
    (e) => e.event === "labeled" && e.label?.name === turnSignalLabel,
  ).length;
}

// The dead-man's switch: self-spawn recursion filter first, scoped to "actor
// equals the role THIS event would spawn" (never a blanket machine-user
// drop — see #576's F1/F2), then the round cap, evaluated pre-spawn.
export function evaluateGuard({ routing, event, roundCount }) {
  const role = resolveRoute(routing, event);
  if (!role) {
    return { spawn: false, role: null, reason: "no route for this event" };
  }

  if (event.actorLogin === machineLogin(role)) {
    return {
      spawn: false,
      role,
      reason: `filtered: actor ${event.actorLogin} is the role this event would spawn (self-spawn recursion)`,
    };
  }

  if (roundCount > routing.round_cap) {
    return {
      spawn: false,
      role,
      reason: `round cap tripped: round ${roundCount} exceeds round_cap ${routing.round_cap} — halting for a human decision (ADR-0042)`,
    };
  }

  return {
    spawn: true,
    role,
    reason: `${role}'s turn, round ${roundCount || 1}/${routing.round_cap}`,
  };
}

// --- CLI shell (I/O) -------------------------------------------------------

async function fetchTimeline({ apiUrl, repo, issueNumber, token }) {
  const events = [];
  let url = `${apiUrl}/repos/${repo}/issues/${issueNumber}/timeline?per_page=100`;
  while (url) {
    const res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
      },
    });
    if (!res.ok) {
      throw new Error(`timeline fetch failed: ${res.status} ${await res.text()}`);
    }
    events.push(...(await res.json()));
    const next = res.headers.get("link")?.match(/<([^>]+)>;\s*rel="next"/);
    url = next ? next[1] : null;
  }
  return events;
}

async function main() {
  const {
    GITHUB_TOKEN,
    GITHUB_API_URL = "https://api.github.com",
    GITHUB_REPOSITORY,
    GITHUB_OUTPUT,
    ROUTING_CONFIG_PATH = ".github/agent-routing.yml",
    EVENT_TYPE,
    EVENT_ACTION,
    EVENT_LABEL = "",
    ACTOR_LOGIN,
    ISSUE_NUMBER,
  } = process.env;

  for (const [name, value] of Object.entries({
    GITHUB_TOKEN,
    GITHUB_REPOSITORY,
    GITHUB_OUTPUT,
    EVENT_TYPE,
    EVENT_ACTION,
    ACTOR_LOGIN,
    ISSUE_NUMBER,
  })) {
    if (!value) throw new Error(`agent-loop-guard: missing required env var for ${name}`);
  }

  const fs = await import("node:fs");
  const routing = parseRoutingConfig(fs.readFileSync(ROUTING_CONFIG_PATH, "utf8"));
  if (!routing.round_cap) {
    // Fail-closed default (ADR-0048): no cap configured means don't run.
    throw new Error("agent-loop-guard: agent-routing.yml has no round_cap — refusing to run");
  }

  const timeline = await fetchTimeline({
    apiUrl: GITHUB_API_URL,
    repo: GITHUB_REPOSITORY,
    issueNumber: ISSUE_NUMBER,
    token: GITHUB_TOKEN,
  });
  const roundCount = countTurnSignalRounds(timeline, routing.turn_signal_label);

  const decision = evaluateGuard({
    routing,
    event: {
      eventType: EVENT_TYPE,
      eventAction: EVENT_ACTION,
      label: EVENT_LABEL,
      actorLogin: ACTOR_LOGIN,
    },
    roundCount,
  });

  console.log(`agent-loop-guard: ${decision.reason}`);
  fs.appendFileSync(
    GITHUB_OUTPUT,
    `spawn=${decision.spawn}\nrole=${decision.role ?? ""}\nreason=${decision.reason}\nturn_signal_label=${routing.turn_signal_label}\n`,
  );
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err.stack || String(err));
    process.exit(1);
  });
}
