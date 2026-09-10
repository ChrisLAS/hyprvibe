{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v0.9.0/herdr-linux-x86_64";
    hash = "sha256-T6GgEVjdgEPaktMbJweAsNzBBgMDjZthysTYGrY/tx8=";
  };

  dontUnpack = true;
  nativeBuildInputs = [installShellFiles];

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
    install -Dm644 <("$out/bin/herdr" --skill) \
      "$out/share/herdr/skills/herdr/SKILL.md"
    installShellCompletion --cmd herdr \
      --bash <("$out/bin/herdr" completion bash) \
      --fish <("$out/bin/herdr" completion fish) \
      --zsh <("$out/bin/herdr" completion zsh)
  '';

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    mainProgram = "herdr";
    platforms = ["x86_64-linux"];
  };
}
