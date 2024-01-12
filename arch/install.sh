#!/bin/bash
#
# Arch Linux installation
#
# Bootable USB:
# - [Download](https://archlinux.org/download/) ISO and GPG files
# - Verify the ISO file: `$ pacman-key -v archlinux-<version>-dual.iso.sig`
# - Create a bootable USB with: `# dd if=archlinux*.iso of=/dev/sdX && sync`
#
# UEFI setup:
#
# - Set boot mode to UEFI, disable Legacy mode entirely.
# - Temporarily disable Secure Boot.
# - Make sure a strong UEFI administrator password is set.
# - Delete preloaded OEM keys for Secure Boot, allow custom ones.
# - Set SATA operation to AHCI mode.
#
# Run installation:
#
# - Connect to wifi via: `# iwctl station wlan0 connect WIFI-NETWORK`
# - Run: `# bash <(curl -sL https://t.ly/o4kG)`

set -uo pipefail
trap on_error ERR

# Redirect output to files for easier debugging
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log" >&2)

MIRRORLIST_URL="https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on"

# Dialog
BACKTITLE="Arch Linux installation"

on_error() {
	ret=$?
	echo "[$0] Error on line $LINENO: $BASH_COMMAND"
	exit $ret
}

get_input() {
	title="$1"
	description="$2"

	input=$(dialog --clear --stdout --backtitle "$BACKTITLE" --title "$title" --inputbox "$description" 0 0)
	echo "$input"
}

get_password() {
	title="$1"
	description="$2"

	init_pass=$(dialog --clear --stdout --backtitle "$BACKTITLE" --title "$title" --passwordbox "$description" 0 0)
	test -z "$init_pass" && echo >&2 "password cannot be empty" && exit 1

	test_pass=$(dialog --clear --stdout --backtitle "$BACKTITLE" --title "$title" --passwordbox "$description again" 0 0)
	if [[ "$init_pass" != "$test_pass" ]]; then
		echo "Passwords did not match" >&2
		exit 1
	fi
	echo "$init_pass"
}

get_choice() {
	title="$1"
	description="$2"
	shift 2
	options=("$@")
	dialog --clear --stdout --backtitle "$BACKTITLE" --title "$title" --menu "$description" 0 0 0 "${options[@]}"
}

echo -e "\n### Checking UEFI boot mode"
if [ ! -d /sys/firmware/efi ]; then
	echo >&2 "Legacy BIOS boot detected. You must boot in UEFI mode to continue"
	exit 1
fi

# Unmount previously mounted devices in case the install script is run multiple times
swapoff -a || true
umount -R /mnt 2>/dev/null || true

# Basic settings
timedatectl set-ntp true
hwclock --systohc --utc

# Keyring from ISO might be outdated, upgrading it just in case
pacman -Sy --noconfirm --needed archlinux-keyring

# Make sure some basic tools that will be used in this script are installed
pacman -Sy --noconfirm --needed git terminus-font dialog wget

# Adjust the font size in case the screen is hard to read
noyes=("Yes" "The font is too small" "No" "The font size is just fine")
hidpi=$(get_choice "Font size" "Is your screen HiDPI?" "${noyes[@]}") || exit 1
clear
[[ "$hidpi" == "Yes" ]] && font="ter-132n" || font="ter-716n"
setfont "$font"

# Ask which device to install ArchLinux on
devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac | tr '\n' ' ')
read -r -a devicelist <<<"$devicelist"
device=$(get_choice "Installation" "Select installation disk" "${devicelist[@]}") || exit 1
clear

noyes=("Yes" "I want to remove everything on $device" "No" "GOD NO !! ABORT MISSION")
lets_go=$(get_choice "Are you absolutely sure ?" "YOU ARE ABOUT TO ERASE EVERYTHING ON $device" "${noyes[@]}") || exit 1
clear
[[ "$lets_go" == "No" ]] && exit 1

hostname=$(get_input "Hostname" "Enter hostname") || exit 1
clear
test -z "$hostname" && echo >&2 "hostname cannot be empty" && exit 1

user=$(get_input "User" "Enter username") || exit 1
clear
test -z "$user" && echo >&2 "user cannot be empty" && exit 1

user_password=$(get_password "User" "Enter password") || exit 1
clear
test -z "$user_password" && echo >&2 "user password cannot be empty" && exit 1

echo "Updating fastests mirrors list"
curl -s "$MIRRORLIST_URL" |
	sed -e 's/^#Server/Server/' -e '/^#/d' |
	rankmirrors -n 5 - >/etc/pacman.d/mirrorlist

echo "Writing random bytes to $device, go grab some coffee it might take a while"
dd bs=1M if=/dev/urandom of="$device" status=progress || true

### Setup the disk and partitions ###
swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_end=$(($swap_size + 129 + 1))MiB

parted --script "${device}" -- mklabel gpt \
	mkpart ESP fat32 1Mib 129MiB \
	set 1 boot on \
	mkpart primary linux-swap 129MiB ${swap_end} \
	mkpart primary ext4 ${swap_end} 100%

# Simple globbing was not enough as on one device I needed to match /dev/mmcblk0p1
# but not /dev/mmcblk0boot1 while being able to match /dev/sda1 on other devices
part_boot="$(ls ${device}* | grep -E "^${device}p?1$")"
part_swap="$(ls ${device}* | grep -E "^${device}p?2$")"
part_root="$(ls ${device}* | grep -E "^${device}p?3$")"

wipefs "${part_boot}"
wipefs "${part_swap}"
wipefs "${part_root}"

mkfs.vfat -n "EFI" -F 32 "${part_boot}"
mkswap "${part_swap}"
mkfs.f2fs -f "${part_root}"

swapon "${part_swap}"
mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot

# Install all packages listed in packages/regular
grep -o '^[^ *#]*' packages | pacstrap -K /mnt -

# Patch pacman config
sed -i "s/#Color/Color/g" /mnt/etc/pacman.conf

# Kernel parameters
{
	# Allow suspend state (puts device into sleep but keeps powering the RAM for fast sleep mode recovery)
	echo -n " mem_sleep_default=deep"

} >/mnt/etc/kernel/cmdline

echo "${hostname}" >/mnt/etc/hostname
echo "en_US.UTF-8 UTF-8" >/mnt/etc/locale.gen
ln -sf /usr/share/zoneinfo/US/Central "/etc/localtime"
sed 's/#en_US/en_US/' -i /etc/locale.gen
arch-chroot /mnt locale-gen

genfstab -U /mnt >>/mnt/etc/fstab

arch-chroot /mnt bootctl install

cat <<EOF >/mnt/boot/loader/loader.conf
default arch
EOF

cat <<EOF >/mnt/boot/loader/entries/arch.conf
title    Arch Linux
linux    /vmlinuz-linux
initrd   /intel-ucode.img
initrd   /initramfs-linux.img
options  root=PARTUUID=$(blkid -s PARTUUID -o value "$part_root") rw
EOF

echo -e "\n### Creating user"
arch-chroot /mnt useradd -m -s /usr/bin/zsh "$user"
for group in wheel network storage video audio input; do
	arch-chroot /mnt groupadd -rf "$group"
	arch-chroot /mnt gpasswd -a "$user" "$group"
done

# Hardening
arch-chroot /mnt chmod 700 /boot
arch-chroot /mnt chsh -s /usr/bin/zsh
echo "$user:$password" | arch-chroot /mnt chpasswd
arch-chroot /mnt passwd -dl root

# Configure systemd services
arch-chroot /mnt systemctl enable systemd-networkd
arch-chroot /mnt systemctl enable systemd-resolved
arch-chroot /mnt systemctl enable systemd-timesyncd
arch-chroot /mnt systemctl enable iwd
arch-chroot /mnt systemctl enable nftables
arch-chroot /mnt systemctl enable docker

# Configure systemd user services
arch-chroot /mnt systemctl --global enable pipewire
arch-chroot /mnt systemctl --global enable wireplumber

# arch-chroot /mnt sudo -u $user bash -c 'git clone --recursive https://aur.archlinux.org/yay.git'
# arch-chroot /mnt sudo -u $user bash -c 'cd yay && makepkg -si'
# arch-chroot /mnt sudo -u $user bash -c 'curl https://github.com/olets/gpg | gpg --import'
# arch-chroot /mnt sudo -u $user bash -c 'yay -S zsh-abr --sudoloop --noconfirm'
# arch-chroot /mnt sudo -u $user bash -c 'git clone --recursive https://github.com/carpet-stain/dotfiles.git ~/.dotfiles'
# arch-chroot /mnt sudo -u $user bash -c 'cd ~/.dotfiles/arch/aur/zsh-syntax-highlighting && makepkg -siCc --noconfirm'
echo -e "\n### Running initial setup"
# arch-chroot /mnt chmod +700 /home/$user/.dotfiles/arch/setup-base-system.sh
# arch-chroot /mnt /home/$user/.dotfiles/arch/setup-base-system.sh

echo -e "\n### Reboot now, and after power off remember to unplug the installation USB"
umount -R /mnt
