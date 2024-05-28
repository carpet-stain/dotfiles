{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }:
    let
      # TODO: Adjust these values to your needs
      system = "aarch64-linux";
      hostName = "nixos";
    in
    {
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./disk-config.nix
          disko.nixosModules.disko
          ({ pkgs, ... }: {
            boot.loader = {
              systemd-boot.enable = true;
              efi.canTouchEfiVariables = true;
            };
            networking = { inherit hostName; };
            networking.wireless.enable = true;

            time.timeZone = "America/New_York";

            i18n.defaultLocale = "en_US.UTF-8";

            users.users.brian = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                passwordHash = ""
                packages = with pkgs; [
                    firefox
                    tree
                ];
            };
            services.openssh.enable = true;
            environment.systemPackages = with pkgs; [
              htop
              git
              neovim
            ];
            system.stateVersion = "23.11";
          })
        ];
      };
    };
}