{config, pkgs, ...}: let
  # Explicit video-only setup: programs.droidcam also loads snd-aloop, which
  # would add an unnecessary sound card to the existing meeting audio setup.
  iphoneWebcam = pkgs.writeShellApplication {
    name = "droidcam-iphone";
    runtimeInputs = [pkgs.droidcam];
    text = ''
      if [[ ! -c /dev/video10 ]]; then
        echo "iPhone Webcam is unavailable: the v4l2loopback driver is not loaded." >&2
        exit 1
      fi
      if [[ ! -S /run/usbmuxd ]]; then
        echo "iPhone USB service is unavailable: check usbmuxd.service." >&2
        exit 1
      fi
      echo "Open DroidCam on your USB-connected iPhone and trust this computer."
      echo "Video: 1920x1080; select 30 FPS in the phone app. Audio stays unchanged."
      echo "In Firefox select iPhone Webcam. Press Ctrl-C here to stop the camera."
      exec droidcam-cli -v -nocontrols -dev=/dev/video10 -size=1920x1080 ios 4747
    '';
  };
in {
  environment.systemPackages = [
    pkgs.droidcam
    pkgs.v4l-utils
    pkgs.libimobiledevice
    iphoneWebcam
    (pkgs.makeDesktopItem {
      name = "droidcam-iphone";
      desktopName = "iPhone Webcam (USB)";
      comment = "Use the iPhone camera in meetings at 1080p over USB";
      exec = "${iphoneWebcam}/bin/droidcam-iphone";
      icon = "camera-web";
      terminal = true;
      categories = ["AudioVideo" "Video"];
    })
  ];

  services.usbmuxd.enable = true;
  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="iPhone Webcam" exclusive_caps=1
  '';
}
