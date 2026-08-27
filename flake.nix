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

    dankcalendar.url = "github:AvengeMedia/dankcalendar";
    dankcalendar.inputs.nixpkgs.follows = "nixpkgs";

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

    # Hermes Desktop is built during nixos-rebuild instead of at launch.
    hermes-agent = {
      url = "github:NousResearch/hermes-agent/v2026.8.27";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    prettyswitch,
    hyprland,
    codex-cli-nix,
    chatgpt-linux-metadata,
    freshrss-mcp,
    dankcalendar,
    sops-nix,
    nixos-hardware,
    googleworkspace-cli,
    gogcli-src,
    hermes-agent,
    ...
  }: let
    prettySwitchModule = {pkgs, ...}: {
      environment.systemPackages = [
        prettyswitch.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
    hermesAgentOverlay = final: prev: let
      hermesSource = final.applyPatches {
        src = hermes-agent;
        name = "hermes-agent-electron-headers-fixed";
        patches = [ ./patches/hermes-electron-headers.patch ];
      };
      hermesMinimal =
        (builtins.getAttr prev.stdenv.hostPlatform.system hermes-agent.packages).minimal.override {
          callPackage = path: args:
            if builtins.baseNameOf (toString path) == "desktop.nix" then
              final.callPackage (hermesSource + "/nix/desktop.nix") args
            else
              final.callPackage path args;
        };
      hermesLocalStub = final.writeShellScriptBin "hermes" ''
        echo "This Hermes Desktop installation is configured for a remote backend." >&2
        exit 1
      '';
      # Upstream retains its local agent through the desktop wrapper's fallback.
      # Replace only that reference while preserving the renderer dependencies.
      hermesDesktop = hermesMinimal.hermesDesktop.overrideAttrs (old: {
        installPhase = let
          original = old.installPhase;
          replaced = builtins.replaceStrings
            [(final.lib.getExe hermesMinimal)]
            [(final.lib.getExe hermesLocalStub)]
            original;
          context = removeAttrs (builtins.getContext original) [
            (builtins.unsafeDiscardStringContext hermesMinimal.drvPath)
          ];
        in
          builtins.appendContext (builtins.unsafeDiscardStringContext replaced) context;
        postInstall = (old.postInstall or "") + ''
          sed -i "s|^export HERMES_DESKTOP_HERMES=.*|export HERMES_DESKTOP_HERMES='${final.lib.getExe hermesLocalStub}'|" "$out/bin/hermes-desktop"
          chmod u+w "$out/share/hermes-desktop/dist/electron-main.mjs"
          chmod u+w "$out/share/hermes-desktop/dist"
          sed -i 's#if (opts.globalRemote || opts.profileRemoteOverride)#if (opts.profileRemoteOverride)#' "$out/share/hermes-desktop/dist/electron-main.mjs"
        '';
      });
    in {
      hermes-desktop = hermesDesktop;
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
      voice-pe-firmware-tools = pkgs.callPackage ./pkgs/voice-pe-firmware-tools.nix {};
      voice-pe-hermes-bridge = pkgs.callPackage ./pkgs/voice-pe-hermes-bridge.nix {};
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
                  codexbar = final.callPackage ./pkgs/codexbar.nix {};
                })
                hermesAgentOverlay
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
                  codexbar = final.callPackage ./pkgs/codexbar.nix {};
                  chatgpt-desktop = final.callPackage ./pkgs/chatgpt-desktop.nix {
                    repositoryMetadata = chatgpt-linux-metadata;
                  };
                })
                hermesAgentOverlay
              ];
            }
          )
          prettySwitchModule
          dankcalendar.nixosModules.default
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
                  codexbar = final.callPackage ./pkgs/codexbar.nix {};
                })
                hermesAgentOverlay
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
                  codexbar = final.callPackage ./pkgs/codexbar.nix {};
                })
                hermesAgentOverlay
              ];
            }
          )
          prettySwitchModule
          dankcalendar.nixosModules.default
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
