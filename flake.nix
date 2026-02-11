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

    openclaw.url = "github:openclaw/nix-openclaw";
    openclaw.inputs.nixpkgs.follows = "nixpkgs";

    freshrss-mcp.url = "github:ChrisLAS/freshrss-mcp";
    freshrss-mcp.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      prettyswitch,
      hyprland,
      openclaw,
      freshrss-mcp,
      ...
    }:
    {
      # Formatter (optional)
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      nixosModules = {
        # New hyprvibe-prefixed exports
        hyprvibe = import ./modules/shared;
        hyprvibe-packages = import ./modules/shared/packages.nix;
        hyprvibe-desktop = import ./modules/shared/desktop.nix;
        hyprvibe-hyprland = import ./modules/shared/hyprland.nix;
        hyprvibe-waybar = import ./modules/shared/waybar.nix;
        hyprvibe-shell = import ./modules/shared/shell.nix;
        hyprvibe-services = import ./modules/shared/services.nix;
      };

      nixosConfigurations = {
        rvbee = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/rvbee/system.nix
            prettyswitch.nixosModules.default
            freshrss-mcp.nixosModules.default
          ];
          specialArgs = {
            inherit self hyprland openclaw;
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
        nixbook = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixbook/system.nix
            prettyswitch.nixosModules.default
          ];
          specialArgs = {
            inherit hyprland;
          };
        };
      };
    };
}
