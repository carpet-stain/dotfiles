#!/usr/bin/env bash
# Stamp a sequentially-numbered ADR from docs/adr/templates/template.md — the
# runner-agnostic replacement for adr-tools, which has no Debian package and so
# isn't portable across the machines a bootstrapped repo runs on. Numbers
# auto-increment from the highest existing docs/adr/NNNN-*.md so ADRs are never
# hand-numbered. Run via `just adr "Title"`.
#
# usage: scripts/new-adr.sh "Short decision title"
set -euo pipefail

ADR_DIR="docs/adr"
TEMPLATE="$ADR_DIR/templates/template.md"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 \"Short decision title\"" >&2
  exit 1
fi
TITLE="$*"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "error: ADR template not found at $TEMPLATE" >&2
  exit 1
fi

# Highest existing NNNN prefix, or 0 so the first real ADR after the seed is
# numbered one past it. 10# forces base-10 so a leading zero isn't read as octal.
last=$(find "$ADR_DIR" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -exec basename {} \; |
  sort | tail -n1 | cut -c1-4)
next=$(printf '%04d' $((10#${last:-0} + 1)))

# Slug: lowercase, spaces/underscores to hyphens, drop other punctuation,
# collapse repeats, trim leading/trailing hyphens.
slug=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' |
  tr -cd 'a-z0-9-' | sed 's/-\{2,\}/-/g; s/^-//; s/-$//')
file="$ADR_DIR/${next}-${slug}.md"

# Fill the template's placeholders; leave the body sections for the author.
sed -e "s/^# NUMBER\. TITLE/# ${next}. ${TITLE}/" \
  -e "s/^Date: DATE/Date: $(date +%Y-%m-%d)/" \
  -e "s/^STATUS/Accepted/" \
  "$TEMPLATE" >"$file"

echo "created $file — edit it to fill in Context, Decision, Alternatives, Consequences."
