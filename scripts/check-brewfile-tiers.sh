#!/usr/bin/env bash
# Enforces the macos/Brewfile.{payload,dev,personal} split (#127/#364): a
# tap/brew/cask name may appear in exactly one of the three files — no
# silent duplicate/ambiguous classification — and no name from
# Brewfile.dev or Brewfile.personal (or its apt-name alias) may appear in
# linux/deploy.sh or linux/Aptfile. That's the actual leak ADR-0006/
# ADR-0030's tier model exists to prevent: macOS-only tooling reaching the
# disposable Linux VM. File placement *is* the classification — no `# tier:`
# comment convention to parse, no untagged-line case to fail closed on.
#
# Known blind spot, accepted per #127's ratification: this only catches a
# tool already declared in one of the three Brewfiles leaking onto Linux,
# not a brand-new dev tool added straight into Aptfile/deploy.sh and never
# added to any Brewfile at all — closing that gap needs generating Aptfile
# from the Brewfile, the exact machinery this mechanism deliberately avoids.
set -uo pipefail

payload_file="macos/Brewfile.payload"
dev_file="macos/Brewfile.dev"
personal_file="macos/Brewfile.personal"
aptfile="linux/Aptfile"
deploy_sh="linux/deploy.sh"

# Hand-maintained apt-name aliases for macOS-only tools whose apt package
# name would differ from its Brewfile name — the one piece of
# hand-maintenance this mechanism doesn't eliminate (small and explicit,
# not hidden in a generator). Empty for now: go/gh/fnm(node) are
# general-purpose dev tooling Linux keeps too (Brewfile.payload, provisioned
# via apt under their own apt names), not macOS-only — the only set this
# map needs to cover. Add an entry here if a macOS-only tool ever needs one.
declare -A apt_aliases=()

status=0

# names_in <file> — every tap/brew/cask name declared in a Brewfile.
names_in() {
  grep -oE "^(tap|brew|cask) '[^']+'" "$1" | sed -E "s/^(tap|brew|cask) '//; s/'\$//"
}

mapfile -t payload_names < <(names_in "$payload_file")
mapfile -t dev_names < <(names_in "$dev_file")
mapfile -t personal_names < <(names_in "$personal_file")

# Fail-closed replacement for the old "missing # tier: tag" check: a name
# declared in more than one file is exactly as ambiguous as an untagged
# line was, just detected by cross-referencing files instead of parsing
# comments.
all_names=("${payload_names[@]}" "${dev_names[@]}" "${personal_names[@]}")
duplicates="$(printf '%s\n' "${all_names[@]}" | sort | uniq -d)"
if [[ -n "$duplicates" ]]; then
  while IFS= read -r dup; do
    printf 'macos/Brewfile.*: "%s" declared in more than one Brewfile\n' "$dup" >&2
  done <<<"$duplicates"
  status=1
fi

# Whole-word match: a tool name must be its own token (surrounded by
# start/end-of-line or a non-identifier character), not a substring of an
# unrelated word — e.g. "go" must not match inside "golang" or "going". Uses
# grep (not bash's [[ =~ ]]) because $text is multi-line and grep anchors
# ^/$ per line, not to the whole blob.
name_matches() {
  local tool="$1" text="$2"
  grep -qE "(^|[^A-Za-z0-9_-])${tool}([^A-Za-z0-9_-]|\$)" <<<"$text"
}

# deploy.sh is prose (comments, unrelated XDG paths, the claude/ config
# symlinks, the Ghostty terminfo compile step) as much as it is code —
# scanning the whole file by word makes "go"/"claude"/"ghostty" (legitimate
# payload features, not necessarily the same as a macOS-only Brewfile entry
# of the same name) false-positive. The only place a hardcoded macOS-only
# package name could actually leak into deploy.sh is an `apt-get install`
# invocation, so scope the scan to those — joining backslash-continued lines
# first, since this script wraps long install commands across lines.
apt_install_lines() {
  awk '
    /\\$/ { sub(/\\$/, ""); buf = buf $0 " "; next }
    { print buf $0; buf = "" }
  ' "$1" | grep -i 'apt-get install'
}
deploy_sh_installs="$(apt_install_lines "$deploy_sh")"
aptfile_packages="$(grep -vE '^\s*#' "$aptfile")"

macos_only_names=("${dev_names[@]}" "${personal_names[@]}")
for tool in "${macos_only_names[@]}"; do
  names=("$tool")
  # shellcheck disable=SC2206 # word-splitting the alias list is intentional
  [[ -n "${apt_aliases[$tool]:-}" ]] && names+=(${apt_aliases[$tool]})
  for name in "${names[@]}"; do
    if name_matches "$name" "$aptfile_packages"; then
      printf '%s: macOS-only tool "%s" (from Brewfile'"'"'s "%s") leaked onto Linux\n' \
        "$aptfile" "$name" "$tool" >&2
      status=1
    fi
    if name_matches "$name" "$deploy_sh_installs"; then
      printf '%s: macOS-only tool "%s" (from Brewfile'"'"'s "%s") leaked onto Linux\n' \
        "$deploy_sh" "$name" "$tool" >&2
      status=1
    fi
  done
done

exit $status
