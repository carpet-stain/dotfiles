# 29. Replace Homebrew-managed node and python with fnm and uv-only on macOS

Date: 2026-07-18

## Status

Accepted

## Context

macOS carried Node and Python inconsistently: `uv` (ADR-0014) is already the
dogfooded, deterministic way this repo does Python — Homebrew installs the
`uv` manager, `uv` itself owns the interpreter. `node`/`python` sat alongside
it as plain Homebrew formulas with no version-pin story, `python` for a bare
`python3` nothing in this repo actually consumes (no `python3_host` in nvim,
no shebang uses it, Mason's `ruff` installs as a standalone binary), `node`
solely to feed Mason's npm-installed LSP tools (`pyright`, `json-lsp`,
`yaml-language-server`, `markdown-toc` — `macos/Brewfile`'s own comment).

ADR-0006 (Accepted) already classifies both `node-for-LSPs` and `uv` as
dev-tooling, macOS-only, and #127 (open spike) already names
`python3-pip`/`nodejs` as dev-tooling leaks to remove from Linux. This
decision is the first concrete execution of that existing classification for
macOS — not a new or conflicting call — and deliberately doesn't touch
`linux/Aptfile`/`linux/deploy.sh` (#127's scope).

This also cuts against ADR-0002's Homebrew-first stance, which rejected
chezmoi specifically for "adds a templating + manager-owned-state layer."
`fnm` is that shape of tool, and Homebrew already carries `node`, so this
isn't the "brew lacks it → escape hatch" path ADR-0002 already allows for. It
needs to be named as a deliberate, additional carve-out, not glossed over.

Scope note, discovered via `brew uses --installed node` during
implementation: removing the explicit `brew 'node'` line does not remove
Node from the machine. `prettier` and `markdownlint-cli2` (both already in
`macos/Brewfile`, unrelated to this decision) pull it in transitively. The
outcome is asymmetric between the two languages, not full parity — recorded
plainly below rather than claimed away.

## Decision

**Python:** drop `brew 'python'` from `macos/Brewfile`. `uv` becomes the sole
Python interpreter provider on macOS — Homebrew's vendored interpreter (used
internally by Homebrew itself) is unaffected and irrelevant here.

**Node:** add `fnm` (Homebrew-installed, Rust-based, actively maintained) as
the Node version manager. `fnm` provides the Node actually used for
development — `macos/deploy.zsh` installs and activates fnm's pinned Node
(`fnm install --lts && fnm default lts-latest`, `eval "$(fnm env)"`) before
the headless Mason/LSP bootstrap step runs, since that step executes in the
deploy script's own process, not a fresh shell that's sourced `.zshenv`.
`.zshenv` sources fnm's shell integration the same way for ordinary
interactive/script use, placed **after** the existing `opt/*/bin` PATH loop
so fnm's Node wins over Homebrew's should both be present — see "Node's
Homebrew presence" below for why Homebrew's copy isn't actually removed.
`FNM_DIR` is set explicitly to `$XDG_DATA_HOME/fnm` (this repo's strict-XDG
stance) and pre-created in `deploy.zsh`'s directory step, matching every
other XDG-relocated tool.

**The precise symmetry this establishes:** neither language's
_runtime/interpreter_ is Homebrew-owned for development purposes — the
version-manager _tool_ itself may still be Homebrew-installed, exactly the
model `uv` already established for Python (ADR-0014: Homebrew installs the
manager, the manager owns the runtime). `fnm` extends that same model to
Node.

**Node's Homebrew presence, explicitly not eliminated:** a Homebrew-managed
Node still exists on the machine after this change, as an unrelated
transitive dependency of `prettier` and `markdownlint-cli2`. It stays inert
for development purposes as long as fnm's `PATH` entry wins — the `.zshenv`
ordering above is what makes that true, not the absence of Homebrew's copy.
Node's original Brewfile comment recorded a real, separate reason it was
there in the first place — Mason's npm-installed LSPs (`pyright`,
`bash-language-server`) — and that provenance (ADR-0016) is preserved here in
this ADR now that the explicit `brew 'node'` line and its comment are gone:
Node is still needed for Mason's LSP installs; fnm is layered on top for
day-to-day development use.

**This is a deliberate, additional carve-out from ADR-0002's Homebrew-first
stance**, not a general erosion of it — following the precedent ADR-0014
already set for `uv`/Python. The cost: a second provisioning model inside
`deploy.zsh` (an install-and-`eval`-env dance instead of a plain Homebrew
formula), and `fnm`-owned state under `$XDG_DATA_HOME/fnm`.

## Alternatives considered

- **Volta** — the original ask. Rejected: Volta's own README leads with "Volta
  is unmaintained... we recommend migrating to `mise`" (last commit
  2026-05-15), which contradicts this repo's "Modern Replacements" principle
  (modern, maintained alternatives) outright.
- **mise** — a viable, actively-maintained cross-language manager. Rejected in
  favor of staying single-purpose: `mise` would overlap `uv`'s existing job
  for Python rather than complementing it, and this repo prefers one
  single-purpose tool per concern over one tool covering several.
- **`brew 'node@22'` (a pinned Homebrew formula)** — satisfies "a maintained,
  version-pinned Node" without adding a second provisioning model. Rejected:
  it doesn't achieve the actual goal, which is architectural symmetry with
  `uv` (neither language's runtime should be Homebrew-owned for development)
  — a pinned Homebrew formula keeps Node's runtime exactly as Homebrew-owned
  as before, just at a fixed version.
- **A repo-root Node-version-pin file (e.g. `.node-version`)** — considered
  during planning, rejected as scope creep and the wrong mechanism: it only
  governs the repo directory via `--use-on-cd`, not the whole machine, and
  `fnm default <version>` already covers the actual need (a Node present
  regardless of cwd) without a second tracked artifact to maintain.

## Consequences

Python's runtime is now genuinely `uv`-only on macOS — no other Brewfile
formula pulls in a Python interpreter, verified via a Brewfile-wide grep at
implementation time. Node's story is asymmetric and openly so: fnm wins
`PATH` for development, but a Homebrew-managed Node persists underneath as
`prettier`/`markdownlint-cli2`'s dependency — inert as long as the `.zshenv`
PATH ordering holds, and worth re-verifying if either formula is ever
dropped. `deploy.zsh` and `.zshenv` each gained an fnm-specific
install/activate step, mirroring the existing `brew shellenv` pattern rather
than introducing a new one. `FNM_DIR` joins the set of XDG-relocated tool
homes already tracked in `.zshenv`/`deploy.zsh`'s directory-creation step. If
`prettier`/`markdownlint-cli2` are ever removed and nothing else pulls in
Homebrew's Node, the `brew uses --installed node` check in this ADR's Context
should be re-run — Node may then be fully absent from Homebrew, closing the
asymmetry.
