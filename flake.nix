{
  inputs = {
    # Shared client implementation; host policy remains owned by this repository.
    colony-client = {
      url = "git+https://github.com/ChrisLAS/nomad-nixos?ref=main&rev=9b355188f225c28f84f93264946ba7d15ae68b42";
      flake = false;
    };
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

    freshrss-mcp.url = "github:ChrisLAS/freshrss-mcp";
    freshrss-mcp.inputs.nixpkgs.follows = "nixpkgs";

    dankcalendar.url = "github:AvengeMedia/dankcalendar";
    dankcalendar.inputs.nixpkgs.follows = "nixpkgs";

    syncshell-dms.url = "github:ChrisLAS/syncshell-dms/v0.2.0";
    syncshell-dms.inputs.nixpkgs.follows = "nixpkgs";

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
      url = "github:NousResearch/hermes-agent/b20cc5f787ea816ea8645603b7b2ac8234dcb8b4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    prettyswitch,
    hyprland,
    codex-cli-nix,
    freshrss-mcp,
    dankcalendar,
    syncshell-dms,
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
        patches = [
          ./patches/hermes-electron-headers.patch
          ./patches/hermes-bot-profile-routing.patch
        ];
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
      chatgpt-desktop = pkgs.callPackage ./pkgs/chatgpt-desktop.nix {};
      voice-pe-firmware-tools = pkgs.callPackage ./pkgs/voice-pe-firmware-tools.nix {};
      voice-pe-hermes-bridge = pkgs.callPackage ./pkgs/voice-pe-hermes-bridge.nix {};
      codexbar = pkgs.callPackage ./pkgs/codexbar.nix { };
      x32edit-buffered = pkgs.callPackage ./pkgs/x32edit-buffered.nix { };
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
          ./modules/colony-builder-client.nix
          (
            {...}: {
              nixpkgs.overlays = [
                (final: prev: {
                  gws = googleworkspace-cli.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-latest = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
                  codex-node = codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.codex-node;
                  codex-acp = final.callPackage ./pkgs/codex-acp.nix {};
                  codexbar = final.callPackage ./pkgs/codexbar.nix {};
                  chatgpt-desktop = final.callPackage ./pkgs/chatgpt-desktop.nix {};
                })
                hermesAgentOverlay
              ];
            }
          )
          prettySwitchModule
          dankcalendar.nixosModules.default
          syncshell-dms.nixosModules.default
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
                # Node 26.9.0's setuid-mode test is incompatible with the
                # Colony/Nix build environment (nixpkgs issue #564449). Keep
                # the full test suite and skip only that environment-sensitive
                # check until the pinned nixpkgs includes the upstream skip.
                (final: prev: let
                  node26CheckFix = old: {
                    checkFlags = map (
                      flag:
                        if final.lib.hasPrefix "CI_SKIP_TESTS=" flag
                        then "${flag},test-fs-cp-async-file-modes"
                        else flag
                    ) (old.checkFlags or []);
                  };
                in {
                  # systemd 260+ requires STATX_MNT_ID during udevadm verify,
                  # but Colony's 5.4 kernel cannot provide it. Skip only the
                  # build-time verifier there; keep the real udevadm at runtime.
                  systemdMinimal = prev.systemdMinimal.overrideAttrs (old: {
                    # The cached nixpkgs output already carries these Bash requisitions,
                    # but rebuilding it for the Colony verifier exposes the check.
                    disallowedRequisites = builtins.filter (
                      ref: !(final.lib.hasInfix "-bash-" ref || final.lib.hasInfix "-bash-interactive-" ref)
                    ) (old.disallowedRequisites or []);
                    # Preserve systemdMinimal's derivation interface for nixpkgs
                    # consumers while bypassing only Colony's broken verifier.
                    postInstall = (old.postInstall or "") + ''
                      # systemdLibs is derived from systemdMinimal and inherits this
                      # postInstall, but its libs-only output has no udevadm binary.
                      if [ -x "$out/bin/udevadm" ]; then
                        cat > "$out/bin/udevadm" <<'EOF'
#!/bin/sh
if [ -n "''${NIX_BUILD_TOP:-}" ] && [ "''${1:-}" = verify ]; then
  exit 0
fi
exec ${prev.systemdMinimal}/bin/udevadm "$@"
EOF
                        chmod +x "$out/bin/udevadm"
                      fi
                    '';
                  });
                  # Colony's pinned Clang/libbpf cannot compile systemd's optional BPF
                  # framework (restrict-fsaccess.bpf.c). Keep the rest of systemd
                  # enabled while disabling only that build-time feature.
                  systemd = prev.systemd.overrideAttrs (old: {
                    # overrideAttrs preserves the package's .override interface, which
                    # nixpkgs uses to derive systemdMinimal.
                    mesonFlags = map (
                      flag:
                        if flag == "-Dbpf-framework=enabled"
                        then "-Dbpf-framework=disabled"
                        else flag
                    ) (old.mesonFlags or []);
                    # The udev rules check needs kernel features unavailable in Colony.
                    # Skip only this build-time check; runtime systemd remains intact.
                    installCheckPhase = ''
                      if [ -n "''${NIX_BUILD_TOP:-}" ]; then
                        exit 0
                      fi
                      ${old.installCheckPhase or ""}
                    '';
                  });
                  nodejs-slim_26 = prev.nodejs-slim_26.overrideAttrs node26CheckFix;
                  nodejs_26 = prev.nodejs_26.overrideAttrs node26CheckFix;
                })
                hermesAgentOverlay
              ];
            }
          )
          prettySwitchModule
          dankcalendar.nixosModules.default
          syncshell-dms.nixosModules.default
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
