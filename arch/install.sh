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
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log" >&2)

MIRRORLIST_URL="https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on"

pacman -Sy --noconfirm pacman-contrib dialog

echo "Updating mirror list"
curl -s "$MIRRORLIST_URL" | \
    sed -e 's/^#Server/Server/' -e '/^#/d' | \
    rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

# Dialog
BACKTITLE="Arch Linux installation"

### Get infomation from user ###
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password=$(dialog --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}
password2=$(dialog --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1
clear

echo -e "\n### Checking UEFI boot mode"
if [ ! -f /sys/firmware/efi/fw_platform_size ]; then
    echo >&2 "You must boot in UEFI mode to continue"
    exit 2
fi

echo -e "\n### Setting up clock"
timedatectl set-ntp true
hwclock --systohc

### Setup the disk and partitions ###
swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_end=$(( $swap_size + 129 + 1 ))MiB

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

mkfs.vfat -F32 "${part_boot}"
mkswap "${part_swap}"
mkfs.f2fs -f "${part_root}"

swapon "${part_swap}"
mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot

pacstrap /mnt base linux linux-firmware base-devel zsh git man-db man-pages intel-ucode nftables git iwd openssh firefox plasma-desktop dolphin electrum monero-gui plasma-wayland-session tmux neovim fzf bat colordiff diff-so-fancy fd gnupg htop httpie p7zip pbzip2 the_silver_searcher tree wget bitwarden signal-desktop alacritty bluez bluez-utils pipewire-audio


genfstab -t PARTUUID /mnt >> /mnt/etc/fstab
echo "${hostname}" > /mnt/etc/hostname

arch-chroot /mnt bootctl install

cat <<EOF > /mnt/boot/loader/loader.conf
default arch
EOF

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title    Arch Linux
linux    /vmlinuz-linux
initrd   /intel-ucode.img
initrd   /initramfs-linux.img
options  root=PARTUUID=$(blkid -s PARTUUID -o value "$part_root") rw
EOF

echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/US/Central "/etc/localtime"
sed 's/#en_US/en_US/' -i /etc/locale.gen
locale-gen

echo -e "\n### Creating user"
arch-chroot /mnt useradd -m -s /usr/bin/zsh "$user"
for group in wheel network storage video audio input; do
    arch-chroot /mnt groupadd -rf "$group"
    arch-chroot /mnt gpasswd -a "$user" "$group"
done
arch-chroot /mnt chsh -s /usr/bin/zsh
echo "$user:$password" | arch-chroot /mnt chpasswd
arch-chroot /mnt passwd -dl root

# arch-chroot /mnt sudo -u $user bash -c 'git clone --recursive https://aur.archlinux.org/yay.git'
# arch-chroot /mnt sudo -u $user bash -c 'cd yay && makepkg -si'
# arch-chroot /mnt sudo -u $user bash -c 'curl https://github.com/olets/gpg | gpg --import'
# arch-chroot /mnt sudo -u $user bash -c 'yay -S zsh-abr --sudoloop --noconfirm'
arch-chroot /mnt sudo -u $user bash -c 'git clone --recursive https://github.com/carpet-stain/dotfiles.git ~/.dotfiles'
arch-chroot /mnt sudo -u $user bash -c 'cd ~/.dotfiles/arch/aur/zsh-syntax-highlighting && makepkg -siCc --noconfirm'
echo -e "\n### Running initial setup"
arch-chroot /mnt chmod +700 /home/$user/.dotfiles/arch/setup-base-system.sh
arch-chroot /mnt /home/$user/.dotfiles/arch/setup-base-system.sh

echo -e "\n### Reboot now, and after power off remember to unplug the installation USB"
umount -R /mnt
