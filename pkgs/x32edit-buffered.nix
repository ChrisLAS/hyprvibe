{
  alsa-lib,
  makeWrapper,
  stdenv,
  symlinkJoin,
  x32edit,
}:
let
  socketBufferShim = stdenv.mkDerivation {
    pname = "x32edit-socket-buffer";
    version = "1";

    src = ./x32edit-socket-buffer.c;
    dontUnpack = true;

    buildPhase = ''
      runHook preBuild
      $CC -shared -fPIC -O2 -Wall -Wextra -Werror \
        -o libx32edit-socket-buffer.so "$src"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 libx32edit-socket-buffer.so \
        "$out/lib/libx32edit-socket-buffer.so"
      runHook postInstall
    '';
  };
in
symlinkJoin {
  name = "x32-edit-buffered-${x32edit.version}";
  paths = [ x32edit ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram "$out/bin/x32-edit" \
      --set ALSA_CONFIG_PATH "${alsa-lib}/share/alsa/alsa.conf" \
      --prefix LD_PRELOAD : "${socketBufferShim}/lib/libx32edit-socket-buffer.so"
  '';

  meta = x32edit.meta // {
    description = "${x32edit.meta.description} with a JUCE startup deadlock workaround";
    mainProgram = "x32-edit";
  };
}
