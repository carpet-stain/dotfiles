---
paths:
  - "pyproject.toml"
  - "**/*.py"
---

<!-- Python idioms. Canonical source: my dotfiles. Language-level only — never a repo path,
     service name, or branch name. The paths: frontmatter is the gate: Claude Code loads this
     only when a pyproject.toml/*.py file is read, structurally, no prose guard needed.
     Rationale: claude/README.md. -->

> ### GATE
>
> The `paths:` frontmatter is the gate — this file loads only when Claude reads a Python file
> (`pyproject.toml`/`*.py`), in any repo. No prose guard needed.

> ### LOCAL-WINS
>
> If this repo has its own Python standards doc (e.g. docs/CODING.md), that doc is AUTHORITATIVE:
> treat this as baseline and prefer the repo's doc on conflict.

> ### COMPOSE — give a repo its own concrete Python doc
>
> Trigger: the human asks to scaffold, OR a Python repo lacks a standards doc and one is
> warranted. PROPOSE, don't create. Steps: (1) read this as baseline; (2) write a repo-local doc
> (e.g. docs/CODING.md) restating these with the repo's concrete nouns — its linter/type-checker
> config, package layout, pinned tool versions, framework stance; (3) add to the repo's AGENTS.md
> that docs/CODING.md is authoritative over generic Python conventions (name no personal path);
> (4) after this the repo reads its own doc — don't re-distill.

# Python Conventions

Baseline is [**Effective Python**, 3rd ed.](https://effectivepython.com/) (Slatkin) for idiom,
with PEP 8 as surface style — enforced by tooling, not litigated in review (PEP 8 itself cedes to
project guides; don't cite it beyond what ruff enforces). Idiom essentials: `snake_case`
functions/variables, `PascalCase` classes, `UPPER_CASE` constants, one leading underscore for
internal names; early-return flow; f-strings; `pathlib` over `os.path`; `enum` over loose
string/int constants; comprehensions where they clarify, loops where they don't; speak the data
model (`__iter__`, `__enter__`, ...) instead of inventing bespoke method names; docstrings on
public API. Type hints throughout, checked strictly — they are contracts, not decoration.

Design stance (Hynek Schlawack's subclassing essays/PyCon talks are the canonical source):
composition over inheritance for code sharing; `typing.Protocol` over ABCs for interfaces —
structural, so implementations need not know the interface exists, and defined where consumed,
exactly like a Go interface. Subclass only where Go would embed: pure specialization that adds
behavior without modifying the parent's. Exceptions are the error channel — design a small domain
exception hierarchy and translate it at the boundary; don't import result-type ceremony.

Make the mechanizable parts tooling-enforced: uv for env/packaging/lock (pyproject.toml is the
one config home, `[dependency-groups]` for dev deps), ruff for lint+format, a strict type checker
(pyright today; the Rust checkers ty/pyrefly are still settling), pytest (plus hypothesis where
properties beat examples). `src/` layout, so tests import the installed package, not the working
copy. Judgment parts — API design, naming, docstring quality — stay a matter of review.

## Dependency posture — Python is not stdlib-maximalist

Go's stdlib-first instinct doesn't transfer. Idiomatic Python reaches for the community-standard
library where the stdlib equivalent is a known boilerplate pit: httpx/requests over urllib,
pytest over unittest, click/typer over argparse for real CLIs, structlog over logging plumbing,
attrs where dataclasses run out. Hand-rolling those to "avoid a dependency" reads as unidiomatic,
not disciplined. The filter is standing, not novelty: prefer the boring, widely adopted choice,
and keep the usual skepticism for single-maintainer micro-deps and frameworks for one call site —
Simplicity First still applies; liberal is not indiscriminate.

## Application structure (layered apps)

Python-concrete realization of `architecture.md`'s layer-boundary principles — reference text:
[Architecture Patterns with Python](https://www.cosmicpython.com/) (Percival & Gregory), read
WITH its own caveats: the authors document ("So Many Layers!") that the full stack — repository,
unit of work, message bus, CQRS — is overkill for most apps. Apply per module where domain logic
is real; a CRUD module stays plain. Opinionated frameworks invert this: inside Django, work
framework-native — fat models as the internal API, `transaction.atomic` as the unit of work —
rather than wrapping the ORM in repositories you then maintain forever (James Bennett's "against
service layers").

- **Domain modules hold plain classes** — dataclasses/attrs with behavior, importing nothing
  transport- or IO-specific. Pydantic belongs at untrusted-data edges (request bodies, config),
  never as the domain model — validation is a boundary concern.
- **One thin facade module per external dependency**, owned by you, wrapping its client library —
  the same move as Go's one-package-per-dependency, and the precondition for "don't mock what
  you don't own": tests fake your facade, never the third-party API.
- **Interfaces live with their consumers** as `Protocol`s; concrete adapters import the domain,
  never each other.
- **A composition root wires it**: an app factory / `main()` / `bootstrap.py` passing
  dependencies as plain constructor/function arguments. No DI framework, no globals discovered
  at depth.
- **Domain exceptions translate at the boundary**: transport code maps the domain hierarchy to
  status/exit codes; deeper layers raise domain errors and never speak HTTP.
