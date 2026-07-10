<!-- LAYER 1 — Go idioms. Canonical source: my dotfiles.
     Language-level only: never any repo path, service name, or branch name here. -->

> ### APPLY GUARD
> APPLY ONLY IF this repo is a Go project — a go.mod exists at the repo root.
> If there is no go.mod, IGNORE this entire file; it is not relevant.
> If this repo already has its own Go standards doc (e.g. docs/CODING.md), that doc is
> AUTHORITATIVE: treat this layer as baseline only and prefer the repo's doc on conflict.

> ### COMPOSE PROTOCOL (how to give a repo its own concrete Go doc)
> Trigger: only when the human asks to scaffold/adopt conventions, OR a Go repo has no
> Go standards doc and one is warranted. Default to PROPOSE, don't create — suggest the
> doc and wait for approval before writing committed files.
> Steps:
>   1. Read this layer once as the baseline.
>   2. Write a repo-local doc (e.g. docs/CODING.md) that RESTATES these principles with
>      the repo's CONCRETE nouns: its actual linters + config file, its module layout,
>      its pinned tool versions, its file-naming in practice. Keep the principle, replace
>      the abstraction with the specific.
>   3. Wire the gate so local wins: add to the repo's committed AGENTS.md:
>        "docs/CODING.md is authoritative for Go specifics; treat any generic Go layer
>         as baseline and prefer this repo's doc on conflict."
>      (This line names NO personal path — commit-safe, true for any contributor.)
>   4. After this, the repo reads its own doc; do not re-distill this layer for that repo.

# Go Conventions

Baseline is **Effective Go** (https://go.dev/doc/effective_go): gofmt formatting (tabs, no manual
alignment); short lower-case single-word package names (no under_scores, no mixedCaps);
`MixedCaps`/`mixedCaps` for multiword names; getters without a `Get` prefix; `-er` names for
one-method interfaces; short receiver names; early-return control flow that omits the unnecessary
`else`; error strings that identify their origin (lower-case, no trailing punctuation); always
checking returned errors (never discarding a failure with `_`); doc comments on exported
identifiers; idiomatic interfaces, slices/maps, `defer`, and the comma-ok idiom.

Effective Go predates generics and modules — treat it as the idiom baseline and complement it with
modern Go: generics where they clarify, `errors.Is`/`errors.As`, the `slices`/`maps` stdlib, and
module-aware layout. All consistent with its spirit.

Make the mechanizable parts tooling-enforced rather than left to convention:
`gofmt`/`gofumpt` and `goimports` for formatting/imports, and `golangci-lint` for the lintable rules
(staticcheck including error-string style, errcheck for unchecked errors, errorlint, revive for
naming/indent-error-flow and initialism casing, package doc comments, and a meaningful doc comment on
every exported identifier). Judgment parts — package purpose, comment quality, interface design —
stay a matter of review.

File naming: keep files topical (`inventory.go`, `errors.go`, `logging.go`), avoid dumping-ground
names (`utils.go`, `helpers.go`, `misc.go`, `common.go`).

Package docs: give every package a `doc.go` with a concise overview (what it owns, primary
invariants, start-here files) that surfaces in `go doc` and IDE hovers. When a package needs a deeper
guide, put a co-located `README.md` next to the code and have `doc.go` point to it.

For relational code navigation — who calls this exact symbol, what implements this interface, is a
rename safe — prefer a language-server-backed tool (gopls) over grep; grep matches text and yields
false positives on symbol queries. Keep grep for fast text/config/log scans.
