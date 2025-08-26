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
  };

  outputs = { self, nixpkgs, prettyswitch, hyprland, ... }: {
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
    };

    nixosConfigurations = {
      rvbee = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/rvbee/system.nix
          prettyswitch.nixosModules.default
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
        ];
        specialArgs = {
          inherit hyprland;
        };
      };
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Graphical ISO with Calamares (Plasma)
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix")
          # Optional: add extra tools to the live ISO
          ({ pkgs, ... }: {
            environment.systemPackages = with pkgs; [
              neovim
              git
              firefox
              btop
            ];
          })
        ];
      };
    };
  };
}
