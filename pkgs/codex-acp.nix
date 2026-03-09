{
  lib,
  stdenv,
  fetchurl,
  gnutar,
  gzip,
  bash,
  codex-latest ? null,
}:

let
  version = "0.9.5";

  platformMap = {
    "x86_64-linux" = {
      asset = "codex-acp-0.9.5-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-Se9IGniDY4SkwKqZSs85gixUnvD6INTWEM4ALjuYCOA=";
    };
  };

  release = platformMap.${stdenv.hostPlatform.system} or (throw "codex-acp is not packaged for ${stdenv.hostPlatform.system} in this repo");
in
stdenv.mkDerivation {
  pname = "codex-acp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/zed-industries/codex-acp/releases/download/v${version}/${release.asset}";
    hash = release.hash;
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    gnutar
    gzip
  ];

  unpackPhase = ''
    runHook preUnpack
    mkdir -p source
    tar -xzf "$src" -C source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 source/codex-acp "$out/bin/codex-acp-raw"
    cat > "$out/bin/codex-acp" <<EOF
#!${bash}/bin/bash
${lib.optionalString (codex-latest != null) "export PATH=${codex-latest}/bin:\$PATH"}
exec "$out/bin/codex-acp-raw" "\$@"
EOF
    chmod +x "$out/bin/codex-acp"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ACP adapter for OpenAI Codex CLI";
    homepage = "https://github.com/zed-industries/codex-acp";
    license = licenses.asl20;
    platforms = builtins.attrNames platformMap;
    mainProgram = "codex-acp";
  };
}
