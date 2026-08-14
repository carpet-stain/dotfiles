# 44. Blocking two-line signpost cap for code comments

Date: 2026-08-14

## Status

Accepted

Supercedes [31. Length-based advisory lint for comment concision](0031-length-based-advisory-lint-for-comment-concision.md)

## Context

ADR-0031 built `check-comment-concision.sh` as an advisory outlier detector: threshold 20 lines,
calibrated against this repo's own densest legitimate block, never a non-zero exit. It was
deliberately a nudge — a hard block on something that judgment-dependent invited `--no-verify`.

Epic #530 changes what the rule is, which is what forces a new decision rather than a retune. The
rule is no longer "this block is an outlier, re-read it" but "a comment on one declaration is a
≤2-line signpost — the tripwire plus a pointer — and the durable why lives in an ADR or issue."
That is an absolute discipline, and an advisory nudge calibrated to a repo's existing style cannot
express it: at 20 lines it stays silent on exactly the 3-to-15-line restatements the rule targets.

The rule also wasn't stated quantitatively anywhere. `design-principles.md` said "explain why not
what, point elsewhere" and named no limit, so neither a human nor an agent could tell whether a
given block complied.

The collision this has to resolve, surfaced in infra#163's review: `design-principles.md` also says
a load-bearing tripwire stays inline. A cap that reads as "delete anything over two lines" would
force the removal of warnings the repo deliberately keeps.

## Decision

The cap is **2 lines, enforced by a non-zero exit**.

- `THRESHOLD_LINES=2` is the **maximum allowed**, so the comparison is `count > threshold`. The
  reference lint used `>=`, which flags a 2-line block and reads off-by-one against "≤2 allowed."
  The config number now matches the rule's number everywhere.
- **Non-zero exit on any violation.** The script accumulates status across files, so it reports
  every offending block rather than stopping at the first.
- **File-header preambles stay exempt** (a block starting at line 1, or line 2 after a shebang) —
  standalone file documentation, not a per-declaration comment. Unchanged from ADR-0031.
- **The comment-prefix map extends past `#` and Lua's `--`** to the languages the repos that mirror
  this script actually use: Python and Terraform (`#`), and JS (`//`). Prefix coverage is what makes
  the script portable; which files it runs on stays each repo's `lefthook.yml` glob.
- **No escape hatch.** No pragma, no per-file opt-out, no per-repo threshold. Relocate-or-point is
  the pressure release: if the content is worth keeping, it has a durable home, and the comment
  keeps a pointer to it.

**The boundary clause**, which resolves the tripwire collision and is stated identically in
`design-principles.md`: the inline tripwire is the terse actionable warning — what breaks plus the
revisit condition — kept within the ≤2-line cap. Where its supporting rationale or evidence won't
fit, that relocates to the pointer's target and the inline keeps only the warning plus the pointer.
When a block mixes restatement and tripwire, the tripwire wins and the block stays.

**Rollout is per-repo and separate from this mechanism.** This ADR lands the script and the stated
rule. Each repo sweeps its own comments and then flips its own wiring — dotfiles' own sweep is #532,
and until it lands the `comment-concision` job here stays advisory (`|| true` in `lefthook.yml`,
which #532 deletes). Landing the blocking script and the repo's sweep in one change would fail CI
on 191 pre-existing blocks.

## Alternatives considered

- **Keep it advisory, just lower the threshold** — preserves ADR-0031's `--no-verify` argument and
  needs no sweep. Rejected: the epic's rule is an absolute cap, and an advisory cap that everyone
  scrolls past is the state that let the restatements accumulate in the first place. The
  `--no-verify` risk is real and answered by the sweep, not by staying quiet.
- **Per-repo threshold calibration** (ADR-0031's own instruction to mirroring repos) — right for an
  outlier detector, wrong for a discipline. A cap calibrated to each repo's existing style
  ratifies whatever that style already is; 2 is the same number everywhere because the rule is the
  same everywhere.
- **An opt-out pragma** (`# concision: allow`) for genuinely long blocks — rejected as the escape
  hatch that makes the cap advisory again by another name. The boundary clause covers the case it
  would be used for: keep the tripwire, relocate the evidence.
- **Auto-fixing** — rejected: deciding what relocates and where it goes is judgment, and a tool that
  silently truncated a comment would destroy the intent this rule exists to preserve.
- **Extending the lefthook globs to the new languages here** — out of scope by the epic's own split
  (`#531`'s acceptance): the prefix map is the portable capability, and what each repo lints is that
  repo's flip decision.

## Consequences

The rule is stated once with a number and enforced mechanically, so "is this comment compliant?"
has a mechanical answer for the first time — the config-is-code shape the repo already applies to
every other lint.

The cost is a sweep per repo before the flip: dotfiles has 191 over-cap blocks today, and the
mirroring repos (infra, project-starter-template) carry their own. Until each flip lands, the
enforcement is real in the script and inert in that repo's wiring, which is a state worth reading
carefully — a green pre-commit here does not yet mean the repo is clean.

ADR-0031's finding stands and is not re-litigated: length is not a redundancy detector. This cap
does not claim to catch a short restatement that was already documented elsewhere; it makes the
long ones impossible and leaves the short ones to review.

Revisit if the sweep turns up a class of comment the boundary clause can't place — that would mean
the tripwire/evidence line is drawn wrong, not that the cap needs a hatch — or if a mirroring repo's
language makes a 2-line cap structurally unworkable rather than merely uncomfortable.

**Amendment, 2026-08-14 (scope clause; extends this model, not superseding it — ADR-0025's
precedent for a same-ADR correction):** two corrections to what the cap governs, both forced by the
sweep in #532.

**One — ASCII section banners are out of scope, alongside file headers.** 58 of the 188 blocks
flagged at the start of the sweep (the 191 above, less three already fixed) were the `# +------+`
section headers AGENTS.md mandates:

```text
# +--------+
# | ZELLIJ |
# +--------+
```

Three comment lines above a declaration, so the cap flagged every one, and the "relocate the why"
remedy is meaningless for them: a banner is a structural separator that carries no rationale to
move. The only way to comply was to destroy a convention the repo requires elsewhere.

A block is a banner when every one of its lines, with the comment prefix stripped, is either a rule
(`+---+`) or a bare title (`| NAME |`). A block mixing banner lines with prose is not exempt — the
prose is a real comment and the cap applies to the whole block. This is a scope definition, not the
escape hatch the Decision refuses: the cap governs explanatory comments on a declaration, and a
banner was never one.

**Two — the file-header exemption widens** from the Decision's "block starting at line 1, or line 2
after a shebang" to "the first comment block, with nothing above it but a shebang or blank lines."
The original wording was drawn one line short of this repo's own style: every `zsh/**` file writes
shebang, blank, header, putting the header at line 3 and making it structurally unexemptable. The
narrow rule would have forced a real header trim in four files before the sweep caught it.

The same gap likely exists for interface documentation — a godoc comment or a params/returns
docstring is a consumption contract, not an explanatory comment, and `documentation.md` and
`tools/go.md` both require it at lengths the cap forbids. Left open here rather than assumed;
it needs the same scope treatment before a repo with Go or Python adopts the flip.
