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
    sha256 = "sha256-eZToejGv4+rFsHFAk7n7GXUmM83vtP/9hTNOGH2Ouio=";
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
    # wrapProgram rewrites the existing script's shebang and prepends runtime
    # tools to its PATH lookup. Do not move or rename the binary; codexbar is
    # invoked by Waybar as `codexbar` and must remain at $out/bin/codexbar.
    wrapProgram "$out/bin/codexbar" \
      --prefix PATH : "${lib.makeBinPath [ bash coreutils curl gnused jq util-linux ]}"
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
