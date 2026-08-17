{
  ffmpeg,
  espeak-ng,
  python3Packages,
  stdenv,
  symlinkJoin,
  writeShellScriptBin,
  writeShellApplication,
  zlib,
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
  neuttsLibraryPath = "${stdenv.cc.cc.lib}/lib:${zlib}/lib";
  neuttsServer = writeShellScriptBin "voice-pe-neutts-server" ''
    set -euo pipefail
    exec env LD_LIBRARY_PATH="${neuttsLibraryPath}:''${LD_LIBRARY_PATH:-}" \
      "''${VOICE_PE_NEUTTS_PYTHON:-/home/chrisf/.local/share/voice-pe/neutts-venv/bin/python}" \
      ${./voice-pe-neutts.py} --server "$@"
  '';
  neuttsTts = writeShellScriptBin "voice-pe-neutts-tts" ''
    set -euo pipefail
    if [ "''${1:-}" != "--output" ] || [ "$#" -ne 3 ]; then
      echo "Usage: voice-pe-neutts-tts --output OUTPUT.wav TEXT" >&2
      exit 2
    fi
    exec env LD_LIBRARY_PATH="${neuttsLibraryPath}:''${LD_LIBRARY_PATH:-}" \
      "''${VOICE_PE_NEUTTS_PYTHON:-/home/chrisf/.local/share/voice-pe/neutts-venv/bin/python}" \
      ${./voice-pe-neutts.py} --client --output "$2" "$3"
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
  paths = [ bridge espeakTts neuttsServer neuttsTts ];
}
