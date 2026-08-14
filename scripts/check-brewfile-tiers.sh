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

# apt-name aliases for macOS-only tools whose apt package name differs. Empty:
# go/gh/fnm are payload tier (ADR-0006/ADR-0030), so nothing needs one yet.
declare -A apt_aliases=()

status=0

# names_in <file> — every tap/brew/cask name declared in a Brewfile.
names_in() {
  grep -oE "^(tap|brew|cask) '[^']+'" "$1" | sed -E "s/^(tap|brew|cask) '//; s/'\$//"
}

mapfile -t payload_names < <(names_in "$payload_file")
mapfile -t dev_names < <(names_in "$dev_file")
mapfile -t personal_names < <(names_in "$personal_file")

# A name declared in more than one Brewfile is ambiguous classification —
# fail closed rather than pick one.
all_names=("${payload_names[@]}" "${dev_names[@]}" "${personal_names[@]}")
duplicates="$(printf '%s\n' "${all_names[@]}" | sort | uniq -d)"
if [[ -n "$duplicates" ]]; then
  while IFS= read -r dup; do
    printf 'macos/Brewfile.*: "%s" declared in more than one Brewfile\n' "$dup" >&2
  done <<<"$duplicates"
  status=1
fi

# Whole-word so "go" doesn't match inside "golang". grep, not [[ =~ ]] —
# $text is multi-line and grep anchors ^/$ per line, not to the whole blob.
name_matches() {
  local tool="$1" text="$2"
  grep -qE "(^|[^A-Za-z0-9_-])${tool}([^A-Za-z0-9_-]|\$)" <<<"$text"
}

# Scope to `apt-get install` lines only — word-scanning all of deploy.sh
# false-positives on prose. Joins backslash continuations first.
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
