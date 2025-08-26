{ lib, pkgs, config, ... }:
let cfg = config.shared.shell;
in {
  options.shared.shell = {
    enable = lib.mkEnableOption "Fish + Oh My Posh + Atuin basics";
  };

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    environment.systemPackages = [ pkgs.oh-my-posh ];

    system.activationScripts.shell = lib.mkAfter ''
      mkdir -p /home/chrisf/.config/fish/conf.d
      cat > /home/chrisf/.config/fish/conf.d/oh-my-posh.fish << 'EOF'
      if command -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
      end
      EOF
      # Ensure ~/.local/bin is on PATH
      cat > /home/chrisf/.config/fish/conf.d/local-bin.fish << 'EOF'
      if test -d "$HOME/.local/bin"
        fish_add_path "$HOME/.local/bin"
      end
      EOF
      mkdir -p /home/chrisf/.config/oh-my-posh
      cat > /home/chrisf/.config/oh-my-posh/config-default.json << 'EOF'
      {"$schema":"https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json","version":1,"final_space":true,"blocks":[]}
      EOF
      [ -f /home/chrisf/.config/oh-my-posh/config.json ] || cp /home/chrisf/.config/oh-my-posh/config-default.json /home/chrisf/.config/oh-my-posh/config.json
      chown -R chrisf:users /home/chrisf/.config/fish /home/chrisf/.config/oh-my-posh
    '';
  };
}


