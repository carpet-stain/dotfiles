{ config, lib, pkgs, ... }:

{
    imports = [
        ./hardware-configuration.nix
    ];

boot.loader.systemd-boot.enable = true;

networking.hostName = "nixos";
networking.wireless.enable = true;

time.timeZone = "America/New_York"

i18n.defaultLocale = "en_US.UTF-8"

users.users.brian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    passwordHash = ""
    packages = with pkgs; [
        firefox
        tree
    ];
};

# List packages installed in system profile. To search, run:
# $ nix search wget
environment.systemPackages = with pkgs; [
    neovim
    wget
    git
];

programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
};

services.openssh.enable = true;

system.stateVersion = "23.11";

}