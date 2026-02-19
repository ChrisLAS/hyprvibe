# Simplified gogcli overlay - receives gogcli-src directly
gogcli-src:
final: prev:
let
  src = gogcli-src;

  shortRev =
    if src ? shortRev then
      src.shortRev
    else if src ? rev then
      builtins.substring 0 7 src.rev
    else
      null;

  version =
    if src ? lastModifiedDate && shortRev != null then
      "0-unstable-${src.lastModifiedDate}-${shortRev}"
    else if shortRev != null then
      "0-unstable-${shortRev}"
    else
      "latest";
in
{
  gogcli = final.buildGoModule {
    pname = "gogcli";
    inherit version;

    src = src;

    # If this fails after updating `gogcli-src`, rebuild once and replace with the hash Nix reports.
    vendorHash = "sha256-jMvPQfh4E3EKzFqFxaNMq1Ae/ZXQvUU3eAZ0DqM7+hc=";

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/steipete/gogcli/cmd.Version=${version}"
    ];

    meta = with final.lib; {
      description = "CLI tool for GOG.com";
      homepage = "https://github.com/steipete/gogcli";
      license = licenses.mit;
      mainProgram = "gogcli";
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
}
