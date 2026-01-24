{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hyprvibe.shell;
  user = config.hyprvibe.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
in
{
  options.hyprvibe.shell = {
    enable = lib.mkEnableOption "Fish + Oh My Posh + Atuin basics";
    kittyAsDefault = lib.mkEnableOption "Set kitty as default terminal and env";
    atuin.enable = lib.mkEnableOption "Enable Atuin integration snippet for Fish";
    githubToken.enable = lib.mkEnableOption "Export GITHUB_TOKEN from ~/.config/secrets/github_token in Fish";
    kittyIntegration.enable = lib.mkEnableOption "Enable kitty shell integration snippet in Fish";
    kittyConfig.enable = lib.mkEnableOption "Write a shared kitty.conf to the user's config";
    ohMyPoshDefault = lib.mkOption {
      type = lib.types.lines;
      default = ''
        {
          "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
          "version": 3,
          "final_space": true,
          "blocks": [
            {
              "type": "prompt",
              "alignment": "left",
              "segments": [
                { "type": "root", "style": "powerline", "background": "#ffe9aa", "foreground": "#100e23", "powerline_symbol": "\ue0b0", "template": " \uf0e7 " },
                { "type": "session", "style": "powerline", "background": "#ffffff", "foreground": "#100e23", "powerline_symbol": "\ue0b0", "template": " {{ .UserName }}@{{ .HostName }} " },
                { "type": "path", "style": "powerline", "background": "#91ddff", "foreground": "#100e23", "powerline_symbol": "\ue0b0", "properties": { "style": "agnoster", "max_depth": 2, "max_width": 50, "folder_icon": "\uf115", "home_icon": "\ueb06", "folder_separator_icon": " \ue0b1 " }, "template": " {{ .Path }} " },
                { "type": "git", "style": "powerline", "background": "#95ffa4", "background_templates": [ "{{ if or (.Working.Changed) (.Staging.Changed) }}#FF9248{{ end }}", "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#ff4500{{ end }}", "{{ if gt .Ahead 0 }}#B388FF{{ end }}", "{{ if gt .Behind 0 }}#B388FF{{ end }}" ], "foreground": "#193549", "powerline_symbol": "\ue0b0", "properties": { "fetch_status": true, "fetch_upstream": true, "fetch_upstream_icon": true, "display_stash_count": true, "branch_template": "{{ trunc 25 .Branch }}" }, "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} " },
                { "type": "node", "style": "powerline", "background": "#6CA35E", "foreground": "#ffffff", "powerline_symbol": "\ue0b0", "properties": { "fetch_version": true, "display_mode": "files" }, "template": " \ue718 {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} " },
                { "type": "python", "style": "powerline", "background": "#FFDE57", "foreground": "#111111", "powerline_symbol": "\ue0b0", "properties": { "fetch_virtual_env": true, "display_version": true, "display_mode": "files" }, "template": " \ue235 {{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }} " },
                { "type": "go", "style": "powerline", "background": "#8ED1F7", "foreground": "#111111", "powerline_symbol": "\ue0b0", "properties": { "fetch_version": true, "display_mode": "files" }, "template": " \ue626 {{ .Full }} " },
                { "type": "rust", "style": "powerline", "background": "#FF9E64", "foreground": "#111111", "powerline_symbol": "\ue0b0", "properties": { "fetch_version": true, "display_mode": "files" }, "template": " \ue7a8 {{ .Full }} " },
                { "type": "docker_context", "style": "powerline", "background": "#7aa2f7", "foreground": "#1a1b26", "powerline_symbol": "\ue0b0", "properties": { "display_default": false }, "template": " \uf308 {{ .Context }} " },
                { "type": "execution_time", "style": "powerline", "background": "#9aa5ce", "foreground": "#1a1b26", "powerline_symbol": "\ue0b0", "properties": { "threshold": 5000, "style": "text" }, "template": " {{ .FormattedMs }} " },
                { "type": "exit", "style": "powerline", "background": "#f7768e", "foreground": "#ffffff", "powerline_symbol": "\ue0b0", "properties": { "display_exit_code": true, "error_color": "#f7768e", "success_color": "#9ece6a" }, "template": " {{ if gt .Code 0 }}\uf071 {{ .Code }}{{ end }} " }
              ]
            },
            {
              "type": "rprompt",
              "segments": [
                { "type": "text", "style": "plain", "properties": { "text": " " } },
                { "type": "time", "style": "plain", "foreground": "#9aa5ce", "background": "#1a1b26", "properties": { "time_format": "15:04", "display_date": false }, "template": " {{ .CurrentDate | date .Format }} " }
              ]
            }
          ]
        }
      '';
      description = "Default OMP config JSON when user config is missing";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    environment.systemPackages = [ pkgs.oh-my-posh ];

    # Move shell setup to systemd --user oneshot
    systemd.user.services.hyprvibe-setup-shell = {
      description = "Hyprvibe: setup shell config in user home";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprvibe-setup-shell" ''
                    set -euo pipefail
                    echo "[hyprvibe][shell] starting user setup"
                    mkdir -p ${userHome}/.config/fish/conf.d ${userHome}/.config/oh-my-posh ${userHome}/.config/secrets
                    # Purge stale Oh My Posh cached init scripts so store path doesn't go stale across generations
                    rm -rf ${userHome}/.cache/oh-my-posh 2>/dev/null || true
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
          set -gx OMP_CONFIG "$HOME/.config/oh-my-posh/config.json"
          if set -q XDG_CACHE_HOME
            set -gx POSH_CACHE_DIR "$XDG_CACHE_HOME/oh-my-posh"
          else
            set -gx POSH_CACHE_DIR "$HOME/.cache/oh-my-posh"
          end
          if command -q oh-my-posh
            if test -r "$OMP_CONFIG"
              oh-my-posh init fish --config "$OMP_CONFIG" | source
            else
              oh-my-posh init fish | source
            end
          end
          EOF
                    cat > ${userHome}/.config/fish/conf.d/local-bin.fish << 'EOF'
          if test -d "$HOME/.local/bin"
            fish_add_path "$HOME/.local/bin"
          end
          EOF
          ${lib.optionalString (cfg.atuin.enable or false) ''
                        cat > ${userHome}/.config/fish/conf.d/atuin.fish << 'EOF'
            if command -q atuin
              set -g ATUIN_SESSION (atuin uuid)
              atuin init fish | source
            end
            EOF
          ''}
          ${lib.optionalString (cfg.githubToken.enable or false) ''
                        cat > ${userHome}/.config/fish/conf.d/github_token.fish << 'EOF'
            if test -r ~/.config/secrets/github_token
              set -gx GITHUB_TOKEN (string trim (cat ~/.config/secrets/github_token))
            end
            EOF
          ''}
          ${lib.optionalString ((cfg.kittyIntegration.enable or false) || (cfg.kittyAsDefault or false)) ''
                          cat > ${userHome}/.config/fish/conf.d/kitty-integration.fish << 'EOF'
            if test "$TERM" = "xterm-kitty"
              if command -q kitty
                kitty + complete setup fish | source
              end
            end
            EOF
          ''}
                    if [ ! -f ${userHome}/.config/oh-my-posh/config.json ]; then
                      echo '${cfg.ohMyPoshDefault}' > ${userHome}/.config/oh-my-posh/config-default.json
                      cp ${userHome}/.config/oh-my-posh/config-default.json ${userHome}/.config/oh-my-posh/config.json
                    fi
                    echo "[hyprvibe][shell] user setup complete"
        '';
      };
    };

    environment.sessionVariables = lib.mkIf cfg.kittyAsDefault {
      TERMINAL = "kitty";
      KITTY_CONFIG_DIRECTORY = "~/.config/kitty";
      KITTY_SHELL_INTEGRATION = "enabled";
    };

    # Move kitty config write to user oneshot as well
    systemd.user.services.hyprvibe-setup-kitty = lib.mkIf (cfg.kittyConfig.enable or false) {
      description = "Hyprvibe: write kitty.conf in user home";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprvibe-setup-kitty" ''
          set -euo pipefail
          echo "[hyprvibe][shell][kitty] writing kitty.conf"
          mkdir -p ${userHome}/.config/kitty
          cat > ${userHome}/.config/kitty/kitty.conf << 'EOF'
          # Hyprvibe Kitty Terminal Configuration
          font_family FiraCode Nerd Font
          font_size 12
          bold_font auto
          italic_font auto
          bold_italic_font auto
          background #1a1b26
          foreground #c0caf5
          selection_background #28344a
          selection_foreground #c0caf5
          url_color #7aa2f7
          cursor #c0caf5
          cursor_text_color #1a1b26
          active_tab_background #7aa2f7
          active_tab_foreground #1a1b26
          inactive_tab_background #1a1b26
          inactive_tab_foreground #c0caf5
          tab_bar_background #16161e
          window_padding_width 10
          window_margin_width 0
          window_border_width 0
          background_opacity 0.95
          shell_integration enabled
          copy_on_select yes
          detect_urls yes
          show_hyperlink_targets yes
          underline_hyperlinks always
          mouse_hide_while_typing yes
          focus_follows_mouse yes
          sync_to_monitor yes
          repaint_delay 10
          input_delay 3
          map ctrl+shift+equal change_font_size all +1.0
          map ctrl+shift+minus change_font_size all -1.0
          map ctrl+shift+0 change_font_size all 0
          shell fish
          enable_audio_bell no
          visual_bell_duration 0.5
          visual_bell_color #f7768e
          cursor_shape beam
          cursor_beam_thickness 2
          scrollback_lines 10000
          scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
          clipboard_control write-clipboard write-primary read-clipboard read-primary
          EOF
          echo "[hyprvibe][shell][kitty] wrote kitty.conf"
        '';
      };
    };
  };
}
