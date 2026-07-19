# 30. Redefine dev tier as the CI/lint/release toolchain only

Date: 2026-07-19

## Status

Accepted

Supercedes [6. Three-tier deploy model (payload / dev-tooling / repo-meta); Linux excludes dev tooling](0006-three-tier-deploy-model-payload-dev-tooling-repo-meta-linux-excludes-dev-tooling.md)

## Context

ADR-0006's Decision classified `golang-go`/`gh`/`nodejs` as dev-tooling,
excluded from Linux — reasoning that "a disposable VM SSH'd into for editing
doesn't need the Go toolchain, GitHub CLI, or Node-for-LSPs." #127's
follow-on migration epic (#361) executed that classification directly: #362
(open PR #372) removes `golang-go`/`golang-src`/`gh`/`nodejs`/`python3`/
`python3-pip` from `linux/deploy.sh`/`linux/Aptfile`; #363 (open PR #371)
gates Neovim's Mason-managed LSP installs (`pyright`, `gopls`, etc.) to
macOS-only, reasoning that once piece 1 lands, nothing on Linux consumes
those runtimes anyway.

That reasoning assumed the Linux target's only job is editing/developing
_this_ dotfiles repo. It isn't — a Linux dev box (the disposable OrbStack VM,
or a remote work box per the README) is also used for general development
work in other languages and other repos, which genuinely needs a Go
toolchain, a Node runtime, `gh` for interacting with those other repos'
PRs/issues, and Python. Only the toolchain that exists specifically to
develop _this_ repo (`act`, `actionlint`, `adr-tools`, `colima`, `docker`,
`git-cliff`, `lefthook`, `markdownlint-cli2`, `prettier`, `selene`,
`shellcheck`, `shfmt`, `stylua`, `taplo`, `tenv`, `trivy`, `yamlfmt`, `just`,
`uv`) has no reason to exist on a general-purpose Linux dev box — that part
of ADR-0006's Decision was correct and is unaffected.

## Decision

Redefine the dev-tooling tier to mean _only_ the CI/lint/release toolchain
used to develop this repo, not general-purpose language runtimes. `go`,
`gh`, and a Node runtime (`fnm`-managed on macOS, apt `nodejs` on Linux)
move to the payload tier — deployed on both platforms, like any other user
CLI tool. Python already has a native Linux equivalent (apt `python3`/
`python3-pip`); that stays as-is. ADR-0029's uv-only swap is macOS-specific
(its own separate decision about how _macOS_ manages Python versions) and is
unaffected by this — Linux was never going through uv for Python and still
isn't.

`go`, `gh`, and `fnm` move from `macos/Brewfile.dev` to `macos/Brewfile.payload`
(#364; the payload/dev/personal file split itself is also #364 — see that
issue's PR for why file-per-tier replaced an earlier `# tier:` comment
convention). `linux/deploy.sh`/`linux/Aptfile` keep installing `golang-go`/
`golang-src`/`gh`/`nodejs`/`python3`/`python3-pip` — #362 (issue) is
obsoleted by this decision, not executed; its open PR (#372) removes exactly
the packages this ADR says to keep, and should be closed or reworked rather
than merged as originally scoped.

## Alternatives considered

- **Keep ADR-0006's original classification** (`golang-go`/`gh`/`nodejs`
  dev-tier, excluded from Linux) — rejected: doesn't match actual usage: a
  Linux dev box does general development work, not just this repo's own
  editing.
- **Collapse the tier split entirely** (move every current dev-tier tool to
  payload) — rejected, overcorrects: `act`/`shellcheck`/`lefthook`/etc. still
  have zero use case on a box that isn't developing this specific repo. The
  three-tier model itself isn't wrong, only which bucket `go`/`gh`/`node`
  belonged in.
- **A fourth tier for "general language runtimes"** distinct from payload
  and dev-tooling — rejected as unnecessary complexity; the existing
  payload/dev-tooling split already has room for this once the dev-tooling
  definition is corrected to mean "specific to developing this repo."

## Consequences

`golang-go`/`golang-src`/`gh`/`nodejs`/`python3`/`python3-pip` stay on
Linux's `install_apt_packages`/`Aptfile`, unremoved — #362 (issue) should be
closed or re-scoped; its PR #372 shouldn't merge as originally written.

Issue #363's open PR (#371) reasoned "nothing on Linux consumes go/node once
[golang-go/nodejs are] removed" — that premise no longer holds, since this
decision keeps them. Resolved (not just flagged): #371 replaces its
macOS-only OS gate with a per-tool `vim.fn.executable()` check — Mason
manages a dev-LSP tool (`gopls`, `pyright`, `lua_ls`, etc.) only when the
binary isn't already resolvable on `$PATH`, on either platform, so a
gated Mason stack and present language runtimes coexist rather than being
mutually exclusive.

That check needs the tools to actually _be_ on `$PATH` for it to matter, so
this ADR's payload set grew beyond the original `go`/`gh`/`fnm`: the LSP
servers, linters, formatters, and debuggers those languages' Neovim configs
call for (`gopls`, `goimports`, `gofumpt`, `golangci-lint`, `gomodifytags`,
`delve`; `pyright`, `ruff`; `lua-language-server`, `selene`, `stylua`;
`bash-language-server`) are payload too — "look at what nvim already
configures for a language and install that directly," not just the bare
runtime. `macos/Brewfile.payload` covers all of these via Homebrew except `impl`
(Go interface-stub generator, no formula) and provisions it via a pinned
`go install` instead — still reproducible, since Go's module proxy/sumdb
checksum-verify the fetch the same way binaries.lock's sha256 pins do for a
raw download. Linux has no apt package for any of these; each goes through
whichever of `linux/binaries.lock` (GitHub-release binaries: `golangci-lint`,
`lua-language-server`, `ruff`, `stylua`, `selene` — x86_64 only, repo-wide:
that's the actual Linux target, an aarch64 OrbStack VM is a convenience, and
`selene` doesn't publish an aarch64 build at all so the two-arch pin the
lock used to carry for every tool wasn't buying anything real), pinned
`go install` (`gopls`, `goimports`,
`gofumpt`, `gomodifytags`, `impl`, `delve` — none of these publish release
binaries), or pinned `npm install -g` (`pyright`, `bash-language-server` —
npm-only, no release binaries either) actually fits.

Issue #364's leak-guard mechanism (`scripts/check-brewfile-tiers.sh`, failing
if a tool is declared in more than one `macos/Brewfile.{payload,dev,personal}`
or a `Brewfile.dev`/`Brewfile.personal` tool leaks onto Linux) is unaffected
in design — only its dev-tier tool list and apt-alias map shrink now that
`go`/`gh`/`fnm` are out of it. The mechanism itself changed shape mid-#364:
file placement now _is_ the classification, replacing an earlier `# tier:
payload`/`# tier: dev` comment convention on a single `macos/Brewfile` — more
idiomatic `brew bundle --file=` usage, and it drops the need to parse tags at
all.
