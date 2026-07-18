# Repo task runner — one entry point for the dev verbs (see ADR-0019 for why
# `just` over `make`). Run `just` with no args for the recipe list.
#
# Linux VM recipes drive an OrbStack Debian VM to exercise linux/deploy.sh —
# macOS-host dev tooling, not part of any deploy and not run by CI (a full
# run is slow: the LazyVim/Mason bootstrap alone takes minutes on a cold
# cache). Meant to be run by hand before a release, not on every commit.
#
#   just test                                    # ensure VM up, deploy + smoke (reuses VM)
#   just test-setup                              # just ensure a VM is up (idempotent)
#   just e2e-test                                # clean-room: wipe VM, deploy + smoke
#   just e2e-test DEBIAN=bookworm VM=dotfiles-test-12
#   just vm-fresh DEBIAN=bookworm VM=dotfiles-test-12
#   just deploy VM=dotfiles-test-12
#   just smoke-test VM=dotfiles-test-12
#   just ssh VM=dotfiles-test-12
#
# test vs e2e-test: `test` reuses an existing VM (fast, for iterating);
# `e2e-test` wipes and recreates it first (clean-room, for a pre-release check).

VM := "dotfiles-test"
DEBIAN := "trixie"
REPO := justfile_directory()

# RemoteCommand is dropped for the scripted targets below (deploy, smoke-test,
# wait-for-ssh) since it conflicts with passing an explicit command over ssh —
# see ssh/config's "DEVBOX PERSISTENCE" section. The plain `ssh` recipe keeps
# it, since that's for interactive use.
SSH := "ssh -o RemoteCommand=none -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new " + VM + "@orb"

# List recipes when invoked with no arguments.
_default:
    @just --list

# +--------------------------------------------------------------------------+
# | Repo dev verbs                                                            |
# +--------------------------------------------------------------------------+

# Run every pre-commit check (the entry point CI's lint job calls too).
lint *args:
    lefthook run pre-commit --all-files {{ args }}

# Render-then-lint the copier templates (git-flow/python) — see #310 and
# scripts/lint-templates.sh's own header for the strategy.
lint-templates:
    scripts/lint-templates.sh

# Run the GitHub Actions workflows locally via act (Colima-backed); args pass through.
act *args:
    scripts/act-run.sh {{ args }}

# Preview the version + changelog release automation would compute (no side effects).
cliff-preview *args:
    git cliff --bump {{ args }}

# Create/supersede an ADR (adr-tools): `just adr "Title"`, or `just adr -s 12 "Title"`.
# VISUAL=true so adr-tools writes the file without hanging on $EDITOR; then edit it.
adr *args:
    VISUAL=true adr new {{ args }}

# +--------------------------------------------------------------------------+
# | Linux VM (OrbStack) — exercise linux/deploy.sh                           |
# +--------------------------------------------------------------------------+

# Wipe and recreate the VM, then wait for SSH.
vm-fresh: vm-delete
    orbctl create debian:{{ DEBIAN }} {{ VM }}
    just VM={{ VM }} DEBIAN={{ DEBIAN }} wait-for-ssh

# Create the VM only if it doesn't already exist (non-destructive, unlike vm-fresh).
vm-ensure:
    @orbctl list 2>/dev/null | awk '{print $1}' | grep -qx '{{ VM }}' || orbctl create debian:{{ DEBIAN }} {{ VM }}
    @just VM={{ VM }} DEBIAN={{ DEBIAN }} wait-for-ssh

vm-delete:
    -orbctl delete -f {{ VM }}

wait-for-ssh:
    #!/usr/bin/env bash
    set -euo pipefail
    for _ in $(seq 1 30); do
      {{ SSH }} true >/dev/null 2>&1 && exit 0
      sleep 2
    done
    echo "{{ VM }} never came up for SSH" >&2
    exit 1

ssh:
    ssh {{ VM }}@orb

deploy:
    {{ SSH }} 'cd {{ REPO }}/linux && bash deploy.sh'

smoke-test:
    {{ SSH }} 'bash -s' < {{ REPO }}/linux/smoke-test.sh

# Idempotently make sure a VM is up and reachable — nothing deployed yet.
test-setup: vm-ensure

# Fast iterate loop: reuse the VM (create if missing), deploy, smoke-test.
test: vm-ensure deploy smoke-test
    @echo "test passed for {{ VM }} (debian:{{ DEBIAN }})"

e2e-test: vm-fresh deploy smoke-test
    @echo "e2e test passed for {{ VM }} (debian:{{ DEBIAN }})"
