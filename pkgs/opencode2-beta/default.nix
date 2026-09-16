{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  glibc,
}: let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
  stdenvNoCC.mkDerivation {
    pname = "opencode2-beta";
    inherit (source) version;

    src = fetchurl {
      inherit (source) url hash;
    };
    sourceRoot = "package";

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [glibc];

    dontBuild = true;
    # The executable contains an embedded Bun payload after the ELF data.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      # Stable V2 ships bin/opencode. Keep the repository's explicit
      # opencode2 command so OpenCode 1 remains available as opencode.
      install -Dm755 bin/opencode "$out/bin/opencode2"
      runHook postInstall
    '';

    meta = {
      description = "OpenCode 2 stable CLI";
      homepage = "https://opencode.ai/v2/docs/";
      license = lib.licenses.mit;
      mainProgram = "opencode2";
      platforms = ["x86_64-linux"];
    };
  }
