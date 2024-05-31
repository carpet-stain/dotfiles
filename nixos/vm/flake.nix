{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }:
    let
      system = "aarch64-linux";
      hostName = "nixos";
    in
    {
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
            {
                disko.devices = {
                    disk = {
                        main = {
                            device = "/dev/nvme0n1";
                            type = "disk";
                            content = {
                                type = "gpt";
                                partitions = {
                                    ESP = {
                                        type = "EF00";
                                        size = "500M";
                                        content = {
                                            type = "filesystem";
                                            format = "vfat";
                                            mountpoint = "/boot";
                                        };
                                    };
                                    root = {
                                        size = "100%";
                                        content = {
                                            type = "filesystem";
                                            format = "ext4";
                                            mountpoint = "/";
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            }
          disko.nixosModules.disko
          ({ pkgs, ... }: {
            boot.loader = {
              systemd-boot.enable = true;
              efi.canTouchEfiVariables = true;
            };
            networking = { inherit hostName; };

            users.users.brian = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                password = "brian";
            };
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