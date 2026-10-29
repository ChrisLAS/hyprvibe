# Nixvader iPhone webcam

Source: `hosts/nixvader/droidcam.nix`, imported by the Nixvader system only.
Uses the native classic DroidCam client with the standard kernel-matched
v4l2loopback driver. No OBS, audio loopback, firewall changes or automatic
camera capture. Existing microphone/headset and physical webcams stay intact.

## Use

1. Install **DroidCam Webcam & OBS Camera** on the iPhone. The iOS app supports
   both classic and new desktop clients. Removing the HD watermark requires Pro;
   no purchase is made by the host setup.
2. Connect a USB data cable, unlock the phone and approve **Trust This Computer**
   if prompted. Open DroidCam, leave it open, use port **4747** (the default),
   landscape orientation, and choose **30 FPS** in its camera settings.
3. Launch **iPhone Webcam (USB)** from the app launcher, or run
   `droidcam-iphone` in a terminal. It requests **1920x1080** video only.
4. In Firefox grant the meeting site camera access and select **iPhone Webcam**.
   Keep your normal microphone selected separately. Start DroidCam before opening
   the camera picker: exclusive-caps mode exposes a capture camera only while a
   producer is connected. Refresh the meeting tab/picker if necessary.
5. Press **Ctrl-C** in the launcher terminal to stop camera transmission.

The virtual camera is `/dev/video10`; it does not replace `/dev/video0`–`3`.
1080p input does not guarantee 1080p meeting transmission: the service may cap it.
If performance is poor, stop capture and use the lower-resolution command:

```console
droidcam-cli -v -dev=/dev/video10 -size=1280x720 ios 4747
```

## Checks

```console
systemctl status usbmuxd --no-pager
v4l2-ctl --list-devices
v4l2-ctl -d /dev/video10 --get-fmt-video --get-parm
```

Do not publish `idevice_id`, pairing records or full usbmuxd logs: they can
contain phone identifiers. `/var/lib/lockdown` contains local pairing material,
not repository content. Do not reset phone trust/privacy settings as a routine fix.

## Deployment

Commit source, use `nixvader-update validate`, review `diff`, promote/push the
validated candidate, then explicitly stage with `nixvader-update boot`. Never
refresh flake inputs or reboot as an incidental part of this setup.

A live driver must match `uname -r` exactly. Before any full live switch, review
unrelated staged changes; the 2026-10-29 setup deliberately avoids activating the
pending Hokum/DMS migration. A narrowly scoped current-session bring-up may use
the validated driver/client/service store paths without switching the full
system. Record exactly what was loaded/started in `.beads/droidcam-iphone.md`.
The staged generation owns the permanent packages, usbmuxd user/service, udev
permissions and module options after the next operator-chosen reboot.

## References

- https://www.dev47apps.com/droidcam/linux/
- https://droidcam.app/help/ (iOS client compatibility and USB setup)
- https://github.com/umlaeute/v4l2loopback#options
