#!/bin/bash

set -e
exec 2> >(while read line; do echo -e "\e[01;31m$line\e[0m"; done)

script_name="$(basename "$0")"
dotfiles_dir="$(
    cd "$(dirname "$0")"
    pwd
)"
cd "$dotfiles_dir"

if (("$EUID")); then
    sudo -s "$dotfiles_dir/$script_name" "$@"
    exit 0
fi

if [ "$1" = "-r" ]; then
    echo >&2 "Running in reverse mode!"
    reverse=1
fi

copy() {
    if [ -z "$reverse" ]; then
        orig_file="$dotfiles_dir/$1"
        [ -n "$3" ] && dest_file="/$3" || dest_file="/$1"
    else
        [ -n "$3" ] && orig_file="/$3" || orig_file="/$1"
        dest_file="$dotfiles_dir/$1"
    fi

    mkdir -p "$(dirname "$orig_file")"
    mkdir -p "$(dirname "$dest_file")"

    rm -rf "$dest_file"

    cp -R "$orig_file" "$dest_file"
    if [ -z "$reverse" ]; then
        [ -n "$2" ] && chmod "$2" "$dest_file"
    else
        chown -R brian "$dest_file"
    fi
    echo "$dest_file <= $orig_file"
}

is_chroot() {
    ! cmp -s /proc/1/mountinfo /proc/self/mountinfo
}

systemctl_enable_start() {
    echo "systemctl enable --now "$1""
    systemctl enable "$1"
    systemctl start "$1"
}

echo ""
echo "=========================="
echo "Setting up /etc configs..."
echo "=========================="

copy "etc/iwd/main.conf"
copy "etc/nftables.conf"
copy "etc/pacman.conf" 644 "etc/pacman.conf"
copy "etc/sudoers.d/override"
copy "etc/ssh/ssh_config"

(("$reverse")) && exit 0 

echo "================================="
echo "Enabling and starting services..."
echo "================================="

sysctl --system > /dev/null

systemctl daemon-reload
systemctl_enable_start "iwd.service"
systemctl_enable_start "nftables.service"
systemctl_enable_start "systemd-networkd.socket"
systemctl_enable_start "systemd-resolved.service"

echo ""
echo "===================="
echo "Reload udev rules..."
echo "===================="
udevadm control --reload
udevadm trigger

echo ""
echo "======================================="
echo "Finishing various user configuration..."
echo "======================================="

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping /etc/resolv.conf setup..."
else
    echo "Configuring /etc/resolv.conf"
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

echo "Configuring NTP"
timedatectl set-ntp true
