{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "herdr-agent-icons-max";
  version = "1.3.0-unstable-2026-08-20";

  src = fetchFromGitHub {
    owner = "qintmb";
    repo = "herdr-icon-agent-ui";
    rev = "6bd682d5bfba1482380fecbb7da2375e95e5512d";
    hash = "sha256-Ab8NWk2VTMj4maKfAQCa7wuKv9vOeRmGlIsrWk5wrMg=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 dist/HerdrAgentIconsMax-Regular.ttf \
      "$out/share/fonts/truetype/HerdrAgentIconsMax-Regular.ttf"
    runHook postInstall
  '';
}
