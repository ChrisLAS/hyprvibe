{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
, bash
, coreutils
, curl
, gnused
, jq
, util-linux
}:

let
  version = "0.1.0-unstable-2026-08-18";
  src = fetchurl {
    url = "https://raw.githubusercontent.com/mryll/codexbar/master/codexbar";
    sha256 = "sha256-HUJ07BUZLx+wf9b7HNCKZU6LvpqsTuUey0fiECgSn94=";
  };
in
stdenvNoCC.mkDerivation {
  inherit version;
  pname = "codexbar";
  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm0755 "$src" "$out/bin/codexbar"
    mv "$out/bin/codexbar" "$out/bin/.codexbar-unwrapped"
    makeWrapper "$out/bin/.codexbar-unwrapped" "$out/bin/codexbar" \
      --prefix PATH : "${lib.makeBinPath [ bash coreutils curl gnused jq util-linux ]}"
    rm "$out/bin/.codexbar-unwrapped"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Waybar widget for OpenAI Codex CLI usage limits";
    homepage = "https://github.com/mryll/codexbar";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "codexbar";
  };
}
