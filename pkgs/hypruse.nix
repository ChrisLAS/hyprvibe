{
  lib,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  hyprland,
  grim,
  wtype,
  systemd,
  imagemagick,
}:
python3Packages.buildPythonApplication rec {
  pname = "hypruse";
  version = "0.9.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "IlyasKhallouki";
    repo = "hypruse";
    rev = "v${version}";
    hash = "sha256-EImqcmN4xmjHIcpNkyOyd5NOpIOdDbptqtK2ka5RFxE=";
  };

  build-system = [python3Packages.hatchling];
  dependencies = [python3Packages.mcp];
  nativeBuildInputs = [makeWrapper];
  nativeCheckInputs = [python3Packages.pytestCheckHook];

  postInstall = ''
    wrapProgram "$out/bin/hypruse" \
      --prefix PATH : ${lib.makeBinPath [hyprland grim wtype systemd imagemagick]}
  '';

  pythonImportsCheck = ["hypruse"];

  meta = {
    description = "Computer use for Hyprland over MCP";
    homepage = "https://github.com/IlyasKhallouki/hypruse";
    license = lib.licenses.mit;
    mainProgram = "hypruse";
    platforms = lib.platforms.linux;
  };
}
