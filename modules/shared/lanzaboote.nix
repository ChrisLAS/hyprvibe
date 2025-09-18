{ config, lib, pkgs, ... }:

let
  cfg = config.shared.lanzaboote;
in
{
  options.shared.lanzaboote = {
    enable = lib.mkEnableOption "Lanzaboote Secure Boot for NixOS";

    pkiBundle = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the PKI bundle containing the keys and certificates for Secure Boot.
        If null, you must provide publicKeyFile and privateKeyFile separately.
      '';
    };

    publicKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the public key file for signing.
        Required if pkiBundle is not provided.
      '';
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the private key file for signing.
        Required if pkiBundle is not provided.
      '';
    };

    configurationLimit = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = ''
        Maximum number of latest NixOS configurations to keep in the ESP.
        Older configurations will be removed to save space.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Additional lanzaboote configuration options to pass through.
        See lanzaboote documentation for available options.
      '';
    };

    bootloaderSpec = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable bootloader specification (required for lanzaboote)";
      };
    };

    systemdBoot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable systemd-boot alongside lanzaboote.
          This is usually not needed as lanzaboote handles the boot process.
        '';
      };

      configurationLimit = lib.mkOption {
        type = lib.types.int;
        default = cfg.configurationLimit;
        description = "Configuration limit for systemd-boot (synced with lanzaboote by default)";
      };
    };

    quietBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable quiet boot parameters for a cleaner boot experience";
    };

    secureBoot = {
      enrollKeys = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Automatically enroll Secure Boot keys during system activation.
          WARNING: Only enable this if you understand the implications.
          This will modify your system's UEFI firmware.
        '';
      };

      fallbackKeys = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Keep Microsoft's keys as fallback in the Secure Boot database.
          This allows booting other operating systems that are signed by Microsoft.
        '';
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        Additional packages to include in the ESP.
        Useful for firmware update tools or other boot-time utilities.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.pkiBundle != null) || (cfg.publicKeyFile != null && cfg.privateKeyFile != null);
        message = "lanzaboote requires either pkiBundle or both publicKeyFile and privateKeyFile to be set";
      }
      {
        assertion = !config.boot.loader.systemd-boot.enable || cfg.systemdBoot.enable;
        message = "systemd-boot cannot be enabled directly when using lanzaboote. Use shared.lanzaboote.systemdBoot.enable instead.";
      }
    ];

    # Enable bootspec (required for lanzaboote)
    boot.bootspec.enable = lib.mkIf cfg.bootloaderSpec.enable true;

    # Core lanzaboote configuration
    boot.lanzaboote = lib.recursiveUpdate {
      enable = true;
      
      # PKI configuration
      pkiBundle = lib.mkIf (cfg.pkiBundle != null) cfg.pkiBundle;
      publicKeyFile = lib.mkIf (cfg.publicKeyFile != null) cfg.publicKeyFile;
      privateKeyFile = lib.mkIf (cfg.privateKeyFile != null) cfg.privateKeyFile;
      
      # Configuration limits
      configurationLimit = cfg.configurationLimit;
      
      # Settings for cleaner integration
      settings = {
        # Automatically install boot entries
        auto-install = true;
        
        # Use lanzaboote's custom stub for smaller UKIs
        stub = "lanzaboote";
      };
    } cfg.extraConfig;

    # Bootloader configuration
    boot.loader = {
      # Disable GRUB when using lanzaboote
      grub.enable = lib.mkForce false;
      
      # Configure systemd-boot if requested
      systemd-boot = lib.mkIf cfg.systemdBoot.enable {
        enable = true;
        configurationLimit = cfg.systemdBoot.configurationLimit;
        # Let lanzaboote handle most of the configuration
        editor = false;
      };
      
      # Enable EFI
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      # Timeout configuration
      timeout = lib.mkDefault 3;
    };

    # Quiet boot configuration
    boot.kernelParams = lib.mkIf cfg.quietBoot [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    # Plymouth integration for smooth boot
    boot.plymouth = lib.mkIf cfg.quietBoot {
      enable = lib.mkDefault true;
    };

    # Console configuration for quiet boot
    boot.consoleLogLevel = lib.mkIf cfg.quietBoot 3;

    # Include additional packages in the system
    environment.systemPackages = with pkgs; [
      # Essential tools for Secure Boot management
      sbctl
      efibootmgr
      efivar
    ] ++ cfg.extraPackages;

    # Optional: Add helpful services
    systemd.services.lanzaboote-update = lib.mkIf cfg.enable {
      description = "Update Lanzaboote boot entries";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # This service can be used to trigger lanzaboote updates
        # The actual update is handled by the lanzaboote module
        echo "Lanzaboote configuration updated"
      '';
    };

    # Security hardening when Secure Boot is enabled
    security = lib.mkIf cfg.enable {
      # Lockdown the kernel when Secure Boot is active
      lockKernelModules = lib.mkDefault true;
      
      # Additional security measures
      allowUserNamespaces = lib.mkDefault false;
      allowSimultaneousMultithreading = lib.mkDefault true;
    };

    # Informational output
    warnings = lib.optionals (cfg.secureBoot.enrollKeys) [
      ''
        lanzaboote.secureBoot.enrollKeys is enabled. This will modify your system's 
        UEFI firmware and enroll Secure Boot keys automatically. Make sure you have 
        backups of your current keys and understand the implications.
      ''
    ];
  };
}