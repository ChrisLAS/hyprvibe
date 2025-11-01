{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.shell;
  user = config.hyprvibe.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
in {
  options.hyprvibe.shell = {
    enable = lib.mkEnableOption "Fish + Oh My Posh + Atuin basics";
    kittyAsDefault = lib.mkEnableOption "Set kitty as default terminal and env";
    ohMyPoshDefault = lib.mkOption {
      type = lib.types.lines;
      default = ''{"$schema":"https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json","version":1,"final_space":true,"blocks":[]}'';
      description = "Default OMP config JSON when user config is missing";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    environment.systemPackages = [ pkgs.oh-my-posh ];

    system.activationScripts.shell = lib.mkAfter ''
      mkdir -p ${userHome}/.config/fish/conf.d
      # Minimal, conservative grc integration for Fish
      cat > ${userHome}/.config/fish/conf.d/grc.fish << 'EOF'
      if set -q GRC_DISABLE
        exit
      end
      if not command -q grc
        exit
      end
      function __grc_wrap
        grc $argv
      end
      set -l __grc_targets diff dig ip last mount netstat ping ping6 ps traceroute traceroute6
      for t in $__grc_targets
        alias $t "__grc_wrap $t"
      end
      EOF
      cat > ${userHome}/.config/fish/conf.d/oh-my-posh.fish << 'EOF'
      if command -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
      end
      EOF
      # Ensure ~/.local/bin is on PATH
      cat > ${userHome}/.config/fish/conf.d/local-bin.fish << 'EOF'
      if test -d "$HOME/.local/bin"
        fish_add_path "$HOME/.local/bin"
      end
      EOF
      mkdir -p ${userHome}/.config/oh-my-posh
      # Only create default config if no config.json exists (preserve user configs)
      if [ ! -f ${userHome}/.config/oh-my-posh/config.json ]; then
        echo '${cfg.ohMyPoshDefault}' > ${userHome}/.config/oh-my-posh/config-default.json
        cp ${userHome}/.config/oh-my-posh/config-default.json ${userHome}/.config/oh-my-posh/config.json
      fi
      chown -R ${userName}:${userGroup} ${userHome}/.config/fish ${userHome}/.config/oh-my-posh
    '';

    environment.sessionVariables = lib.mkIf cfg.kittyAsDefault {
      TERMINAL = "kitty";
      KITTY_CONFIG_DIRECTORY = "~/.config/kitty";
      KITTY_SHELL_INTEGRATION = "enabled";
    };
  };
}


