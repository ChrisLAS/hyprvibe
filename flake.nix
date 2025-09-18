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

  outputs = { self, nixpkgs, prettyswitch, hyprland, ... }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Formatter (optional)
    formatter.${system} = pkgs.alejandra;

    # Development shell with comprehensive tooling
    devShells.${system}.default = pkgs.mkShell {
      name = "hyprvibe-dev";
      
      buildInputs = with pkgs; [
        # Nix development tools
        nixos-rebuild
        nix-tree
        nix-index
        nix-prefetch-git
        nix-update
        
        # System management
        home-manager
        direnv
        nix-direnv
        
        # Build and packaging tools
        git
        gh
        gnumake
        gcc
        
        # Configuration validation
        alejandra          # Nix formatter
        deadnix           # Find dead Nix code
        statix            # Nix linter
        
        # System utilities
        htop
        tree
        jq
        yq-go
        fd
        ripgrep
        fzf
        
        # Hyprland development
        wayland-protocols
        wayland-utils
        wlr-randr
        
        # Scripting and automation
        bash
        python3
        
        # Documentation
        pandoc
        mdbook
      ];
      
      shellHook = ''
        echo "🚀 HyprVibe Development Environment"
        echo "   • NixOS Configuration Management"
        echo "   • Hyprland Wayland Compositor Setup"
        echo ""
        echo "Available commands:"
        echo "   • nixos-rebuild build --flake .#<host>   - Build configuration"
        echo "   • nixos-rebuild switch --flake .#<host>  - Apply configuration"
        echo "   • nix flake check                        - Validate flake"
        echo "   • alejandra .                            - Format Nix code"
        echo "   • deadnix .                              - Find dead code"
        echo "   • statix check .                         - Lint Nix code"
        echo ""
        echo "Hosts: rvbee, nixstation"
        echo ""
        
        # Set up development environment
        export NIXOS_CONFIG_DIR="$PWD"
        export FLAKE_DIR="$PWD"
        
        # Ensure direnv is available
        if command -v direnv >/dev/null 2>&1; then
          echo "✅ direnv is available"
        else
          echo "⚠️  direnv not found in PATH"
        fi
        
        # Check if we're in a git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
          echo "📂 Git repository: $(git branch --show-current)"
        fi
        
        # Development aliases
        alias build="nixos-rebuild build --flake ."
        alias switch="sudo nixos-rebuild switch --flake ."
        alias test="sudo nixos-rebuild test --flake ."
        alias check="nix flake check"
        alias fmt="alejandra ."
        alias lint="statix check ."
        alias dead="deadnix ."
        alias update="nix flake update"
        
        echo "🔧 Development aliases loaded: build, switch, test, check, fmt, lint, dead, update"
      '';
      
      # Environment variables for development
      NIX_CONFIG = "experimental-features = nix-command flakes";
    };

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
    };
  };
}
