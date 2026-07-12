---
paths:
  - "go.mod"
  - "**/*.go"
---

<!-- Go idioms. Canonical source: my dotfiles. Language-level only — never a repo path,
     service name, or branch name. The paths: frontmatter is the gate: Claude Code loads this
     only when a go.mod/*.go file is read, structurally, no prose guard needed.
     Rationale: claude/README.md. -->

> ### GATE
>
> The `paths:` frontmatter is the gate — this file loads only when Claude reads a Go file
> (`go.mod`/`*.go`), in any repo. No prose guard needed.

> ### LOCAL-WINS
>
> If this repo has its own Go standards doc (e.g. docs/CODING.md), that doc is AUTHORITATIVE:
> treat this as baseline and prefer the repo's doc on conflict.

> ### COMPOSE — give a repo its own concrete Go doc
>
> Trigger: the human asks to scaffold, OR a Go repo lacks a standards doc and one is warranted.
> PROPOSE, don't create. Steps: (1) read this as baseline; (2) write a repo-local doc (e.g.
> docs/CODING.md) restating these with the repo's concrete nouns — its linters + config file,
> module layout, pinned tool versions, file-naming; (3) add to the repo's AGENTS.md that
> docs/CODING.md is authoritative over generic Go conventions (name no personal path); (4) after
> this the repo reads its own doc — don't re-distill.

# Go Conventions

Baseline is [**Effective Go**](https://go.dev/doc/effective_go): gofmt formatting; short lower-case
single-word package names; `MixedCaps`/`mixedCaps` for multiword names; getters without a `Get`
prefix; `-er` names for one-method interfaces; short receiver names; early-return flow that omits
the needless `else`; error strings that identify their origin (lower-case, no trailing
punctuation); always check returned errors (never `_`-discard a failure); doc comments on exported
identifiers. Complement it with modern Go it predates: generics where they clarify,
`errors.Is`/`errors.As`, the `slices`/`maps` stdlib, module-aware layout.

Make the mechanizable parts tooling-enforced: `gofmt`/`gofumpt` + `goimports` for
formatting/imports, `golangci-lint` for lintable rules (staticcheck, errcheck, errorlint, revive
for naming/indent-error-flow and initialism casing, exported-identifier doc comments). Judgment
parts — package purpose, comment quality, interface design — stay a matter of review.

Give every package a `doc.go` overview (what it owns, primary invariants, start-here files);
co-locate a `README.md` for a deeper guide and point `doc.go` at it — design-principles.md's Naming
& Files rule (no dumping-ground files) applies here too. For relational navigation — callers of a
symbol, implementers of an interface, rename safety — prefer gopls over grep; grep is for
text/config/log scans.

## Application structure (layered apps)

Go-concrete realization of `architecture.md`'s layer-boundary principles, scoped to the
services/CLIs its GATE covers — worked exemplar: Ben Johnson's WTF Dial
(`github.com/benbjohnson/wtf`, gobeyond.dev's "Standard Package Layout" / "Packages as layers, not
groups" / "Failure Is Your Domain"). Skip the ceremony for a small CLI with no real dependency
boundary (design-principles.md: no abstraction without a real boundary).

- **Root package is the domain**, importing nothing implementation-specific: types plus service
  interfaces (`wtf.DialService`) defined where they're consumed, not where they're implemented —
  Go's shape for Compose at the edge.
- **Subpackages wrap one external dependency each**, not a technical layer — `http/`, `sqlite/`,
  `mock/`, never `models/`/`controllers/`/`services/`. They import the domain package, never each
  other — Go's shape for Organize by dependency, not technical layer.
- **`cmd/<bin>/main.go` is the composition root**: a thin `main()` traps signals/exit; a `Main`
  struct wires concrete implementations (e.g. `sqlite` + `http`) into the domain interfaces —
  runtime selection at the top, per Compose at the edge. Separate binaries (`cmd/wtfd`, `cmd/wtf`)
  wire different subsets of the same domain; `mock/` wires a fake subset for tests.
- **Domain error type**: `Error{Code, Message}` with a sentinel `Code` set (`ENOTFOUND`,
  `ECONFLICT`, `EINVALID`, `EINTERNAL`, ...) and `ErrorCode(err)`/`ErrorMessage(err)` helpers that
  unwrap wrapped errors, falling back to `EINTERNAL`/a generic message outside the domain — a
  transport layer translates `Code` to its own status, keeping that translation at the boundary
  per Backend quirks stay at the boundary. Extends this file's error-checking guidance with error
  _design_.
