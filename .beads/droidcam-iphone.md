# Nixvader iPhone DroidCam — USB1080p30 capture verified

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
- **Build routing:** Colony failed before compilation because its selector rejects
  the udev-rules recipe. Its normalized SHA256 is identical to the previous
  staged candidate (2fd598a455d34746e9b561c5adac14a628c7afb5d39228487b94b0e5371d1bec).
  Chris explicitly approved the guided owner-local one-job/two-core override.
  No shared builder policy was modified or failed Colony job replayed.
- **Validated/published/staged:** first build44fd0fa passed. Preserved concurrent
  origin60498e6 docs via rebase; candidate1fae7bfa6386785b690428edcb52e75b2536c3a2
  validated, published and boot-stage VERIFIED on local route, output
  `/nix/store/zm0n8pkc41b380nsh42smpm9m9djn1s4-nixos-system-nixvader-26.11.20260917.e554fab`.
  Fleet88bfe58583076c8cf81c0f228f2cbf3fb5d3ac1796150f04c04b32e4868b55b9,
  live_activation_performed=false. Per-command Git helper override reused existing
  gh auth because ~/.gitconfig references a missing old helper store path; no
  credential rotation/config edit. Current source adds reusable on-demand user
  unit; its final receipt/output must be checked before linking/staging it.
- **Scoped live bring-up:** created only declared usbmux system account/group;
  installed Apple-only group rule in `/run/udev/rules.d/90-droidcam-iphone.rules`;
  loaded exact-kernel v4l2loopback with declared options; runtime-linked generated
  usbmuxd unit (resolve the generated symlink with readlink -f before linking).
  Initial udev trigger was asynchronous; after permission settled, one targeted
  usbmuxd restart detected the already-trusted phone. Pairing validates. Local
  pairing material stays under /var/lib/lockdown, never copied to source/chat.
- **Capture evidence:** foreground helper running in a manually started user
  service; /dev/video10 YU12/I4201920x1080,30fps. v4l2 capture received60frames
  at30.15fps to /dev/null. Isolated real Firefox156 profile captured camera label
  iPhone Webcam,1920x1080/30fps,4.30seconds and5distinct/nonblack image samples;
  no images saved and no user tabs/profile changed. Headless compositor counter
  stays0, so changing decoded pixels established real frames instead. Initial
  pre-capture enumeration labels were privacy-hidden; isolated exact real-device
  name filter plus camera permission resolved the test, not a fake stream.
- **Runtime boundaries:** /run/current-system and /run/booted-system still b5bd9aq,
  kernel unchanged. DMS/PipeWire/WirePlumber not restarted. No audio loopback,
  firewall/network change, full switch, notification activation or reboot.
- **Remaining delivery:** validate/publish/stage the on-demand user unit, replace
  only our transient capture service with its generated runtime-linked unit,
  retest restart/capture and compare baseline service PIDs. Final usage:
  `systemctl --user start|stop droidcam-iphone`; select iPhone Webcam in Firefox.
  Meeting-site transmission resolution and app HD-watermark entitlement are not
  proven by the local capture test; no purchase authorized.
