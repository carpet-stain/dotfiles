#!/bin/bash

# Run installation:
#
# - Connect to wifi via: `# iwctl station wlan0 connect WIFI-NETWORK`
# - Run: `# bash <(curl -sL https://t.ly/o4kG)`

set -uo pipefail

# Redirect output to files for easier debugging
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log" >&2)

FLAKE="github:carpet-stain/dotfiles?dir=nixos/vm#nixos"

BACKTITLE="NixOS installation"

get_choice() {
	title="$1"
	description="$2"
	shift 2
	options=("$@")
	dialog --clear --stdout --backtitle "$BACKTITLE" --title "$title" --menu "$description" 0 0 0 "${options[@]}"
}

nix-env -iA nixos.dialog

# Ask which device to install NixOS on
devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac | tr '\n' ' ')
read -r -a devicelist <<<"$devicelist"
DEVICE=$(get_choice "Installation" "Select installation disk" "${devicelist[@]}") || exit 1
echo $DEVICE
clear

sudo nix \
    --extra-experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "$FLAKE" \
    --write-efi-boot-entries \
    --disk main "$DEVICE"
