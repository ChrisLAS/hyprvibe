# Dell XPS 14 DA14260 hardware improvements

Research and read-only baseline: 2026-11-12. This is a validation plan, not a claim every feature works.

## Priority 1: restore sound without sacrificing the camera
- Observed: Linux 7.3.1, Panther Lake audio 8086:e428, Dell SSID 1028:0db9; no ALSA cards.
- All four CS35L57 amplifier probes fail on speaker-ID GPIO with EBUSY.
- intel_cvs owns controller 1 pin 20 as wake; SOF 2.14.1.1 boots and matching 10280db9 amplifier firmware exists.
- Added a host-scoped kernel patch replacing the exclusive CVS wake GPIO request with ACPI IRQ lookup. Camera driver remains enabled.
- Patch applies without offsets to official v7.3.1; full kernel build and new boot required before calling this fixed.
- Preserve the previous boot generation. Do not unload the live camera stack or reboot implicitly.
- After boot: inspect /proc/asound/cards, amp probe/firmware logs, wpctl status; test speakers at low volume, headphone jack, microphone, camera, and suspend/resume.
- Never use another laptop's amplifier tuning files.

Patch source: https://gitlab.com/cki-project/kernel-ark/-/merge_requests/4744.diff
Exact regression: https://bugzilla.redhat.com/show_bug.cgi?id=2531233
History (including later regressions): https://bugzilla.redhat.com/show_bug.cgi?id=2529031
Cirrus safety/background: https://cdn.kernel.org/doc/html/latest/sound/codecs/cs35l56.html

## Priority 2: enable Arc B390 AI compute
- Verified Arc B390 8086:b080, xe kernel driver, Mesa 26.2.6 Vulkan hardware device.
- Added intel-compute-runtime 26.31.39395.13 and Level Zero loader 1.32.0 to hardware.graphics.extraPackages; clinfo to diagnostic tools.
- Tested the exact store runtime before activation: Intel Arc B390 enumerates as available, OpenCL 3.0 NEO, driver 26.31.039395.
- User chrisf already belongs to render and video; no permissions or access expansion needed.
- Runtime reports 28.62 GiB global/maximum allocation, but this is SHARED system memory, not dedicated VRAM. Machine has ~30 GiB usable RAM. Leave headroom for desktop, model context/KV cache and OS.
- No global allocation override, disabled mitigations/thermal protection, forced clocks, or permanent performance mode added.
- After new generation: run clinfo normally and verify Level Zero enumeration in the chosen framework. Runtime enumeration is not an inference benchmark.
- Candidate workloads: llama.cpp Vulkan (existing Mesa), llama.cpp SYCL (Intel Level Zero/oneAPI), OpenVINO GPU. Compare same model, quantization, context and batch on AC power; benchmark prompt processing AND generation, memory and thermals. Do not presume one backend fastest.
- Start with a modest quantized model; no model downloads or inference server were enabled automatically.
- NPU intel_vpu is bound and /dev/accel/accel0 exists, but NPU userspace/runtime and model support are separate work, not evidence of GPU acceleration.

Intel runtime support: https://github.com/intel/compute-runtime/releases/tag/26.31.39395.13
llama.cpp SYCL: https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/SYCL.md
llama.cpp backends: https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md
OpenVINO requirements: https://docs.openvino.ai/nightly/about-openvino/release-notes-openvino/system-requirements.html

## Priority 3: verify already configured modern features
- Camera: IPU7 8086:b05d firmware authenticates; ipu75xa platform enabled; video nodes present. Verify real capture after audio fix.
- Media: intel-media-driver already enabled. Verify VA-API encode/decode using an actual supported video; no evidence of missing graphics driver.
- Thunderbolt: driver and bolt configured; test dock, external screen and hotplug.
- Wi-Fi/Bluetooth: iwlwifi and btintel_pcie bound; verify Bluetooth audio and reconnection after suspend.
- Power: power-profiles-daemon, thermald and upower active; balanced profile. Intel pstate powersave still boosts. Use performance profile only for deliberate AC-powered tests; restore balanced afterward.
- Sleep: firmware exposes only s2idle. Do not force deep. Measure overnight/short controlled suspend drain before changing power policy.
- Firmware: fwupd active, BIOS 1.8.2 observed. Review official Dell/LVFS update applicability and release notes before any flash.
- Wi-Fi power saving stays disabled for reliability; reconsider only after battery measurement.
- Investigate recurring xe selective-fetch warnings or PipeWire crashes if they persist after audio fix; no speculative workarounds.

## Deferred and acceptance
Build success does not equal hardware success. Do not mark audio/camera/power acceptance complete without the tests above.
No BIOS flash, forced kernel downgrade, camera blacklist, live service restart, security setting change, or AI service was performed as part of this configuration.
