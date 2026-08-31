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
  version = "0.10.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "IlyasKhallouki";
    repo = "hypruse";
    rev = "v${version}";
    hash = "sha256-H7cIaLmvxKYuCad3KWwdSoMCtfKcc0JI3m+2FfyoDBo=";
  };

  build-system = [python3Packages.hatchling];
  dependencies = [python3Packages.mcp];
  nativeBuildInputs = [makeWrapper];
  nativeCheckInputs = [python3Packages.pytestCheckHook];

  postInstall = ''
    wrapProgram "$out/bin/hypruse" \
      --prefix PATH : ${lib.makeBinPath [hyprland grim wtype systemd imagemagick]}
  '';

  postCheck = ''
    journal="$TMPDIR/journal.ndjson"
    HYPRUSE_JOURNAL="$journal" HYPRUSE_JOURNAL_TEXT=0 \
      ${python3Packages.python.interpreter} - <<'PY'
    import json
    import os
    from hypruse import journal

    @journal.journaled("act")
    def keyboard(text):
        return "ok"

    keyboard("hypruse-redaction-check")
    entry = json.loads(open(os.environ["HYPRUSE_JOURNAL"]).readline())
    assert entry["args"]["text"] == {
        "redacted": True,
        "chars": 23,
        "sha256": "5292adf67c65",
    }
    PY
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
