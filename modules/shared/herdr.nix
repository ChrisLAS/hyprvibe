{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hyprvibe.herdr;
  user = config.hyprvibe.user;
  iconFont = pkgs.callPackage ../../pkgs/herdr-agent-icons-max.nix {};
  herdrPackage = pkgs.callPackage ../../pkgs/herdr.nix {};
  ghosttyBlock = ''
    # BEGIN HYPRVIBE HERDR
    font-family = "${cfg.ghostty.primaryFont}"
    font-family = "Herdr Agent Icons Max"
    font-codepoint-map = U+E1A0-U+E1B0="Herdr Agent Icons Max"
    # END HYPRVIBE HERDR
  '';
in {
  options.hyprvibe.herdr = {
    enable = lib.mkEnableOption "Herdr remote workspace client";
    ghostty.primaryFont = lib.mkOption {
      type = lib.types.str;
      default = "Fira Code";
      description = "Primary Ghostty font retained ahead of the Herdr icon fallback";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = herdrPackage.version == "0.9.0";
        message = "The Herdr client pilot is reviewed and pinned for Herdr 0.9.0.";
      }
    ];

    environment.systemPackages = [herdrPackage];
    fonts.packages = [iconFont];

    systemd.user.services.hyprvibe-setup-herdr = {
      description = "Hyprvibe: configure Ghostty for Herdr agent icons";
      unitConfig.ConditionUser = user.name;
      wantedBy = ["default.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprvibe-setup-herdr" ''
          set -euo pipefail
          config_dir=${lib.escapeShellArg "${user.home}/.config/ghostty"}
          config_file="$config_dir/config"
          temporary="$config_dir/.config-herdr.$$"
          install -d -m 0755 "$config_dir"
          ${pkgs.gawk}/bin/awk '
            /^# BEGIN HYPRVIBE HERDR$/ { managed = 1; next }
            /^# END HYPRVIBE HERDR$/ { managed = 0; next }
            !managed && /^[[:space:]]*$/ { pending = pending $0 ORS; next }
            !managed { printf "%s", pending; pending = ""; print }
          ' "$config_file" 2>/dev/null > "$temporary" || true
          if [ -s "$temporary" ]; then
            printf '\n' >> "$temporary"
          fi
          cat >> "$temporary" <<'EOF'
          ${ghosttyBlock}
          EOF
          install -m 0644 "$temporary" "$config_file"
          rm -f "$temporary"
        '';
      };
    };
  };
}
