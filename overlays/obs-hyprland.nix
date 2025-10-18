final: prev:
let
  lib = prev.lib;
in
{
  obs-hyprland = prev.stdenv.mkDerivation rec {
    pname = "obs-hyprland";
    # Pin a known good commit; update as needed
    version = "unstable-2025-10-01";

    src = prev.fetchFromGitHub {
      owner = "hyprwm";
      repo = "obs-hyprland";
      # TODO: consider pinning to a release/tag when available
      rev = "master";
      sha256 = lib.fakeSha256; # replace with prefetch
    };

    nativeBuildInputs = with prev; [ cmake pkg-config ninja ];
    buildInputs = with prev; [ obs-studio hyprland wlroots libdrm libxkbcommon wayland wayland-protocols ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
    ];

    # Standard out path structure for OBS plugins in Nix
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/obs-plugins" "$out/share/obs/obs-plugins/obs-hyprland/locale"
      # The plugin .so usually lands under build dir named like obs-hyprland.so
      find . -name '*.so' -maxdepth 2 -print -exec cp -v {} "$out/lib/obs-plugins/" \;
      # If the project provides data/locale, install it
      if [ -d "data" ]; then
        cp -vr data/* "$out/share/obs/obs-plugins/obs-hyprland/" || true
      fi
      runHook postInstall
    '';

    meta = with lib; {
      description = "OBS Studio source plugin for Hyprland capture";
      homepage = "https://github.com/hyprwm/obs-hyprland";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = [];
    };
  };
}


