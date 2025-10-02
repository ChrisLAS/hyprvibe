{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # musnix.url = "github:musnix/musnix";
    # musnix.inputs.nixpkgs.follows = "nixpkgs";
    # companion.url = "github:noblepayne/bitfocus-companion-flake";
    # companion.inputs.nixpkgs.follows = "nixpkgs";

    prettyswitch.url = "github:noblepayne/pretty-switch";
    prettyswitch.inputs.nixpkgs.follows = "nixpkgs";
    
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, prettyswitch, hyprland, lanzaboote, ... }: {
    # Formatter (optional)
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosModules = {
      shared = import ./modules/shared;
      shared-packages = import ./modules/shared/packages.nix;
      shared-desktop = import ./modules/shared/desktop.nix;
      shared-hyprland = import ./modules/shared/hyprland.nix;
      shared-waybar = import ./modules/shared/waybar.nix;
      shared-shell = import ./modules/shared/shell.nix;
      shared-services = import ./modules/shared/services.nix;
      shared-lanzaboote = import ./modules/shared/lanzaboote.nix;
    };

    nixosConfigurations = {
      rvbee = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/rvbee/system.nix
          prettyswitch.nixosModules.default
          lanzaboote.nixosModules.lanzaboote
        ];
        specialArgs = {
          inherit hyprland;
        };
            };
      nixstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixstation/system.nix
          prettyswitch.nixosModules.default
          lanzaboote.nixosModules.lanzaboote
        ];
        specialArgs = {
          inherit hyprland;
        };
      };
    };
  };
}
