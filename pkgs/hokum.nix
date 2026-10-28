{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libxkbcommon,
  wayland,
  vulkan-loader,
  fontconfig,
  xdg-utils,
  wl-clipboard,
}:
stdenvNoCC.mkDerivation rec {
  pname = "hokum";
  version = "0.1.1";

  # Stable upstream artifact, not the mutable Anomaly release-channel URL.
  src = fetchurl {
    url = "https://github.com/anomalyco/hokum/releases/download/v${version}/hokum-${version}-linux-x64";
    hash = "sha256-BaYiAhyQwqDgyN7USzTtm7NKehAmwP9ivFiCy4bQZC8=";
  };
  dontUnpack = true;
  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [stdenv.cc.cc.lib libxkbcommon];
  # Rune loads these dynamically rather than declaring ELF NEEDED entries.
  runtimeDependencies = [wayland vulkan-loader fontconfig];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/hokum"
    mkdir -p "$out/share/applications" "$out/share/dbus-1/services"
    cat > "$out/share/applications/hokum.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=Hokum
    GenericName=Notification Settings
    Comment=Style and configure your notifications
    Exec=$out/bin/hokum
    Icon=preferences-desktop-notification
    Terminal=false
    Categories=Settings;DesktopSettings;
    Keywords=notifications;notification;daemon;do not disturb;
    EOF
    cat > "$out/share/dbus-1/services/app.hokum.Notifications.service" <<EOF
    [D-BUS Service]
    Name=org.freedesktop.Notifications
    Exec=$out/bin/hokum service
    SystemdService=hokum.service
    EOF
    wrapProgram "$out/bin/hokum" \
      --prefix PATH : ${lib.makeBinPath [xdg-utils wl-clipboard]} \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
    runHook postInstall
  '';

  meta = {
    description = "Wayland notification daemon drawn with Rune";
    homepage = "https://github.com/anomalyco/hokum";
    license = lib.licenses.mit;
    mainProgram = "hokum";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
}
