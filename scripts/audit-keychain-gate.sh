#!/usr/bin/env bash
# Audit infra's crown-jewel gate: the elevated Keychain items must prompt
# for the keychain password on every secret read (infra's ADR-0010; the
# invariant is iam/main.tf's header there). One "Always Allow" click — or a
# confirm setting that skips the password because an app sits in the item's
# allow-list — opens the fence silently: found live in that state on
# 2026-08-09 (infra#167). Part of infra's periodic audit (its
# docs/BOOTSTRAP.md); lives here because the items are this machine's
# login-Keychain state, like aws-vended-token's read path.
# Reads ACL metadata only (dump-keychain -a): no prompt, no secret exposed.
#
# usage: audit-keychain-gate
set -euo pipefail

items="infra-aws-local-apply infra-aws-bootstrap"
keychain="${HOME}/Library/Keychains/login.keychain-db"

# For each target item, every ACL entry authorizing decrypt must require the
# keychain password and hold an empty application allow-list. Anything the
# dump doesn't yield in the expected shape fails closed.
verdicts="$(security dump-keychain -a "$keychain" | awk -v targets="$items" '
  BEGIN { n = split(targets, tl, " "); for (i = 1; i <= n; i++) want[tl[i]] = 1 }
  function flag(reason) { bad[svce] = bad[svce] "\n  " reason }
  function close_entry(c) {
    if (svce in want && auth ~ /decrypt/) {
      seen[svce]++
      if (dontreq) flag("read does not require the keychain password")
      else if (!reqpw) flag("password requirement not found in ACL entry")
      if (apps == "") flag("application allow-list not found in ACL entry")
      else if (apps ~ /<null>/) flag("every application may read silently (Always Allow)")
      else {
        c = apps; gsub(/[^0-9]/, "", c)
        if (c != "" && c + 0 > 0) flag("allow-list holds " c " app(s) that read silently")
      }
    }
    auth = ""; reqpw = 0; dontreq = 0; apps = ""
  }
  /^keychain:/ { close_entry(); svce = "" }
  /"svce"<blob>=/ { svce = $0; sub(/.*"svce"<blob>="/, "", svce); sub(/"$/, "", svce) }
  /^[[:space:]]*entry [0-9]+:/ { close_entry() }
  /^[[:space:]]*authorizations \(/ { auth = $0 }
  /^[[:space:]]*don.t-require-password$/ { dontreq = 1 }
  /^[[:space:]]*require-password$/ { reqpw = 1 }
  /^[[:space:]]*applications/ { apps = $0 }
  END {
    close_entry()
    for (i = 1; i <= n; i++) {
      s = tl[i]
      if (!seen[s]) print "FAIL " s ": no decrypt ACL entry found — item missing, or the dump format changed"
      else if (s in bad) print "FAIL " s ":" bad[s]
      else print "OK   " s ": every read prompts for the keychain password"
    }
  }
')"

echo "$verdicts"
if grep -q '^FAIL' <<<"$verdicts"; then
  echo >&2
  echo "fix: Keychain Access → the item → Access Control →" >&2
  echo "  'Confirm before allowing access' + 'Ask for Keychain password'," >&2
  echo "  empty app list — then re-run (infra#167)" >&2
  exit 1
fi
