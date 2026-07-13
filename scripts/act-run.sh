#!/usr/bin/env bash
# Wraps `act` with an on-demand Colima VM: starts Colima if it isn't already
# running, runs act, then stops Colima again only if this invocation is what
# started it. An already-running Colima (left up across several act runs) is
# left alone — an unconditional stop would force every run to eat Colima's
# ~10-20s VM boot again. Resources are capped modestly (Colima's own default
# is 100GiB disk) since this VM only needs to run act's containers.
#
# For "I'm done, tear it down": `colima stop` directly.
set -euo pipefail

started_colima=0
if ! colima status >/dev/null 2>&1; then
  # act bind-mounts the daemon socket into every job container for
  # docker-outside-of-docker; virtiofs (Colima's default mount type) can't
  # satisfy that mount — the guest's dockerd gets ENOTSUP trying to mkdir
  # the socket's path (abiosoft/colima#997, nektos/act#2486). sshfs doesn't
  # hit this.
  colima start --cpu 2 --memory 4 --disk 20 --mount-type sshfs
  started_colima=1
fi

# `colima start` switches the docker CLI's own context, but act reads
# $DOCKER_HOST directly rather than resolving the active context, so it
# can't find Colima's socket without this — confirmed by testing, act
# otherwise falls back to the (nonexistent, on macOS) default
# /var/run/docker.sock and fails outright.
DOCKER_HOST=$(colima status --json | jaq -r .docker_socket)
export DOCKER_HOST

cleanup() {
  docker container prune -f >/dev/null
  [[ $started_colima -eq 1 ]] && colima stop
}
trap cleanup EXIT

act "$@"
