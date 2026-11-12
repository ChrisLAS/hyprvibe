{ self, nixpkgs, hyprland }:
let
  installed = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit self; };
    modules = [
      hyprland.nixosModules.default
      self.inputs.sops-nix.nixosModules.sops
      ./system.nix
      {
        # The entire built client is carried in the RAM installer. No build,
        # source download, or connection to another builder is needed after wiping.
        system.build.reviewInstaller = installer.config.system.build.kexecTree;
      }
    ];
  };
  installer = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      targetSystem = installed.config.system.build.toplevel;
      sourceTree = self.outPath;
    };
    modules = [ ./installer.nix ];
  };
in
installed
