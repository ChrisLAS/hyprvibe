{ lib, pkgs, config, ... }:
let cfg = config.shared.stylix;
in {
  options.shared.stylix = {
    enable = lib.mkEnableOption "Stylix system theming";
    
    autoEnable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically enable all targets for programs found on the system";
    };
    
    image = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper image to generate theme from";
    };
    
    base16Scheme = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = "Base16 color scheme to use instead of generating from image";
    };
    
    polarity = lib.mkOption {
      type = lib.types.enum [ "light" "dark" "either" ];
      default = "dark";
      description = "Whether to use light or dark variant of the theme";
    };
    
    cursor = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.bibata-cursors;
        description = "Cursor theme package";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Bibata-Modern-Classic";
        description = "Cursor theme name";
      };
      size = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Cursor size";
      };
    };
    
    fonts = {
      serif = lib.mkOption {
        type = lib.types.attrs;
        default = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        description = "Serif font configuration";
      };
      sansSerif = lib.mkOption {
        type = lib.types.attrs;
        default = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        description = "Sans-serif font configuration";
      };
      monospace = lib.mkOption {
        type = lib.types.attrs;
        default = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans Mono";
        };
        description = "Monospace font configuration";
      };
      emoji = lib.mkOption {
        type = lib.types.attrs;
        default = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
        description = "Emoji font configuration";
      };
      sizes = {
        applications = lib.mkOption {
          type = lib.types.int;
          default = 12;
          description = "Application font size";
        };
        terminal = lib.mkOption {
          type = lib.types.int;
          default = 12;
          description = "Terminal font size";
        };
        desktop = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Desktop font size";
        };
        popups = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Popup font size";
        };
      };
    };
    
    opacity = {
      applications = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Opacity for applications";
      };
      desktop = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Opacity for desktop";
      };
      popups = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Opacity for popups";
      };
      terminal = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Opacity for terminal";
      };
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional Stylix configuration options to pass through";
    };
  };

  config = lib.mkIf cfg.enable {
    stylix = lib.recursiveUpdate {
      enable = true;
      autoEnable = cfg.autoEnable;
      
      # Image or base16 scheme
      image = lib.mkIf (cfg.image != null) cfg.image;
      base16Scheme = lib.mkIf (cfg.base16Scheme != null) cfg.base16Scheme;
      
      polarity = cfg.polarity;
      
      # Cursor configuration
      cursor = {
        package = cfg.cursor.package;
        name = cfg.cursor.name;
        size = cfg.cursor.size;
      };
      
      # Font configuration
      fonts = {
        serif = cfg.fonts.serif;
        sansSerif = cfg.fonts.sansSerif;
        monospace = cfg.fonts.monospace;
        emoji = cfg.fonts.emoji;
        
        sizes = {
          applications = cfg.fonts.sizes.applications;
          terminal = cfg.fonts.sizes.terminal;
          desktop = cfg.fonts.sizes.desktop;
          popups = cfg.fonts.sizes.popups;
        };
      };
      
      # Opacity configuration
      opacity = {
        applications = cfg.opacity.applications;
        desktop = cfg.opacity.desktop;
        popups = cfg.opacity.popups;
        terminal = cfg.opacity.terminal;
      };
    } cfg.extraConfig;
  };
}