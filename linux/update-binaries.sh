#!/usr/bin/env bash
# Regenerate linux/binaries.lock — the pinned version + sha256 (per arch) of
# every GitHub-release binary that linux/deploy.sh installs. Run this to bump
# versions, then commit the resulting binaries.lock; don't hand-edit the lock.
#
# For each tool it fetches the latest release, resolves the asset for each
# arch by pattern, downloads it, and records tool/arch/version/url/sha256.
# Uses $GH_TOKEN if set (higher API rate limit), but works without it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK="$SCRIPT_DIR/binaries.lock"

# tool | repo | x86_64 asset pattern | aarch64 asset pattern
# Patterns are matched against the release's browser_download_url list, so
# the version embedded in some asset names is a `.*` wildcard here.
TOOLS=(
  "neovim|neovim/neovim|nvim-linux-x86_64.tar.gz|nvim-linux-arm64.tar.gz"
  "delta|dandavison/delta|delta-.*-x86_64-unknown-linux-musl.tar.gz|delta-.*-aarch64-unknown-linux-gnu.tar.gz"
  "zellij|zellij-org/zellij|zellij-x86_64-unknown-linux-musl.tar.gz|zellij-aarch64-unknown-linux-musl.tar.gz"
  "eza|eza-community/eza|eza_x86_64-unknown-linux-musl.tar.gz|eza_aarch64-unknown-linux-gnu.tar.gz"
  "doggo|mr-karan/doggo|doggo-linux-x86_64.tar.gz|doggo-linux-aarch64.tar.gz"
  "dua|Byron/dua-cli|dua-v.*-x86_64-unknown-linux-musl.tar.gz|dua-v.*-aarch64-unknown-linux-musl.tar.gz"
  "curlie|rs/curlie|curlie_.*_linux_amd64.tar.gz|curlie_.*_linux_arm64.tar.gz"
  "jaq|01mf02/jaq|jaq-x86_64-unknown-linux-gnu\$|jaq-aarch64-unknown-linux-gnu\$"
)

gh_api() {
  local auth=()
  [[ -n "${GH_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GH_TOKEN")
  curl -fsSL "${auth[@]}" "https://api.github.com/repos/$1/releases/latest"
}

# Match one asset URL from a release JSON blob by extended-regex pattern.
match_asset() {
  grep -oP '"browser_download_url":\s*"\K[^"]+' <<<"$1" | grep -E "$2" | head -1
}

sha_of_url() {
  local tmp; tmp="$(mktemp)"
  curl -fsSL "$1" -o "$tmp"
  sha256sum "$tmp" | cut -d' ' -f1
  rm -f "$tmp"
}

{
  printf '# Pinned GitHub-release binaries for linux/deploy.sh — regenerate with\n'
  printf '# linux/update-binaries.sh; do not hand-edit. Tab-separated fields:\n'
  printf '# tool  arch  version  url  sha256\n'
  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r tool repo pat_x86 pat_arm <<<"$entry"
    printf '  %s: latest release of %s...\n' "$tool" "$repo" >&2
    json="$(gh_api "$repo")"
    version="$(grep -oP '"tag_name":\s*"\K[^"]+' <<<"$json" | head -1)"
    for arch_pat in "x86_64|$pat_x86" "aarch64|$pat_arm"; do
      arch="${arch_pat%%|*}"; pat="${arch_pat#*|}"
      url="$(match_asset "$json" "$pat")"
      if [[ -z "$url" ]]; then
        printf '  ERROR: no %s asset matching /%s/ for %s\n' "$arch" "$pat" "$tool" >&2
        exit 1
      fi
      printf '    %s -> %s\n' "$arch" "${url##*/}" >&2
      printf '%s\t%s\t%s\t%s\t%s\n' "$tool" "$arch" "$version" "$url" "$(sha_of_url "$url")"
    done
  done
} > "$LOCK.tmp"
mv "$LOCK.tmp" "$LOCK"
printf 'wrote %s\n' "$LOCK" >&2
