{ inputs, pkgs, ... }:
let
  upstream = inputs.hedgedoc-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
  launcher = pkgs.writeShellScriptBin "zed-hedgedoc-mcp" ''
    exec ${pkgs.python3}/bin/python3 ${./hedgedoc-mcp-launcher.py} ${upstream}/bin/hedgedoc-mcp
  '';
in
{
  environment.systemPackages = [ upstream launcher ];
}
