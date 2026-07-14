# 3. Modern-CLI-tool selection philosophy

Date: 2026-07-04

## Status

Accepted

## Context

This repo is built around modern, often-Rust CLI tools used as drop-in
replacements for coreutils defaults. The first commit (ecd45e77) already shipped
a set tagged in `macos/Brewfile` as "Better X": eza→ls, bat→cat, fd→find,
ripgrep→grep, git-delta→diff, zoxide→cd, doggo→dig, dua→du. README frames this
as "Modern Replacements: Legacy Unix utilities are replaced with modern, faster
(often Rust-based) alternatives" (README.md:38-39).

The philosophy was never written as one artifact — it was applied per-tool and
only made explicit later during a batch tool-review (#92), so what "qualifies" a
replacement needed a stated rule. The forcing constraint: none of the incumbents
were end-of-life, so "newer/shinier" is not on its own a reason to swap (#89
notes oh-my-posh and p10k are both actively maintained, so its eval "isn't an
EOL-driven swap"; #92 grooming: "No EOL driver on any of these, so the bar is a
demonstrated improvement over what already works"). A criterion was needed to
keep the toolset from churning on every new Rust CLI that appears.

(provenance: partial — no single source states this philosophy; it is
reconstructed from the pattern of tool choices plus the explicit rejections
(#92/#89). The two-bar framing, the "same Rust-modern-CLI shape" additive test,
and the EOL-makes-replacement-mandatory inverse are inferred, not stated — see
the inline "(inferred)" marks.)

## Decision

Adopt a modern CLI tool over a coreutils/incumbent default only when it earns
the spot. The #92 grooming distinguishes two situations (framing them as two
named "bars" is inferred; the sources decide case-by-case):

1. **Replacing a working incumbent** — default is keep-incumbent. The candidate
   must show a demonstrated improvement over what already works (measured, e.g.
   equal-or-faster render latency, plus theme/feature parity); otherwise
   document "evaluated, kept incumbent" and move on (#92 grooming).
2. **Additive** — a tool with no incumbent alias to conflict with has a lower
   bar: adopt if it installs and works cleanly on the primary target (macOS) and
   matches "the same Rust-modern-CLI shape as the tools already adopted in
   `aliases.zsh`" (#92 grooming-results). (The additive bar as a _named_ rule is
   inferred from the choose/dysk/procs/viddy adoption pattern.)

Catppuccin Mocha theme portability and clean coexistence with existing zsh
machinery (compinit, fzf-tab) are gating checks, not sufficient reasons on their
own — #92 rejected oh-my-posh even though its Catppuccin theme ported cleanly,
and rejected carapace even though it coexists cleanly with the completion stack.
End-of-life of an incumbent is a separate, standalone driver.

## Alternatives considered

- **oh-my-posh (vs powerlevel10k)** — kept incumbent (#89, #92). Not EOL-driven
  (both actively maintained). Full shell-startup latency was noise-level (~127ms
  p10k vs ~130ms oh-my-posh), but per-_render_ cost differs by architecture:
  oh-my-posh spawns an external binary on every prompt draw (~19ms measured for
  `oh-my-posh print primary`), while p10k renders in-process with a persistent
  gitstatusd daemon. Catppuccin Mocha ported cleanly but that alone didn't clear
  the equal-or-faster bar. No PR.
- **carapace (vs compinit + zsh-completions + fzf-tab)** — kept incumbent (#92).
  Verified it coexists cleanly with the repo's `completions.zsh` + `fzf-tab.zsh`
  (not a conflict), but it solves no unaddressed gap: nothing in the current
  toolset lacks a zsh completion. No PR; revisit per-tool if a specific
  completion gap appears.

## Consequences

Easier: a new Rust CLI has a clear test — a measured win over the incumbent, or
an additive fit — so evaluations end in a decision instead of drifting. #92 is
that review, with its sub-PRs (#189 additive coreutils aliases; #190 deja; #191
zsh-patina) landing the winners.

The coreutils-replacement set now wired in `zsh/rc.d/aliases.zsh` is:
`cat=bat -p`, `find=fd`, `ls=eza`, `grep=rg`, `diff=delta`, `du=dua`,
`dig=doggo`, `df=dysk`, `ps=procs`, `watch=viddy` (plus `cd`→zoxide via zoxide's
own init). README's "Modern Replacements" section is the human-facing statement.
`choose` was adopted additively in #189 (`cut`→choose) but later removed
(3315dde0): its `-c` range syntax (`5:`/`5..`, not `5-`) is not a drop-in for
`cut -c5-`, so shell integrations emitting `cut -c5-` errored on every
interactive startup — a reminder that the additive "installs and works cleanly"
bar has to include real drop-in compatibility, not just a clean install.

Harder: every incumbent swap now needs a benchmark, which is real hands-on work
and hard to do faithfully in a non-TTY sandbox — #92's verification caveat flags
that p10k's gitstatusd, zsh-patina's live daemon, and viddy's TUI couldn't be
exercised at full fidelity, so spot-checks were deferred to the merging PR.

Rejected candidates aren't closed forever: revisit per-tool if a premise changes
— carapace if a real completion gap appears (#92). If an incumbent hits EOL, the
equal-or-faster bar no longer applies and replacement becomes mandatory
(inferred — #89/#92 establish the keep-incumbent-by- default rule when there's
no EOL driver, but no source states this inverse).
