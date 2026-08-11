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
      install -Dm755 bin/opencode2 "$out/bin/opencode2"
      runHook postInstall
    '';

    meta = {
      description = "OpenCode 2 beta CLI";
      homepage = "https://opencode.ai";
      license = lib.licenses.mit;
      mainProgram = "opencode2";
      platforms = ["x86_64-linux"];
    };
  }
