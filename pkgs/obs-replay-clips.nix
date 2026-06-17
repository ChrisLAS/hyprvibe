{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  ffmpeg-full,
}:

stdenvNoCC.mkDerivation {
  pname = "obs-replay-clips";
  version = "0.1.0";

  src = ../scripts/obs-replay-clips;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 obs_replay_clip_helper.py "$out/libexec/obs-replay-clips/obs_replay_clip_helper.py"
    install -Dm644 obs_replay_clipper.lua "$out/share/obs-replay-clips/obs_replay_clipper.lua"

    makeWrapper ${lib.getExe python3} "$out/bin/obs-replay-clip-helper" \
      --add-flags "$out/libexec/obs-replay-clips/obs_replay_clip_helper.py" \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-full ]}

    runHook postInstall
  '';

  meta = {
    description = "Local OBS replay-buffer clipping helper and Lua hotkey script";
    platforms = lib.platforms.linux;
  };
}
