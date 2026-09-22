{inputs, config, ...}: {
  imports = [(inputs.colony-client + "/modules/colony-builder-client.nix")];

  # Explicit submissions are planned on Nomad. Ordinary builds remain local.
  services.colony-builder-client.mode = "coordinator";
  services.colony-builder-client.desktopBootloader =
    if config.networking.hostName == "nixstation" then "grub"
    else if config.networking.hostName == "nixvader" then "systemd-boot"
    else null;
}
