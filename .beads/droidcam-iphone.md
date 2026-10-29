# Nixvader iPhone DroidCam — implementation in progress

- **Request:** USB iPhone webcam for Firefox, target1080p30; avoid reboot.
- **Approval:** Chris said “Ok lets do it” after the explicit proposal to install
  DroidCam, enable iPhone USB support, load the camera driver live and test Firefox.
  No reboot, purchases, broad input updates, audio rerouting or notification-shell
  migration activation. Keep existing physical webcams.
- **Ownership:** `hosts/nixvader/droidcam.nix`, imported by system.nix; usage in
  `docs/DROIDCAM.md`. Main checkout initially clean/current with origin5c81a5d.
- **Tracker blocker:** installed bd1.3.0 refuses remote-backed schema v32→v66
  migration; read-only list also fails on missing leases. No migration/bootstrap
  authorized or performed. This handoff follows existing .beads Markdown practice.
- **Verified baseline:** running/current/configured kernel7.2.6-zen2 same exact
  identity; chrisf in video group; driver/client absent; usbmuxd disabled. iPhone
  visible on USB. PipeWire/WirePlumber/DMS active; Hokum inactive. No kernel,
  session, network or audio changes made during research.
- **Important discovery:** current source includes a not-yet-live Hokum/DMS
  migration with boot-only approval. Do NOT full-switch source to enable webcam.
  Build/stage durable config and bring up only webcam prerequisites for this
  session; record live changes and retain the active desktop generation.
- **Implementation:** video-only client; v4l2loopback /dev/video10 labeled
  iPhone Webcam/exclusive_caps1; usbmuxd; foreground droidcam-iphone helper and
  terminal desktop launcher,1080p request/no audio.30fps is selected in phone app.
- **Admission:** target-scoped Colony probe idle for Nomad/Nixvader/Colony;
  no active build and Matrix healthy before source work.
- **Next:** evaluate/assert source, commit intended files, guided validate/build
  on Colony, review closure/service diff, publish, boot-stage without reboot;
  bounded current-session setup then actual USB/frame/Firefox checks. No build,
  staging, live changes or phone capture verified yet.
