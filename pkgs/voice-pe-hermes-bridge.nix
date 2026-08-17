{
  ffmpeg,
  espeak-ng,
  python3Packages,
  symlinkJoin,
  writeShellScriptBin,
  writeShellApplication,
}:
let
  pythonEnv = python3Packages.python.withPackages (
    ps: with ps; [
      aioesphomeapi
      faster-whisper
      httpx
    ]
  );
  espeakTts = writeShellScriptBin "voice-pe-espeak-tts" ''
    set -euo pipefail
    if [ "''${1:-}" != "--output" ] || [ "$#" -ne 3 ]; then
      echo "Usage: voice-pe-espeak-tts --output OUTPUT.wav TEXT" >&2
      exit 2
    fi
    output="$2"
    text="$3"
    exec ${espeak-ng}/bin/espeak-ng -w "$output" "$text"
  '';
  bridge = writeShellApplication {
    name = "voice-pe-hermes-bridge";
    runtimeInputs = [ ffmpeg ];
    text = ''
      exec ${pythonEnv}/bin/python ${./voice-pe-hermes-bridge.py} "$@"
    '';
  };
in
symlinkJoin {
  name = "voice-pe-hermes-bridge-0.1.0";
  paths = [ bridge espeakTts ];
}
