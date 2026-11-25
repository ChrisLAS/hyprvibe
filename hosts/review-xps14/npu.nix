{ pkgs, ... }:
let
  # Isolate the upstream compiler and OpenVINO loader fixes from the shared
  # Hyprvibe pin. Remove this pin after the main nixpkgs input includes them.
  npuSource = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/d4f25a3e562008648d45bcf2d70bcc7422cad84e.tar.gz";
    sha256 = "sha256-x9sADJvoVG0L6RejZB+/BB4YiGZFBZrfTlhF4uBq1tQ=";
  };
  npuPkgs = import npuSource { system = pkgs.stdenv.hostPlatform.system; };
  npuPython = npuPkgs.python3.withPackages (ps: [ ps.numpy ps.openvino ]);
in
{
  nixpkgs.overlays = [ (_final: _prev: { intel-npu-driver = npuPkgs.intel-npu-driver; }) ];
  hardware.cpu.intel.npu.enable = true;
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "review-xps14-npu-check" ''
      exec ${npuPython}/bin/python ${./npu-check.py} "$@"
    '')
  ];
}
