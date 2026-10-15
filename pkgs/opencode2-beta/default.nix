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
    pname = "opencode2";
    inherit (source) version;

    src = fetchurl {
      inherit (source) url hash;
    };

    sourceRoot = "package";
    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [glibc];
    dontBuild = true;

    # The executable is a Bun standalone binary. Stripping it removes the
    # appended OpenCode application payload and leaves only the Bun runtime.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      # Upstream names the binary opencode; keep the explicit V2 command.
      # The host supplies the opencode compatibility launcher.
      install -Dm755 bin/opencode "$out/bin/opencode2"
      runHook postInstall
    '';

    passthru.sourceMetadata = source;

    meta = {
      description = "OpenCode 2 stable CLI and server";
      homepage = "https://opencode.ai/v2/docs/";
      license = lib.licenses.mit;
      mainProgram = "opencode2";
      platforms = ["x86_64-linux"];
    };
  }
