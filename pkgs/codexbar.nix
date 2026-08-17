{
  lib,
  stdenvNoCC,
  fetchurl,
  bash,
}:
# Pin to upstream `master`. When the upstream script changes, refresh the hash:
#   nix-prefetch-url --type sha256 https://raw.githubusercontent.com/mryll/codexbar/master/codexbar
stdenvNoCC.mkDerivation {
  pname = "codexbar";
  version = "0.0.0-unstable-master-2026-08-17";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/mryll/codexbar/master/codexbar";
    sha256 = "1plz28l11qj7rcgfakmckaz8nkk5ib81ryyngyq1ybqr2pn78hhx";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/codexbar
    substituteInPlace $out/bin/codexbar \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Waybar widget for OpenAI Codex CLI usage limits";
    longDescription = ''
      Pure-bash Waybar widget that displays OpenAI Codex subscription usage
      (session, weekly, code review, credits) with colored progress bars,
      countdown timers, and pacing indicators. Reads OAuth credentials from
      ~/.codex/auth.json (created by `codex login`).
    '';
    homepage = "https://github.com/mryll/codexbar";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "codexbar";
  };
}
