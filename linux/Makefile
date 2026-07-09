# Convenience wrapper for spinning up/testing deploy.sh against an OrbStack
# Debian VM. Dev tooling only — not part of the actual deploy, and not
# wired into CI: a full run is slow (the LazyVim/Mason bootstrap alone can
# take several minutes on a cold cache), so this is meant to be run by
# hand before something like a release, not on every commit.
#
# Usage:
#   make e2e-test                                  # trixie, default VM name
#   make e2e-test DEBIAN=bookworm VM=dotfiles-test-12
#   make vm-fresh DEBIAN=bookworm VM=dotfiles-test-12
#   make deploy VM=dotfiles-test-12
#   make smoke-test VM=dotfiles-test-12
#   make ssh VM=dotfiles-test-12

VM     ?= dotfiles-test
DEBIAN ?= trixie
DIR    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO   := $(shell cd $(DIR).. && pwd)

# RemoteCommand is dropped for the scripted targets below (deploy,
# smoke-test, wait-for-ssh) since it conflicts with passing an explicit
# command over ssh — see ssh/config's "DEVBOX PERSISTENCE" section. The
# plain `ssh` target keeps it, since that's for interactive use.
SSH := ssh -o RemoteCommand=none -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new $(VM)@orb

.PHONY: vm-fresh vm-delete wait-for-ssh ssh deploy smoke-test e2e-test

vm-fresh: vm-delete
	orbctl create debian:$(DEBIAN) $(VM)
	$(MAKE) wait-for-ssh VM=$(VM)

vm-delete:
	-orbctl delete -f $(VM)

wait-for-ssh:
	@for i in $$(seq 1 30); do \
	  $(SSH) true >/dev/null 2>&1 && exit 0; \
	  sleep 2; \
	done; \
	echo "$(VM) never came up for SSH" >&2; exit 1

ssh:
	ssh $(VM)@orb

deploy:
	$(SSH) 'cd $(REPO)/linux && bash deploy.sh'

smoke-test:
	$(SSH) 'bash -s' < $(DIR)smoke-test.sh

e2e-test: vm-fresh deploy smoke-test
	@echo "e2e test passed for $(VM) (debian:$(DEBIAN))"
