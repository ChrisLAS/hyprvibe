{inputs, ...}: {
  imports = [(inputs.colony-client + "/modules/colony-builder-client.nix")];

  # Explicit submissions are planned on Nomad. Ordinary builds remain local.
  services.colony-builder-client.mode = "coordinator";
}
