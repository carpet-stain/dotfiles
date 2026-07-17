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

Baseline is [**Effective Go**](https://go.dev/doc/effective_go), still canonical for core idiom but
frozen by its own disclaimer (written for the 2009 release; no generics, modules, or newer
libraries) — so treat it as baseline, not the whole story. Idiom essentials: gofmt formatting;
short lower-case single-word package names; `MixedCaps`/`mixedCaps` for multiword names; getters
without a `Get` prefix; `-er` names for one-method interfaces; short receiver names; early-return
flow that omits the needless `else`; error strings that identify their origin (lower-case, no
trailing punctuation); always check returned errors (never `_`-discard a failure); doc comments on
exported identifiers. Supplement Effective Go with the active layer that postdates it: the Go team's
[Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) (self-described supplement), the
[Google Go Style Guide](https://google.github.io/styleguide/go/) (clarity > simplicity > concision >
maintainability > consistency, in that order — Google-scoped, adopt pragmatically), and the values
layer, Dave Cheney's [Zen of Go](https://dave.cheney.net/2020/02/23/the-zen-of-go) and Rob Pike's
[Go Proverbs](https://go-proverbs.github.io/).

Design stance: **accept interfaces, return structs** — interfaces belong in the package that
_consumes_ them (defined where used, not where implemented), implementations return concrete types,
and defining an interface on the implementor side "for mocking" is an anti-pattern (test through the
real implementation's public API). Generics follow "write code, not types": reach for a type
parameter only when you're about to duplicate code that differs solely by type; if you only call a
method, use an interface, not a type parameter. Context is passed explicitly as the first parameter,
never stored in a struct field. Errors are values, handled explicitly at the point of failure: wrap
with `%w`, inspect with `errors.Is`/`errors.As`/`errors.Join`; packages return root error values
and wrapping is an application-level policy, not a library one.

Make the mechanizable parts tooling-enforced: `gofmt`/`gofumpt` + `goimports` for
formatting/imports, `golangci-lint` (v2: `linters` and `formatters` are separate config sections;
the `staticcheck` linter now subsumes gosimple + stylecheck) for lintable rules — staticcheck,
errcheck, errorlint, revive for naming/indent-error-flow and initialism casing, exported-identifier
doc comments. Pin dev tools with the go.mod `tool` directive (`go get -tool` / `go tool`, Go 1.24+),
not a `tools.go` hack. Run `govulncheck` in CI — its reachability analysis flags only vulnerabilities
on live call paths, the Go-concrete realization of engineering-practices.md's Security By Default.
Test table-driven with `testdata`/txtar cases before reaching for testify; `testing/synctest`
(stable in 1.25) for deterministic concurrency tests. Judgment parts — package purpose, comment
quality, interface design — stay a matter of review.

Give every package a `doc.go` overview (what it owns, primary invariants, start-here files);
co-locate a `README.md` for a deeper guide and point `doc.go` at it — design-principles.md's Naming
& Files rule (no dumping-ground files) applies here too. For relational navigation — callers of a
symbol, implementers of an interface, rename safety — prefer gopls over grep; grep is for
text/config/log scans.

## Dependency posture — Go is stdlib-first

The mirror image of Python's reach-for-a-library default: in Go the standard library _is_ the
default, and "a little copying is better than a little dependency" (Proverb) is real guidance, not
asceticism. Reach for the stdlib where the ecosystem once reached for a package: `log/slog` for
structured logging (Go 1.21 — the default for new code, not a reason to rip out zap), `net/http`
routing (method+wildcard patterns, Go 1.22), `errors.Join` over a wrapping library, `testing`
table-driven over a framework. Add a dependency when it earns its keep — a hard problem (a database
driver, a TUI runtime), a genuine boundary — not to avoid boilerplate you could copy in ten lines.
Same standing filter as Python from the other side: prefer the boring, well-owned choice, keep the
skepticism for speculative or single-maintainer deps — Simplicity First cuts both ways.

## Application structure (layered apps)

Go-concrete realization of `architecture.md`'s layer-boundary principles, scoped to the
services/CLIs its GATE covers — worked exemplar: Ben Johnson's WTF Dial
(`github.com/benbjohnson/wtf`, gobeyond.dev's "Standard Package Layout" / "Packages as layers, not
groups" / "Failure Is Your Domain"). Start flat and grow into it: the official
[layout guidance](https://go.dev/doc/modules/layout) is `go.mod` + files in the root, splitting into
packages only when size warrants — a directory _is_ a package, so don't add one just to sort files,
and big packages/files aren't anti-patterns. Don't cargo-cult `golang-standards/project-layout`
(`pkg/`, `api/`, ...) — Russ Cox has disavowed it as non-standard. Skip the ceremony entirely for a
small CLI with no real dependency boundary (design-principles.md: no abstraction without a real
boundary).

- **Root package is the domain**, importing nothing implementation-specific: types plus service
  interfaces (`wtf.DialService`) defined where they're consumed, not where they're implemented —
  Go's shape for Compose at the edge.
- **Subpackages wrap one external dependency each**, not a technical layer — `http/`, `sqlite/`,
  `mock/`, never `models/`/`controllers/`/`services/`. They import the domain package, never each
  other — Go's shape for Organize by dependency, not technical layer; the domain-over-layer split
  everyone now converges on (`internal/user`, not `internal/handlers`). Push supporting packages
  into `internal/` (compiler-enforced privacy) so their APIs stay refactorable; a server's logic
  belongs there, since a server exports nothing.
- **`cmd/<bin>/main.go` is the composition root**: a thin `main()` traps signals/exit; a `Main`
  struct wires concrete implementations (e.g. `sqlite` + `http`) into the domain interfaces —
  runtime selection at the top, per Compose at the edge, manual wiring over a DI framework. Separate
  binaries (`cmd/wtfd`, `cmd/wtf`) wire different subsets of the same domain; `mock/` wires a fake
  subset for tests.
- **Domain error type**: `Error{Code, Message}` with a sentinel `Code` set (`ENOTFOUND`,
  `ECONFLICT`, `EINVALID`, `EINTERNAL`, ...) and `ErrorCode(err)`/`ErrorMessage(err)` helpers that
  unwrap wrapped errors, falling back to `EINTERNAL`/a generic message outside the domain — a
  transport layer translates `Code` to its own status, keeping that translation at the boundary
  per Backend quirks stay at the boundary. Extends this file's error-checking guidance with error
  _design_.

To _read_ for idiomatic Go: the standard library first (net/http, net, crypto/subtle — nothing
there by accident), then BoltDB, groupcache/singleflight, Caddy, go-kit, and WTF Dial itself. Study
Kubernetes for scale, but the community consensus is not to emulate its style (over-abstraction, a
`utils` package, import renaming) — calibrate "idiomatic" against the stdlib, not the big names.
