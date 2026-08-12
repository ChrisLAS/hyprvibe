{
  lib,
  stdenv,
  stdenvNoCC,
  buildFHSEnv,
  fetchurl,
  dpkg,
  patchelf,
  repositoryMetadata,
}: let
  metadataLines = lib.splitString "\n" (builtins.readFile repositoryMetadata);
  getField = field:
    lib.removePrefix "${field}: " (
      lib.findFirst
      (line: lib.hasPrefix "${field}: " line)
      (throw "OpenAI Linux package metadata is missing ${field}")
      metadataLines
    );

  version = getField "Version";
  filename = getField "Filename";
  sha256 = getField "SHA256";

  unpacked = stdenvNoCC.mkDerivation {
    pname = "chatgpt-desktop-unpacked";
    inherit version;

    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/${filename}";
      inherit sha256;
    };

    nativeBuildInputs = [
      dpkg
      patchelf
    ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir source "$out"
      dpkg-deb -x "$src" source
      cp -r source/usr/* "$out/"

      # Chrome starts this copied native-messaging host outside the app's FHS
      # environment, so it needs a NixOS interpreter and runtime search path.
      extension_host="$out/lib/chatgpt/resources/plugins/openai-bundled/plugins/chrome/extension-host/linux/x64/extension-host"
      if [ ! -x "$extension_host" ]; then
        echo "ChatGPT Chrome extension host not found at $extension_host" >&2
        exit 1
      fi
      patchelf \
        --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
        --set-rpath ${lib.makeLibraryPath [stdenv.cc.cc.lib stdenv.cc.libc]} \
        "$extension_host"

      substituteInPlace "$out/share/applications/chatgpt.desktop" \
        --replace-fail "Exec=chatgpt %U" "Exec=chatgpt-desktop %U"

      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    pname = "chatgpt-desktop";
    inherit version;

    targetPkgs = pkgs:
      with pkgs; [
        unpacked
        alsa-lib
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        gdk-pixbuf
        git
        glib
        gtk3
        libdrm
        libgbm
        libGL
        libnotify
        libsecret
        libusb1
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        nspr
        nss
        openssl
        pango
        stdenv.cc.cc.lib
        systemd
        xdg-utils
        zlib
      ];

    runScript = "/lib/chatgpt/ChatGPT";

    extraInstallCommands = ''
      cp -r ${unpacked}/share "$out/share"
    '';

    passthru = {
      inherit repositoryMetadata unpacked;
      updateCommand = "nix flake update chatgpt-linux-metadata";
    };

    meta = {
      description = "Official ChatGPT and Codex desktop application";
      homepage = "https://developers.openai.com/codex/app";
      license = lib.licenses.unfree;
      mainProgram = "chatgpt-desktop";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
