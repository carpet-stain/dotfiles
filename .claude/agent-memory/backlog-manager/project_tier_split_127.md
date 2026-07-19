---
name: project-tier-split-127
description: Payload/dev-tooling/repo-meta tier split (spike #127, CLOSED) — now executing as epic #361
metadata:
  type: project
---

Spike #127 ratified the three-tier model (payload / dev-tooling / repo-meta) ADR-0006 named but
left partly TBD: full per-item classification, the tag+guard mechanism (not a Brewfile↔Aptfile
generator — deliberately rejected as more machinery than the drift needs), and answers to the
three open questions (Linux nvim leanness, `claude/` tier, `golang-go`/`gh`/`nodejs` drop). Full
reasoning lives on the issue's final decision comment
(https://github.com/carpet-stain/dotfiles/issues/127#issuecomment-5013636073) — don't re-derive
it here, it's the source of truth for anyone touching this work.

**Status: #127 CLOSED 2026-07-19.** Follow-on implementation epic #361 filed the same day,
`plan-approved` (native GitHub sub-issues #362/#363/#364). Epic body + plan-review comments on
#361 are the current status; this memory entry won't be kept in sync with per-child progress —
check the epic live.

**Why:** the spike's own scope stopped at decision + sized epic outline; migration was explicitly
deferred to a follow-on epic, filed only once the user confirmed ("not creating anything without
confirmation, per instructions" — honored across two sessions apart).

**How to apply:** if #361/#362/#363/#364 ever come up stale/untriaged in a grooming sweep, they're
not new — they're the already-ratified, already-plan-reviewed execution of #127. Don't re-triage
from scratch or reclassify priority without checking the epic's plan-review comments first.

**Non-obvious findings from the plan-review pass on #361** (worth keeping since they're not
visible from the issue bodies alone):
- The children's number order (#362→#363→#364) is *not* the safe execution order. #363 (nvim
  Mason OS-gate) should land **before** #362 (Aptfile/deploy.sh leak removal) — landing #362 first
  opens a real window where Linux nvim gets Mason failed-install notifications every startup
  (`pyright`/`gopls` can't install without `node`/`go`, which #362 just removed) until #363
  catches up. #363's gate is a no-op improvement on macOS and has no dependency on #362, so
  reversing the order costs nothing and closes the window entirely.
- #363's verification can't be headless-only. `mason-tools.lua`'s own code comment already
  documents that the LazyVim-extras auto-install question didn't fire during a headless
  `deploy.zsh` bootstrap — meaning a launch-and-quit headless check is exactly the method that
  already failed to observe this once. `mason-lspconfig`'s auto-install can trigger on opening a
  buffer of the relevant filetype, which a headless `-c "qall"` run never reaches. #363 needs a
  buffer-loaded headless check (or a gate at the `mason-lspconfig`/extras level) to actually close
  this, not just launch+quit.
- #364's ADR-0006 amendment must add `python3`/`python3-pip` to the fix list. ADR-0006's current
  dev-tier enumeration only names `golang-go`/`golang-src`/`gh`/`nodejs` + the three git-script
  symlinks — it never mentions `python3`, even though #127's ratification includes it as a fifth
  leak (zero-consumers confirmed, same finding ADR-0029 made for macOS's `python3`). If #364 only
  amends the Consequences section for the mechanism and forgets this, the ADR stays out of sync
  with what actually shipped.
- #362 should also delete/rewrite `add_apt_repos()`'s and `install_apt_packages()`'s rationale
  comments once the gh/NodeSource/backports blocks and the golang-go backports-pinning explanation
  they describe are gone — otherwise the comments describe code that no longer exists.

Related: #350/ADR-0029 (macOS fnm/uv-only swap) — deliberately scoped to macOS only, explicitly
doesn't touch Linux's Aptfile/deploy.sh, leaving that scope to #127/#361.
