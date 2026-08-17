#!/usr/bin/env bash
# Wraps `act` with an on-demand Colima VM: starts Colima if it isn't already
# running, runs act, then stops Colima again only if this invocation is what
# started it. An already-running Colima (left up across several act runs) is
# left alone — an unconditional stop would force every run to eat Colima's
# ~10-20s VM boot again. Resources are capped modestly (Colima's own default
# is 100GiB disk) since this VM only needs to run act's containers.
#
# For "I'm done, tear it down": `colima stop` directly.
#
# COLIMA_HOME (zsh/.zshenv) relocates Colima's whole tree at once — config,
# VM disk, sockets, logs: Lima's maintainers deliberately don't split those,
# so XDG_CONFIG_HOME's narrower support is the wrong lever. No LIMA_HOME —
# Colima nests Lima's home at $COLIMA_HOME/_lima itself. actrc (repo root,
# symlinked to $XDG_CONFIG_HOME/act/actrc by deploy.zsh) pins the runner
# image so act doesn't pull its own multi-GB default.
set -euo pipefail

started_colima=0
if ! colima status >/dev/null 2>&1; then
  # sshfs, not virtiofs: act bind-mounts the daemon socket into every job
  # container and virtiofs ENOTSUPs it (abiosoft/colima#997, nektos/act#2486).
  colima start --cpu 2 --memory 4 --disk 20 --mount-type sshfs
  started_colima=1
fi

# act reads $DOCKER_HOST directly instead of resolving the docker context, so
# without this it falls back to /var/run/docker.sock and fails on macOS.
DOCKER_HOST=$(colima status --json | jaq -r .docker_socket)
export DOCKER_HOST

cleanup() {
  docker container prune -f >/dev/null
  [[ $started_colima -eq 1 ]] && colima stop
}
trap cleanup EXIT

act "$@"
