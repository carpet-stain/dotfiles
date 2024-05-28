{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    };
    
    outputs = inputs@{ self, nixpkgs, ... }: {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux"
            modules = [
                ./configuration.nix
                {
                    nix = {
                        settings.experimental-features = [ "nix-command" "flakes" ];
                    };
                }
            ];
        };
    };
}