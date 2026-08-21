# Changelog

All notable changes to this project, generated from Conventional Commits.
## [1.10.0] - 2026-08-21

### Features

- *(ssh)* Route github through secretive agent ([#615](https://github.com/carpet-stain/dotfiles/pull/615))
- *(claude)* Agent-gh wrapper — run gh as a deliberation agent ([#618](https://github.com/carpet-stain/dotfiles/pull/618))
- *(github)* Just revend — one-shot recovery of the vended token's dead window ([#622](https://github.com/carpet-stain/dotfiles/pull/622))
- *(claude)* Vendored agent cloud channel for plan-reviewer ([#625](https://github.com/carpet-stain/dotfiles/pull/625))
- *(github)* Infra-gh — thin gh wrapper that drops the vended token ([#641](https://github.com/carpet-stain/dotfiles/pull/641))
- *(claude)* Scope infra-gh issue-management verbs into permissions.allow ([#644](https://github.com/carpet-stain/dotfiles/pull/644))
- *(github)* Pin GH_REPO=carpet-stain/infra in infra-gh ([#649](https://github.com/carpet-stain/dotfiles/pull/649))
- *(github)* Admin-gh — one-command local admin-PAT escalation ([#651](https://github.com/carpet-stain/dotfiles/pull/651))

### Bug Fixes

- *(github)* Admin-gh execs gh directly, no literal gh in the call ([#653](https://github.com/carpet-stain/dotfiles/pull/653))
- *(release)* Tolerate already-deleted branch in release-publish delete step ([#660](https://github.com/carpet-stain/dotfiles/pull/660))

### Documentation

- *(adr)* ADR-0048 — hosted GitHub Actions runtimes for plan-reviewer and the implementor ([#624](https://github.com/carpet-stain/dotfiles/pull/624))
- *(adr)* ADR-0049 — go with the DIY act-poller for Actions-outage resilience ([#633](https://github.com/carpet-stain/dotfiles/pull/633))

### CI

- *(review)* Fetch the OpenRouter key from SSM via OIDC, drop the repo secret ([#631](https://github.com/carpet-stain/dotfiles/pull/631))
- *(adr-guard)* Drop the labeled/unlabeled trigger ([#654](https://github.com/carpet-stain/dotfiles/pull/654))
- *(reusable)* Switch guards to thin reusable-workflow callers ([#655](https://github.com/carpet-stain/dotfiles/pull/655))
- *(reusable)* Adopt the shared adr-guard and pr-guards callers ([#656](https://github.com/carpet-stain/dotfiles/pull/656))
- *(reusable)* Pin the shared-guard callers to the moving v1 tag ([#657](https://github.com/carpet-stain/dotfiles/pull/657))

### Chore

- *(claude)* Bump claude/global — backlog-manager attribution ([#620](https://github.com/carpet-stain/dotfiles/pull/620))

## [1.9.0] - 2026-08-17

### Features

- *(claude)* Add grilling skill + backlog-manager trigger wiring ([#481](https://github.com/carpet-stain/dotfiles/pull/481))
- *(claude)* Add groom-backlog skill, relocate sweep procedure ([#482](https://github.com/carpet-stain/dotfiles/pull/482))
- *(claude)* Journal plan-reviewer critiques as condensed digests ([#483](https://github.com/carpet-stain/dotfiles/pull/483))
- *(claude)* Add implement-issue skill ([#484](https://github.com/carpet-stain/dotfiles/pull/484))
- *(claude)* Drop timebox from spike convention ([#488](https://github.com/carpet-stain/dotfiles/pull/488))
- *(github)* Decouple pr-code-review's trigger from the architecture label ([#489](https://github.com/carpet-stain/dotfiles/pull/489))
- *(ci)* Check the PR diff against the plan it closes ([#491](https://github.com/carpet-stain/dotfiles/pull/491))
- *(github)* Require a closing issue reference or No-Issue marker ([#492](https://github.com/carpet-stain/dotfiles/pull/492))
- *(ci)* Companion-file coupling guard ([#496](https://github.com/carpet-stain/dotfiles/pull/496))
- *(claude)* Just work-queue — cross-repo dispatch digest ([#497](https://github.com/carpet-stain/dotfiles/pull/497))
- *(claude)* Seed voice.md from session transcripts ([#499](https://github.com/carpet-stain/dotfiles/pull/499))
- *(claude)* Deny-list generated and mirrored paths from agent reads ([#502](https://github.com/carpet-stain/dotfiles/pull/502))
- *(theme)* Ghostty + nvim follow macOS appearance natively ([#504](https://github.com/carpet-stain/dotfiles/pull/504))
- *(zsh)* THEME_MODE derivation drives all CLI theme surfaces ([#505](https://github.com/carpet-stain/dotfiles/pull/505))
- *(zellij)* Follow macOS appearance natively via CSI 2031 ([#509](https://github.com/carpet-stain/dotfiles/pull/509))
- *(credentials)* Fetch vended token from SSM, retire bws (infra#125) ([#525](https://github.com/carpet-stain/dotfiles/pull/525))
- *(credentials)* Audit keychain prompt gate ([#534](https://github.com/carpet-stain/dotfiles/pull/534))
- *(credentials)* Route routine GH_TOKEN through the vended token ([#537](https://github.com/carpet-stain/dotfiles/pull/537))
- *(claude)* Trial MCP memory for backlog-manager ([#541](https://github.com/carpet-stain/dotfiles/pull/541))
- *(zellij)* Floating aichat scratch pane for command generation ([#554](https://github.com/carpet-stain/dotfiles/pull/554))
- *(claude)* Cut backlog-manager over to MCP graph memory ([#561](https://github.com/carpet-stain/dotfiles/pull/561))
- *(claude)* Generalize audit-memory to the graph store ([#562](https://github.com/carpet-stain/dotfiles/pull/562))
- *(claude)* Agents read as AI, not impersonated voices ([#564](https://github.com/carpet-stain/dotfiles/pull/564))
- *(claude)* Author shipped work as the implementor identity ([#565](https://github.com/carpet-stain/dotfiles/pull/565))
- *(claude)* Grill non-trivial issues by default ([#575](https://github.com/carpet-stain/dotfiles/pull/575))
- *(ci)* Block comments over the 2-line cap ([#578](https://github.com/carpet-stain/dotfiles/pull/578))
- *(zsh)* Add Alt+I inline command fill widget ([#584](https://github.com/carpet-stain/dotfiles/pull/584))
- *(zsh)* Add git and docker probes to inline command fill ([#586](https://github.com/carpet-stain/dotfiles/pull/586))
- *(zellij)* Live tab name from cwd and foreground command ([#589](https://github.com/carpet-stain/dotfiles/pull/589))
- *(claude)* Back up agent-memory store to B2 ([#595](https://github.com/carpet-stain/dotfiles/pull/595))
- *(zsh)* Add kubectl/brew/gh/base probes to inline command fill ([#599](https://github.com/carpet-stain/dotfiles/pull/599))
- *(claude)* Wire ccusage as the coarse token-usage layer ([#601](https://github.com/carpet-stain/dotfiles/pull/601))
- *(claude)* Transcript token-attribution parser — per-activity split + per-issue rollup ([#604](https://github.com/carpet-stain/dotfiles/pull/604))
- *(claude)* Weekly usage snapshot before the 30-day transcript prune ([#606](https://github.com/carpet-stain/dotfiles/pull/606))
- *(ci)* Close an epic when its last sub-issue closes ([#609](https://github.com/carpet-stain/dotfiles/pull/609))
- *(claude)* Per-spike token accounting — effort in tokens, calibrated from real spend ([#611](https://github.com/carpet-stain/dotfiles/pull/611))

### Bug Fixes

- *(claude)* Rebuild memory-pr via a temp index ([#500](https://github.com/carpet-stain/dotfiles/pull/500))
- *(ci)* Bump pr-review model to gpt-5.6-sol ([#501](https://github.com/carpet-stain/dotfiles/pull/501))
- *(ci)* Exempt chore/sync-backlog-memory PRs from the issue-link guard ([#551](https://github.com/carpet-stain/dotfiles/pull/551))
- *(claude)* Shell-expand MCP memory store path ([#558](https://github.com/carpet-stain/dotfiles/pull/558))
- *(claude)* Harden MCP memory wiring found at rollout ([#559](https://github.com/carpet-stain/dotfiles/pull/559))
- *(claude)* Keyword recall + read_graph fallback ([#571](https://github.com/carpet-stain/dotfiles/pull/571))

### Refactor

- *(ci)* Install lint tools from Brewfile.dev/payload in ci.yml ([#503](https://github.com/carpet-stain/dotfiles/pull/503))
- *(claude)* Extract stable subset to carpet-stain/agents (Phase 1) ([#588](https://github.com/carpet-stain/dotfiles/pull/588))
- *(claude)* Extract backlog-manager.md + voice.md (Phase 2) ([#590](https://github.com/carpet-stain/dotfiles/pull/590))
- *(direnv)* Share the vended-token GITHUB_TOKEN bridge ([#593](https://github.com/carpet-stain/dotfiles/pull/593))

### Documentation

- *(git)* Add PR handoff discipline — self-sufficient top post ([#480](https://github.com/carpet-stain/dotfiles/pull/480))
- *(adr)* Amend ADR-0034 with spike #506's Zellij theme findings ([#507](https://github.com/carpet-stain/dotfiles/pull/507))
- *(claude)* Add reuse-search ladder to Simplicity First ([#512](https://github.com/carpet-stain/dotfiles/pull/512))
- *(claude)* Record the MCP context-tax bar ([#513](https://github.com/carpet-stain/dotfiles/pull/513))
- *(claude)* Add a skill-worthy bar to the authoring convention ([#514](https://github.com/carpet-stain/dotfiles/pull/514))
- *(credentials)* Swap retired infra-bws contrast for infra-aws-local-apply ([#526](https://github.com/carpet-stain/dotfiles/pull/526))
- *(adr)* Deliberation as named agent identities ([#539](https://github.com/carpet-stain/dotfiles/pull/539))
- *(adr)* Record agent-repo extraction residency ([#572](https://github.com/carpet-stain/dotfiles/pull/572))
- *(claude)* Per-repo backlog with virtual multi-repo overlay ([#573](https://github.com/carpet-stain/dotfiles/pull/573))
- *(adr)* Supersede ADR-0007 with the vended-token model ([#574](https://github.com/carpet-stain/dotfiles/pull/574))
- *(adr)* Record the shared-agent roster and operating model ([#577](https://github.com/carpet-stain/dotfiles/pull/577))
- *(adr)* Record the hosted per-role agent-memory architecture ([#600](https://github.com/carpet-stain/dotfiles/pull/600))
- *(adr)* Record the epic-completion reach and guard decision ([#605](https://github.com/carpet-stain/dotfiles/pull/605))
- *(claude)* Relocate AGENTS.md restated facts to their in-repo homes ([#614](https://github.com/carpet-stain/dotfiles/pull/614))

### Chore

- Update repo-watch state ([#466](https://github.com/carpet-stain/dotfiles/pull/466))
- *(claude)* Sync backlog-manager memory ([#467](https://github.com/carpet-stain/dotfiles/pull/467))
- *(claude)* Sync backlog-manager memory ([#468](https://github.com/carpet-stain/dotfiles/pull/468))
- *(claude)* Sync backlog-manager memory ([#469](https://github.com/carpet-stain/dotfiles/pull/469))
- *(macos)* Drop the zsh-patina tap — formula moved into homebrew-core ([#485](https://github.com/carpet-stain/dotfiles/pull/485))
- *(theme)* Bump catppuccin/bat pin — manpage colors, JSON key highlight ([#486](https://github.com/carpet-stain/dotfiles/pull/486))
- *(zsh)* Bump fzf-tab pin, add active-group-style zstyle ([#487](https://github.com/carpet-stain/dotfiles/pull/487))
- *(claude)* Sync backlog-manager memory ([#495](https://github.com/carpet-stain/dotfiles/pull/495))
- *(zsh)* Drop redundant --no-separator on darwin ([#515](https://github.com/carpet-stain/dotfiles/pull/515))
- Update repo-watch state ([#524](https://github.com/carpet-stain/dotfiles/pull/524))
- *(claude)* Stop committing agent-memory ([#553](https://github.com/carpet-stain/dotfiles/pull/553))
- *(ci)* Sweep comments to the 2-line cap ([#580](https://github.com/carpet-stain/dotfiles/pull/580))

## [1.8.0] - 2026-07-27

### Features

- *(claude)* Nudge /audit-memory when agent-memory files change ([#357](https://github.com/carpet-stain/dotfiles/pull/357))
- *(macos)* Replace Homebrew-managed node and python with fnm and uv-only ([#360](https://github.com/carpet-stain/dotfiles/pull/360))
- *(zsh)* Add edit-command-line widget on Alt+E ([#359](https://github.com/carpet-stain/dotfiles/pull/359))
- *(nvim)* Prefer system-installed LSP/lint/format tooling over Mason's own ([#371](https://github.com/carpet-stain/dotfiles/pull/371))
- *(claude)* Land comment-concision advisory lint (reference impl) ([#378](https://github.com/carpet-stain/dotfiles/pull/378))
- *(claude)* Consolidate converged plan into issue body at gate-flip ([#385](https://github.com/carpet-stain/dotfiles/pull/385))
- *(macos)* Install bws CLI in the deploy script ([#402](https://github.com/carpet-stain/dotfiles/pull/402))
- *(ci)* Add a lefthook job for justfile format/syntax check ([#420](https://github.com/carpet-stain/dotfiles/pull/420))
- *(ci)* Add a just recipe to auto-format markdown ([#422](https://github.com/carpet-stain/dotfiles/pull/422))
- *(ci)* Widen yaml-format to all yaml, tune folded scalars ([#424](https://github.com/carpet-stain/dotfiles/pull/424))
- *(ci)* Add editorconfig-checker for files no formatter covers ([#423](https://github.com/carpet-stain/dotfiles/pull/423))
- *(ci)* Add gitleaks secret scanning ([#427](https://github.com/carpet-stain/dotfiles/pull/427))
- *(zsh)* Consume infra's vended Bitwarden token in local/agent shells ([#403](https://github.com/carpet-stain/dotfiles/pull/403))
- *(ci)* Advisory context-budget lint for always-loaded agent files ([#446](https://github.com/carpet-stain/dotfiles/pull/446))
- *(ci)* Add per-line PR review comments with applyable suggestions ([#370](https://github.com/carpet-stain/dotfiles/pull/370))

### Bug Fixes

- *(claude)* Wire up git memory-pr per ADR-0027 ([#392](https://github.com/carpet-stain/dotfiles/pull/392))
- *(ci)* Run formatters before linters in lefthook ([#418](https://github.com/carpet-stain/dotfiles/pull/418))
- *(claude)* Rebuild git memory-pr on a rolling draft PR ([#429](https://github.com/carpet-stain/dotfiles/pull/429))
- *(zsh)* Remap deja's Tab cycle binding to Shift-Tab ([#438](https://github.com/carpet-stain/dotfiles/pull/438))
- *(linux)* Install deja and zsh-patina, drop stale fsh references ([#444](https://github.com/carpet-stain/dotfiles/pull/444))
- *(git)* Default git pr --draft title from HEAD commit subject ([#455](https://github.com/carpet-stain/dotfiles/pull/455))
- *(linux)* Pin fzf via binaries.lock instead of Debian's stale apt package ([#459](https://github.com/carpet-stain/dotfiles/pull/459))
- *(zsh)* Fall back XDG_RUNTIME_DIR when unwritable on Linux ([#460](https://github.com/carpet-stain/dotfiles/pull/460))

### Documentation

- Migrate ISSUE_TEMPLATE to structured issue forms ([#369](https://github.com/carpet-stain/dotfiles/pull/369))
- Shorten AGENTS.md — cut restated specs and duplication ([#426](https://github.com/carpet-stain/dotfiles/pull/426))
- *(claude)* Codify the memory content contract (ADR-0033) ([#430](https://github.com/carpet-stain/dotfiles/pull/430))
- *(claude)* Add memory residency rule and cross-repo maps ([#434](https://github.com/carpet-stain/dotfiles/pull/434))
- *(adr)* Decline memory-pr auto-merge, amend ADR-0027 ([#435](https://github.com/carpet-stain/dotfiles/pull/435))

### Chore

- *(zsh)* Keep fzf's own popup border under Zellij ([#356](https://github.com/carpet-stain/dotfiles/pull/356))
- *(git)* Retire scripts/labels.json and apply-labels.sh ([#358](https://github.com/carpet-stain/dotfiles/pull/358))
- *(claude)* Sync backlog-manager memory ([#367](https://github.com/carpet-stain/dotfiles/pull/367))
- *(ci)* Add github-actions ecosystem to dependabot.yml ([#368](https://github.com/carpet-stain/dotfiles/pull/368))
- *(macos)* Tag Brewfile tiers, add Linux leak guard, redefine dev tier ([#373](https://github.com/carpet-stain/dotfiles/pull/373))
- *(claude)* Sync backlog-manager memory ([#401](https://github.com/carpet-stain/dotfiles/pull/401))
- *(claude)* Sync backlog-manager memory ([#404](https://github.com/carpet-stain/dotfiles/pull/404))
- *(claude)* Sync backlog-manager memory ([#415](https://github.com/carpet-stain/dotfiles/pull/415))
- *(claude)* Sync backlog-manager memory ([#417](https://github.com/carpet-stain/dotfiles/pull/417))
- *(claude)* Codify fresh-subagent audit-memory invocation ([#432](https://github.com/carpet-stain/dotfiles/pull/432))
- *(claude)* Route backlog-manager + plan-reviewer to Opus 4 at medium effort ([#447](https://github.com/carpet-stain/dotfiles/pull/447))
- *(zsh)* Remove zsh-you-should-use plugin ([#448](https://github.com/carpet-stain/dotfiles/pull/448))
- *(claude)* Sharpen plan-reviewer.md with codex adversarial-review prompt IP ([#450](https://github.com/carpet-stain/dotfiles/pull/450))
- *(claude)* Sync backlog-manager memory ([#451](https://github.com/carpet-stain/dotfiles/pull/451))

## [1.7.0] - 2026-07-19

### Features

- *(claude)* Close compose/audit lifecycle gaps ([#233](https://github.com/carpet-stain/dotfiles/pull/233))
- *(git)* Add adr-guard to the git-flow template ([#250](https://github.com/carpet-stain/dotfiles/pull/250))
- *(macos)* Support no-sudo homebrew prefixes ([#259](https://github.com/carpet-stain/dotfiles/pull/259))
- *(zsh)* Add you-should-use alias reminders ([#265](https://github.com/carpet-stain/dotfiles/pull/265))
- *(git)* Complete the git-flow copier bootstrap base ([#277](https://github.com/carpet-stain/dotfiles/pull/277))
- *(python)* Compose the python overlay with the git-flow base ([#279](https://github.com/carpet-stain/dotfiles/pull/279))
- *(git)* Add retrofit-governance.sh — additive template apply for existing repos ([#283](https://github.com/carpet-stain/dotfiles/pull/283))
- *(claude)* Add python language conventions rule ([#287](https://github.com/carpet-stain/dotfiles/pull/287))
- *(claude)* Add terraform conventions rule ([#293](https://github.com/carpet-stain/dotfiles/pull/293))
- *(terraform)* Manage the dotfiles repo with opentofu ([#295](https://github.com/carpet-stain/dotfiles/pull/295))
- *(terraform)* Wire tf lint/scan into hooks and ci ([#296](https://github.com/carpet-stain/dotfiles/pull/296))
- *(terraform)* Create the infra repo as code ([#306](https://github.com/carpet-stain/dotfiles/pull/306))
- *(claude)* Harden audit-rules doc coverage + add ADR-ref check ([#320](https://github.com/carpet-stain/dotfiles/pull/320))
- *(claude)* Add read-only audit-memory skill ([#323](https://github.com/carpet-stain/dotfiles/pull/323))
- *(claude)* Issue templates + backlog-manager read-and-fill ([#324](https://github.com/carpet-stain/dotfiles/pull/324))
- *(claude)* Add verify-nvim-config skill ([#326](https://github.com/carpet-stain/dotfiles/pull/326))
- *(claude)* Add read-only plan-reviewer subagent ([#321](https://github.com/carpet-stain/dotfiles/pull/321))
- *(claude)* Build the plan-review gate into backlog-manager ([#328](https://github.com/carpet-stain/dotfiles/pull/328))
- *(ghostty)* Install terminfo on remote hosts over ssh ([#275](https://github.com/carpet-stain/dotfiles/pull/275))
- *(claude)* Scoped script for backlog-manager's memory PRs ([#339](https://github.com/carpet-stain/dotfiles/pull/339))
- *(claude)* Tighten backlog-manager's plan-review gate ([#344](https://github.com/carpet-stain/dotfiles/pull/344))
- *(claude)* Audit-memory flags misplaced durable content ([#345](https://github.com/carpet-stain/dotfiles/pull/345))

### Bug Fixes

- *(zsh)* Drop broken cut→choose alias ([#232](https://github.com/carpet-stain/dotfiles/pull/232))
- *(claude)* Point smoke-test claude/rules check at ~/.claude ([#234](https://github.com/carpet-stain/dotfiles/pull/234))
- *(github)* Drop both tokens to elevate gh to admin ([#244](https://github.com/carpet-stain/dotfiles/pull/244))
- *(github)* Clear legacy branch protection in bootstrap ([#253](https://github.com/carpet-stain/dotfiles/pull/253))
- *(macos)* Use vendored ghostty terminfo source ([#254](https://github.com/carpet-stain/dotfiles/pull/254))
- *(macos)* Anchor brew symlinks to main checkout ([#260](https://github.com/carpet-stain/dotfiles/pull/260))
- *(macos)* Install tflint as a cask, not a formula ([#317](https://github.com/carpet-stain/dotfiles/pull/317))
- *(claude)* Read origin/main before memory writes ([#318](https://github.com/carpet-stain/dotfiles/pull/318))
- *(claude)* Amend ADR-0025's implementer tier from Haiku to Sonnet ([#337](https://github.com/carpet-stain/dotfiles/pull/337))
- *(claude)* Exclude agent-memory from git-flow's lefthook-base.yml ([#343](https://github.com/carpet-stain/dotfiles/pull/343))
- *(zsh)* Unquote compdump freshness glob so -C cache branch is reachable ([#353](https://github.com/carpet-stain/dotfiles/pull/353))
- *(git)* Default git pr --draft body to the PR template ([#354](https://github.com/carpet-stain/dotfiles/pull/354))

### Refactor

- *(claude)* Make doc-ownership a universal rule ([#235](https://github.com/carpet-stain/dotfiles/pull/235))
- *(zsh)* Sweep comments to stingy why-not-what + pointer form ([#255](https://github.com/carpet-stain/dotfiles/pull/255))
- *(nvim)* Sweep comments to stingy why-not-what form ([#257](https://github.com/carpet-stain/dotfiles/pull/257))
- *(macos)* Sweep deploy-script comments to why-not-what form ([#258](https://github.com/carpet-stain/dotfiles/pull/258))
- *(git)* Sweep config comments to stingy why-not-what form ([#261](https://github.com/carpet-stain/dotfiles/pull/261))
- *(theme)* Sweep loose-config comments to why-not-what form ([#263](https://github.com/carpet-stain/dotfiles/pull/263))
- *(git)* Disjoint file ownership for base + overlay via native composition ([#284](https://github.com/carpet-stain/dotfiles/pull/284))
- *(git)* Drop the copier answers file — no copier update path ([#288](https://github.com/carpet-stain/dotfiles/pull/288))
- *(git)* Remove copier templates from dotfiles after extraction ([#351](https://github.com/carpet-stain/dotfiles/pull/351))

### Documentation

- Adopt adr-tools and backfill 18 ADRs from history ([#245](https://github.com/carpet-stain/dotfiles/pull/245))
- Break README↔AGENTS circular pointer and dedup deploy steps ([#249](https://github.com/carpet-stain/dotfiles/pull/249))
- *(git)* Make the seeded README pointer-only to avoid drift ([#281](https://github.com/carpet-stain/dotfiles/pull/281))
- *(claude)* Bring go.md to python.md parity ([#290](https://github.com/carpet-stain/dotfiles/pull/290))
- Decide repos-as-code foundation (ADR-0022) ([#292](https://github.com/carpet-stain/dotfiles/pull/292))
- Scrap the tf overlay, keep the repo move (ADR-0024) ([#297](https://github.com/carpet-stain/dotfiles/pull/297))
- *(claude)* Document the lean-SKILL.md authoring convention ([#319](https://github.com/carpet-stain/dotfiles/pull/319))
- *(adr)* Reject a skill-activation nudge hook (ADR-0026) ([#325](https://github.com/carpet-stain/dotfiles/pull/325))
- *(adr)* Advisory review pipeline + model tiers (ADR-0025) ([#322](https://github.com/carpet-stain/dotfiles/pull/322))

### Build

- Adopt just as the repo task runner ([#252](https://github.com/carpet-stain/dotfiles/pull/252))

### CI

- Cache homebrew cellar and release tarballs ([#264](https://github.com/carpet-stain/dotfiles/pull/264))
- Relink brew formulae after cache restore ([#285](https://github.com/carpet-stain/dotfiles/pull/285))
- Drop the fragile Homebrew bottle cache, install fresh each run ([#286](https://github.com/carpet-stain/dotfiles/pull/286))
- *(git-flow)* Make the base lint workflow portable, drop Homebrew ([#289](https://github.com/carpet-stain/dotfiles/pull/289))
- Add advisory non-Anthropic PR code review ([#329](https://github.com/carpet-stain/dotfiles/pull/329))

### Chore

- *(github)* Add agent-ready to the portable label manifest ([#251](https://github.com/carpet-stain/dotfiles/pull/251))
- *(terraform)* Move the repos-as-code config to infra ([#308](https://github.com/carpet-stain/dotfiles/pull/308))
- *(claude)* Sync backlog-manager memory ([#316](https://github.com/carpet-stain/dotfiles/pull/316))
- *(claude)* Pin backlog-manager to Sonnet ([#327](https://github.com/carpet-stain/dotfiles/pull/327))
- *(claude)* Sync backlog-manager memory ([#340](https://github.com/carpet-stain/dotfiles/pull/340))
- *(claude)* Sync backlog-manager memory ([#346](https://github.com/carpet-stain/dotfiles/pull/346))
- *(claude)* Close out copier-extraction memory after epic #309 ([#352](https://github.com/carpet-stain/dotfiles/pull/352))

## [1.6.0] - 2026-07-14

### Features

- *(zsh)* Replace fast-syntax-highlighting with zsh-patina ([#191](https://github.com/carpet-stain/dotfiles/pull/191))
- *(zsh)* Replace zsh-autosuggestions with deja ([#190](https://github.com/carpet-stain/dotfiles/pull/190))
- *(zsh)* Add choose/dysk/procs/viddy modern-replacement aliases ([#189](https://github.com/carpet-stain/dotfiles/pull/189))
- *(claude)* Audit-rules — add cross-doc replication check ([#224](https://github.com/carpet-stain/dotfiles/pull/224))
- *(claude)* Add sprawl reduction playbook to audit-rules ([#225](https://github.com/carpet-stain/dotfiles/pull/225))

### Bug Fixes

- *(ci)* Exempt draft PRs from ci.yml and e2e-linux.yml ([#211](https://github.com/carpet-stain/dotfiles/pull/211))
- *(deploy)* Stream long-running deploy steps live ([#216](https://github.com/carpet-stain/dotfiles/pull/216))
- *(zsh)* Relocate npm init-module under XDG_CONFIG_HOME ([#220](https://github.com/carpet-stain/dotfiles/pull/220))
- *(macos)* Stop deja history seed from silently no-oping ([#212](https://github.com/carpet-stain/dotfiles/pull/212))
- *(macos)* Symlink git-squash onto PATH ([#218](https://github.com/carpet-stain/dotfiles/pull/218))
- *(linux)* Compile ghostty terminfo to default search path ([#221](https://github.com/carpet-stain/dotfiles/pull/221))
- *(zsh)* Prepend user path dirs instead of appending ([#228](https://github.com/carpet-stain/dotfiles/pull/228))
- *(theme)* Bump delta submodule for mocha contrast/decoration fixes ([#229](https://github.com/carpet-stain/dotfiles/pull/229))
- *(zsh)* Skip zsh-defer without a controlling terminal ([#226](https://github.com/carpet-stain/dotfiles/pull/226))

### Refactor

- *(docs)* De-dup AGENTS.md and README.md overlap ([#222](https://github.com/carpet-stain/dotfiles/pull/222))
- *(zsh)* Extract fzf config to env.d/fzf.zsh ([#227](https://github.com/carpet-stain/dotfiles/pull/227))

### Documentation

- *(zsh)* Note brew shellenv sets FPATH (site-functions) ([#217](https://github.com/carpet-stain/dotfiles/pull/217))
- *(claude)* Adopt ADRs + a documentation home map ([#214](https://github.com/carpet-stain/dotfiles/pull/214))
- *(claude)* Name comment-as-pointer form in comment guidance ([#219](https://github.com/carpet-stain/dotfiles/pull/219))

### CI

- Shellcheck .envrc* to match nvim ([#215](https://github.com/carpet-stain/dotfiles/pull/215))

### Chore

- Update repo-watch state ([#197](https://github.com/carpet-stain/dotfiles/pull/197))
- *(claude)* Use ~/.claude for everything, drop XDG relocation ([#223](https://github.com/carpet-stain/dotfiles/pull/223))

## [1.5.0] - 2026-07-13

### Features

- *(linux)* Pin release binaries to checksummed versions ([#105](https://github.com/carpet-stain/dotfiles/pull/105))
- *(claude)* Add audit-rules skill ([#113](https://github.com/carpet-stain/dotfiles/pull/113))
- *(claude)* Add compose-agents skill ([#114](https://github.com/carpet-stain/dotfiles/pull/114))
- *(python)* Add uv to Brewfile for project scaffolding ([#132](https://github.com/carpet-stain/dotfiles/pull/132))
- *(python)* Prototype copier template for project starter ([#133](https://github.com/carpet-stain/dotfiles/pull/133))
- *(git)* Open PRs early as drafts and journal decisions via comments ([#144](https://github.com/carpet-stain/dotfiles/pull/144))
- *(claude)* Compose-agents/audit-rules — point at enforced config, don't restate it ([#146](https://github.com/carpet-stain/dotfiles/pull/146))
- *(claude)* Run /audit-rules hook on AGENTS.md edits ([#155](https://github.com/carpet-stain/dotfiles/pull/155))
- *(git)* Add git new/sync helpers + git maintenance ([#154](https://github.com/carpet-stain/dotfiles/pull/154))
- *(git)* Add branch-protection ruleset bootstrap script ([#162](https://github.com/carpet-stain/dotfiles/pull/162))
- *(claude)* Add provenance check before deleting code ([#166](https://github.com/carpet-stain/dotfiles/pull/166))
- *(git)* Add git-flow copier template for portable governance bootstrap ([#167](https://github.com/carpet-stain/dotfiles/pull/167))
- *(git)* Add labels-as-code bootstrap script ([#170](https://github.com/carpet-stain/dotfiles/pull/170))
- *(claude)* Add go app-structure rules, track agent memory ([#179](https://github.com/carpet-stain/dotfiles/pull/179))
- *(claude)* Flag AGENTS.md length in audit-rules sprawl check ([#180](https://github.com/carpet-stain/dotfiles/pull/180))
- *(python)* Add py-new bootstrap command for the copier template ([#182](https://github.com/carpet-stain/dotfiles/pull/182))
- *(macos)* Add on-demand colima Docker runtime for act ([#183](https://github.com/carpet-stain/dotfiles/pull/183))

### Bug Fixes

- Anchor deploy scripts to the shared .git dir, not their own path ([#120](https://github.com/carpet-stain/dotfiles/pull/120))
- *(git)* Restore PR-number changelog links lost to rebase-merge ([#121](https://github.com/carpet-stain/dotfiles/pull/121))
- *(claude)* Consolidate git.md layer onto rebase-merge model ([#128](https://github.com/carpet-stain/dotfiles/pull/128))
- *(python)* Stop globally ignoring .python-version ([#135](https://github.com/carpet-stain/dotfiles/pull/135))
- *(git)* Resolve changelog PR links via git-cliff GitHub remote ([#141](https://github.com/carpet-stain/dotfiles/pull/141))
- *(git)* Reconcile can't-self-verify section with draft-PR-early ([#148](https://github.com/carpet-stain/dotfiles/pull/148))
- *(ci)* Skip Linux e2e deploy for claude/-only markdown changes ([#149](https://github.com/carpet-stain/dotfiles/pull/149))
- *(claude)* Reconcile compose-agents with git.md's model ([#161](https://github.com/carpet-stain/dotfiles/pull/161))
- *(git)* Remove git-pr-link's direct-to-ready fallback ([#163](https://github.com/carpet-stain/dotfiles/pull/163))
- *(ci)* Checkout main, not dev, in release-prepare.yml ([#168](https://github.com/carpet-stain/dotfiles/pull/168))
- *(git)* Rebase onto origin/main at pr finalize, not just start ([#173](https://github.com/carpet-stain/dotfiles/pull/173))
- *(git)* Add git squash alias, fix unsafe reset --soft recipe ([#174](https://github.com/carpet-stain/dotfiles/pull/174))
- *(git)* Mark PR ready before pushing, not after ([#176](https://github.com/carpet-stain/dotfiles/pull/176))
- *(zsh)* Load direnv env in non-interactive shells too ([#177](https://github.com/carpet-stain/dotfiles/pull/177))
- *(claude)* Document ~/.claude XDG exception for daemon/telemetry ([#181](https://github.com/carpet-stain/dotfiles/pull/181))

### Refactor

- *(claude)* Trim rule files to terse directives ([#104](https://github.com/carpet-stain/dotfiles/pull/104))
- *(claude)* De-dup restated specs in rules tree ([#156](https://github.com/carpet-stain/dotfiles/pull/156))
- *(git)* Finalize PR to ready at handoff instead of holding draft ([#165](https://github.com/carpet-stain/dotfiles/pull/165))

### Documentation

- *(agents)* Make the release section automation-first ([#103](https://github.com/carpet-stain/dotfiles/pull/103))
- *(claude)* Consolidate README and fix review findings ([#106](https://github.com/carpet-stain/dotfiles/pull/106))
- Audit and document the keybinding chain ([#122](https://github.com/carpet-stain/dotfiles/pull/122))
- *(git)* Point at pr-guards.yml instead of restating types ([#164](https://github.com/carpet-stain/dotfiles/pull/164))
- *(git)* Add git-flow bootstrap runbook ([#171](https://github.com/carpet-stain/dotfiles/pull/171))

### Build

- Codify linters/formatters per file type ([#110](https://github.com/carpet-stain/dotfiles/pull/110))

### CI

- Adopt feature-branch rebase-merge workflow, retire dev ([#107](https://github.com/carpet-stain/dotfiles/pull/107))
- Migrate pre-commit hooks to lefthook ([#109](https://github.com/carpet-stain/dotfiles/pull/109))
- Add Linux e2e deploy + smoke-test workflow ([#117](https://github.com/carpet-stain/dotfiles/pull/117))

## [1.4.0] - 2026-07-11

### Features

- *(zsh)* Add zmv batch-rename and portable clipboard aliases ([#93](https://github.com/carpet-stain/dotfiles/pull/93))
- *(claude)* Add layered global agent-config system ([#94](https://github.com/carpet-stain/dotfiles/pull/94))
- *(nvim)* Auto-refresh neo-tree like an IDE explorer ([#95](https://github.com/carpet-stain/dotfiles/pull/95))
- *(linux)* Vendor zsh plugins as submodules; add make-test; drop forgit ([#98](https://github.com/carpet-stain/dotfiles/pull/98))
- *(claude)* Add backlog-manager subagent ([#100](https://github.com/carpet-stain/dotfiles/pull/100))
- *(linux)* Xterm-ghostty terminfo, work-VM docs, remove arch scaffolding ([#101](https://github.com/carpet-stain/dotfiles/pull/101))

### Documentation

- *(readme)* Document how to roll back to or install a tagged release ([#79](https://github.com/carpet-stain/dotfiles/pull/79))

## [1.3.1] - 2026-07-10

### Bug Fixes

- *(ci)* Use a PAT for release PR creation to avoid action_required ([#72](https://github.com/carpet-stain/dotfiles/pull/72))
- *(ci)* Don't silently allow a push through when fetch fails ([#77](https://github.com/carpet-stain/dotfiles/pull/77))

## [1.3.0] - 2026-07-10

### Features

- *(nvim)* Add json, yaml, markdown, zsh language support ([#67](https://github.com/carpet-stain/dotfiles/pull/67))

### CI

- Enforce PR title format and automate release cutting ([#69](https://github.com/carpet-stain/dotfiles/pull/69))
- Shift-left tooling, credential scoping, and pre-push automation ([#70](https://github.com/carpet-stain/dotfiles/pull/70))

### Chore

- Xdg home audit — gopath, npm, ssh symlink, session suppress ([#66](https://github.com/carpet-stain/dotfiles/pull/66))

## [1.2.0] - 2026-07-06

### Chore

- *(ci)* Path-filtered linting, dependabot submodules, zellij ci guard ([#64](https://github.com/carpet-stain/dotfiles/pull/64))

## [1.1.0] - 2026-07-06

### Features

- *(nvim)* Wire up Python/Go/Bash LSP tooling, track lazy-lock.json ([#62](https://github.com/carpet-stain/dotfiles/pull/62))

### Chore

- Update repo-watch state ([#61](https://github.com/carpet-stain/dotfiles/pull/61))

## [1.0.0] - 2026-07-06

### Features

- Add Zellij alongside tmux ([#47](https://github.com/carpet-stain/dotfiles/pull/47))
- *(zellij)* Show contextual keybind hints in the status bar ([#49](https://github.com/carpet-stain/dotfiles/pull/49))
- *(zsh)* Auto-start zellij instead of tmux ([#53](https://github.com/carpet-stain/dotfiles/pull/53))
- *(zellij)* [**breaking**] Complete migration from tmux to zellij ([#54](https://github.com/carpet-stain/dotfiles/pull/54))
- *(zellij)* Mode-aware status bar, tab badges, default session name ([#55](https://github.com/carpet-stain/dotfiles/pull/55))

### Bug Fixes

- *(macos)* Pre-grant zjstatus-hints permissions ([#50](https://github.com/carpet-stain/dotfiles/pull/50))
- *(zellij)* Pin zjstatus, quote its booleans, pre-grant permissions ([#51](https://github.com/carpet-stain/dotfiles/pull/51))
- *(zsh)* Fzf ctrl-e leak, PATH glob safety, small alias cleanup ([#56](https://github.com/carpet-stain/dotfiles/pull/56))

### Revert

- *(zellij)* Remove zjstatus-hints ([#52](https://github.com/carpet-stain/dotfiles/pull/52))

### Chore

- *(zsh)* Disable tmux auto-start for zellij testing ([#48](https://github.com/carpet-stain/dotfiles/pull/48))

## [0.3.1] - 2026-07-05

### Features

- *(theme)* Add catppuccin/eza, document ls_colors regeneration ([#43](https://github.com/carpet-stain/dotfiles/pull/43))

### Bug Fixes

- *(zsh)* Remove dead HISTTIMEFORMAT setting ([#45](https://github.com/carpet-stain/dotfiles/pull/45))

### Refactor

- *(zsh)* Remove cursor-shape widgets ([#44](https://github.com/carpet-stain/dotfiles/pull/44))

## [0.3.0] - 2026-07-05

### Features

- *(zsh)* Generate dua/doggo completions on deploy ([#35](https://github.com/carpet-stain/dotfiles/pull/35))
- *(macos)* Add hyperfine and jaq ([#39](https://github.com/carpet-stain/dotfiles/pull/39))

### Bug Fixes

- *(macos)* Disable ghostty auto palette generation
- *(macos)* Update stale curlrc user-agent ([#38](https://github.com/carpet-stain/dotfiles/pull/38))
- *(macos)* Make deploy.zsh idempotent and fix install_brewfile ([#40](https://github.com/carpet-stain/dotfiles/pull/40))

### Documentation

- *(zsh)* Document zsh-autopair rationale ([#37](https://github.com/carpet-stain/dotfiles/pull/37))

### Performance

- *(zsh)* Stop re-running fast-theme every shell startup ([#33](https://github.com/carpet-stain/dotfiles/pull/33))
- *(zsh)* Defer forgit and fzf-tab-source loading ([#36](https://github.com/carpet-stain/dotfiles/pull/36))

### Styling

- *(zsh)* Trim over-explained comments in widgets.zsh ([#34](https://github.com/carpet-stain/dotfiles/pull/34))

### Chore

- Seed repo-watch state after manual preview run ([#29](https://github.com/carpet-stain/dotfiles/pull/29))
- *(macos)* Reconcile Brewfile with actual installed casks ([#30](https://github.com/carpet-stain/dotfiles/pull/30))
- *(git)* Add submodule diff and rebase/branch settings ([#31](https://github.com/carpet-stain/dotfiles/pull/31))
- *(macos)* Track claude-code, mullvad-vpn; drop proton-mail-bridge ([#32](https://github.com/carpet-stain/dotfiles/pull/32))

## [0.2.0] - 2026-07-05

### Documentation

- *(git)* Refine workflow policy
- *(git)* Drop AI attribution from commit policy

### Build

- Add git-cliff for changelog generation

### CI

- Add zsh syntax-check workflow

### Chore

- *(git)* Use carpet-stain commit identity

## [0.1.1] - 2026-07-05

### Bug Fixes

- *(zsh)* Restore _sesh-sessions fpath function
- *(macos)* Use correct Ghostty theme name
- *(macos)* Install ghostty terminfo on deploy

### Styling

- *(macos)* Drop alacritty references from ghostty config

## [0.1.0] - 2026-07-05

### Features

- *(macos)* Migrate Alacritty to Ghostty

