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
      set -euo pipefail
      trap 'echo "[hyprvibe][shell] ERROR at line $LINENO"' ERR
      echo "[hyprvibe][shell] starting activation"
      mkdir -p ${userHome}/.config/fish/conf.d
      # Minimal, conservative grc integration for Fish
      cat > ${userHome}/.config/fish/conf.d/grc.fish << 'EOF'
      if not set -q GRC_DISABLE; and command -q grc
        function __grc_wrap
          grc $argv
        end
        set -l __grc_targets diff dig ip last mount netstat ping ping6 ps traceroute traceroute6
        for t in $__grc_targets
          alias $t "__grc_wrap $t"
        end
      end
      EOF
      cat > ${userHome}/.config/fish/conf.d/oh-my-posh.fish << 'EOF'
      if command -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
      end
      if not functions -q fish_prompt
        function fish_prompt
          set_color cyan
          echo -n (whoami)'@'(hostname)' > '
          set_color normal
        end
      end
      EOF
      # Ensure ~/.local/bin is on PATH
      cat > ${userHome}/.config/fish/conf.d/local-bin.fish << 'EOF'
      if test -d "$HOME/.local/bin"
        fish_add_path "$HOME/.local/bin"
      end
      EOF
      echo "[hyprvibe][shell] wrote fish conf.d snippets"
      mkdir -p ${userHome}/.config/oh-my-posh
      # Only create default config if no config.json exists (preserve user configs)
      if [ ! -f ${userHome}/.config/oh-my-posh/config.json ]; then
        echo '${cfg.ohMyPoshDefault}' > ${userHome}/.config/oh-my-posh/config-default.json
        cp ${userHome}/.config/oh-my-posh/config-default.json ${userHome}/.config/oh-my-posh/config.json
        echo "[hyprvibe][shell] installed default oh-my-posh config"
      fi
      chown -R ${userName}:${userGroup} ${userHome}/.config/fish ${userHome}/.config/oh-my-posh
      echo "[hyprvibe][shell] activation complete"
    '';

    environment.sessionVariables = lib.mkIf cfg.kittyAsDefault {
      TERMINAL = "kitty";
      KITTY_CONFIG_DIRECTORY = "~/.config/kitty";
      KITTY_SHELL_INTEGRATION = "enabled";
    };
  };
}


