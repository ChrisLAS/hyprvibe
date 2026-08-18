{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgsPgsearch.url = "github:nixos/nixpkgs/c8c34e946ef639a0e1e7ddfc3f3aac1cfecb43a9";
    # musnix.url = "github:musnix/musnix";
    # musnix.inputs.nixpkgs.follows = "nixpkgs";
    # companion.url = "github:noblepayne/bitfocus-companion-flake";
    # companion.inputs.nixpkgs.follows = "nixpkgs";

    prettyswitch.url = "github:noblepayne/pretty-switch";
    prettyswitch.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    codex-cli-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Qwen3.8 GGUFs were produced with llama.cpp b10430. Pin the matching
    # upstream Vulkan build until support has reached the nixpkgs package.
    llama-cpp.url = "github:ggml-org/llama.cpp/b10430";
    llama-cpp.inputs.nixpkgs.follows = "nixpkgs";

    # OpenAI's stable Linux package index. Keeping this as a locked file input
    # lets `nix flake update` advance ChatGPT with the rest of the system.
    chatgpt-linux-metadata = {
      url = "file+https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages";
      flake = false;
    };

    freshrss-mcp.url = "github:ChrisLAS/freshrss-mcp";
    freshrss-mcp.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    googleworkspace-cli.url = "github:googleworkspace/cli";
    googleworkspace-cli.inputs.nixpkgs.follows = "nixpkgs";

    # gogcli - GOG CLI tool
    # Note: pinning to v0.11.0 tag to avoid unstable main branch
    gogcli-src.url = "github:steipete/gogcli/v0.11.0";
    gogcli-src.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    prettyswitch,
    hyprland,
    codex-cli-nix,
    chatgpt-linux-metadata,
    freshrss-mcp,
    sops-nix,
    nixos-hardware,
    googleworkspace-cli,
    gogcli-src,
    ...
  }: let
    prettySwitchModule = {pkgs, ...}: {
      environment.systemPackages = [
        prettyswitch.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  in {
    # Formatter (optional)
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    # Packages
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [
          (import ./overlays/gogcli.nix gogcli-src)
          (final: prev: {
            gws = googleworkspace-cli.packages.${prev.stdenv.hostPlatform.system}.default;
            codex-latest = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
            codex-node = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.codex-node;
            codex-acp = final.callPackage ./pkgs/codex-acp.nix {};
          })
        ];
      };
    in {
      gogcli = pkgs.gogcli;
      gws = pkgs.gws;
      chatgpt-desktop = pkgs.callPackage ./pkgs/chatgpt-desktop.nix {
        repositoryMetadata = chatgpt-linux-metadata;
      };
      codexbar = pkgs.callPackage ./pkgs/codexbar.nix { };
    };

    nixosModules = {
      # New hyprvibe-prefixed exports
      hyprvibe = import ./modules/shared;
      hyprvibe-packages = import ./modules/shared/packages.nix;
      hyprvibe-desktop = import ./modules/shared/desktop.nix;
      hyprvibe-hyprland = import ./modules/shared/hyprland.nix;
      hyprvibe-waybar = import ./modules/shared/waybar.nix;
      hyprvibe-shell = import ./modules/shared/shell.nix;
      hyprvibe-services = import ./modules/shared/services.nix;
      hyprvibe-syncthing = import ./modules/shared/syncthing.nix;
    };

    nixosConfigurations = {
      rvbee = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/rvbee/system.nix
          ./hosts/rvbee/ai-memory-stack.nix
          # Shared overlays for custom flake packages
          (
            {...}: {
              nixpkgs.overlays = [
                (import ./overlays/gogcli.nix gogcli-src)
                (final: prev: {
                  gws = googleworkspace-cli.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-latest = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-node = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.codex-node;
                  codex-acp = final.callPackage ./pkgs/codex-acp.nix {};
                })
              ];
            }
          )
          prettySwitchModule
          freshrss-mcp.nixosModules.default
          sops-nix.nixosModules.sops
        ];
        specialArgs = {
          inherit self hyprland;
          inputs = self.inputs;
        };
      };
      nixstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixstation/system.nix
          (
            {...}: {
              nixpkgs.overlays = [
                (final: prev: {
                  gws = googleworkspace-cli.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-latest = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-node = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.codex-node;
                  codex-acp = final.callPackage ./pkgs/codex-acp.nix {};
                  chatgpt-desktop = final.callPackage ./pkgs/chatgpt-desktop.nix {
                    repositoryMetadata = chatgpt-linux-metadata;
                  };
                })
              ];
            }
          )
          prettySwitchModule
          sops-nix.nixosModules.sops
        ];
        specialArgs = {
          inherit hyprland;
          inherit self;
          inputs = self.inputs;
        };
      };
      nixbook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixbook/system.nix
          (
            {...}: {
              nixpkgs.overlays = [
                (final: prev: {
                  gws = googleworkspace-cli.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-latest = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-node = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.codex-node;
                  codex-acp = final.callPackage ./pkgs/codex-acp.nix {};
                })
              ];
            }
          )
          prettySwitchModule
          sops-nix.nixosModules.sops
        ];
        specialArgs = {
          inherit hyprland;
        };
      };
      nixvader = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixvader/system.nix
          nixos-hardware.nixosModules.dell-latitude-7490
          (
            {...}: {
              nixpkgs.overlays = [
                (import ./overlays/gogcli.nix gogcli-src)
                (final: prev: {
                  gws = googleworkspace-cli.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-latest = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-node = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.codex-node;
                  codex-acp = final.callPackage ./pkgs/codex-acp.nix {};
                })
              ];
            }
          )
          prettySwitchModule
          sops-nix.nixosModules.sops
        ];
        specialArgs = {
          inherit self hyprland;
          inputs = self.inputs;
        };
      };
    };
  };
}
