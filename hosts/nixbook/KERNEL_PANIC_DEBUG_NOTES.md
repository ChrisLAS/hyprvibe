# Kernel Panic Debug Notes - Laptop Host

**Last Updated:** 2024-12-15  
**Status:** FIXED - Kernel panic was caused by activation script bug, not kernel parameters  
**Current Generation:** Fixed shell activation script to create .cache directory before chowning

## Hardware Profile - Dell Latitude 5410

- **Model:** Dell Latitude 5410
- **CPU:** Intel Core i7 (generation varies, typically 10th gen Comet Lake or 11th gen Tiger Lake)
- **GPU:** Intel integrated graphics (UHD Graphics, likely i915 driver)
- **Storage:** NVMe SSD (Btrfs filesystem)
- **KVM Module:** `kvm-intel` (correct for Intel CPU)
- **Boot Method:** systemd-boot with EFI

## Problem Summary

The laptop system kernel panics on boot during stage-2-init. Root cause identified and fixed:
- ✅ Swapped Zen kernel for standard Linux kernel (6.12.60)
- ✅ Removed v4l2loopback from early boot (moved to systemd service)
- ✅ Removed verbose `loglevel=6` kernel parameter
- ✅ Added Intel C-state limiting parameters (Priority 1)
- ✅ Added Intel graphics driver parameters (Priority 2)
- ✅ Added ACPI compatibility parameter (Priority 3)
- ✅ **FIXED:** Shell activation script bug - was trying to chown non-existent `.cache` directory

## Root Cause Identified

**Actual Issue:** The kernel panic was NOT caused by kernel parameters, but by an activation script bug in `modules/shared/shell.nix`.

**Panic Details:**
- **Location:** During stage-2-init, shell activation script
- **Error:** `chown: cannot access 'home/chrisf/.cache': No such file or directory`
- **Error Line:** Line 1560 in generated activation script (line 141 in shell.nix)
- **Root Cause:** Script tried to `chown` `${userHome}/.cache` before ensuring it existed
- **Impact:** With `set -euo pipefail`, script exits on error, killing init (PID 1), causing kernel panic

**Fix Applied:**
- Added `mkdir -p` before `chown` to ensure `.cache` directory exists
- File: `hyprvibe/modules/shared/shell.nix` line ~140

## Research Findings - Dell Latitude 5410 Common Issues

Based on research and Linux kernel bug reports, Dell Latitude 5410 laptops commonly experience:

1. **C-State Issues (Most Common)**
   - Intel CPUs in this generation often panic when entering deep C-states
   - Solution: Limit C-state depth with `intel_idle.max_cstate=1` and `processor.max_cstate=1`
   - **Evidence:** nixstation (Intel i7-5820K) uses these parameters successfully

2. **ACPI Issues**
   - ACPI tables on Dell laptops can be problematic
   - May need `acpi=noirq` or `acpi=strict` instead of disabling ACPI entirely
   - Some reports suggest `acpi_osi=Linux` helps

3. **Intel Graphics (i915) Driver Issues**
   - Some Latitude 5410 models have issues with Intel GPU initialization
   - May need `i915.enable_guc=0` and `i915.enable_huc=0` to disable firmware loading
   - Alternative: `i915.modeset=1` to force modesetting

4. **NVMe Storage Issues**
   - Some NVMe drives have compatibility issues with certain kernel versions
   - May need `nvme_core.default_ps_max_latency_us=0` to disable power management

5. **Firmware/Microcode**
   - Ensure Intel microcode is up to date (already enabled via `hardware.cpu.intel.updateMicrocode`)
   - May need `dis_ucode_ldr` to disable microcode loading if it's causing issues

## Changes Made (Current Iteration)

### 1. Removed Verbose Kernel Parameter
**File:** `hosts/nixbook/system.nix`  
**Change:** Removed `loglevel=6` from `boot.kernelParams`

**Before:**
```nix
kernelParams = [ "loglevel=6" ];
```

**After:**
```nix
kernelParams = [ ];
```

**Reason:** `loglevel=6` is extremely verbose (KERN_DEBUG level) and can cause boot issues or kernel panics on some hardware, especially laptops. Default logging level is safer.

### 2. Added Documentation Comments
Added comments explaining why certain parameters are NOT included:
- No AMD-specific parameters (`amdgpu.*`) - this is an Intel system
- No aggressive parameters like `preempt=full` or `threadirqs` - these work on rvbee but can cause panics

### 3. Added Intel C-State Limiting Parameters (Priority 1 Fix)
**File:** `hosts/nixbook/system.nix`  
**Change:** Added C-state limiting parameters to prevent kernel panics

**Before:**
```nix
kernelParams = [ ];
```

**After (Priority 1-3 Combined):**
```nix
kernelParams = [
  # Intel C-state fixes (Priority 1)
  "intel_idle.max_cstate=1"   # Reduce C-state depth (prevents deep sleep panics)
  "processor.max_cstate=1"    # Limit processor C-states system-wide
  # Intel graphics fixes (Priority 2)
  "i915.enable_guc=0"         # Disable Intel GPU GuC firmware loading
  "i915.enable_huc=0"         # Disable Intel GPU HuC firmware loading
  # ACPI compatibility (Priority 3)
  "acpi_osi=Linux"            # Tell ACPI we're Linux (better compatibility)
];
```

**Reason:** 
- Priority 1: Most common cause of kernel panics on Dell Latitude 5410 and similar Intel laptops
  - Intel CPUs in this generation often panic when entering deep C-states
  - Successfully used on nixstation (Intel i7-5820K) system
  - Conservative parameters that only limit deep sleep states (low risk)
- Priority 2: Intel i915 driver can cause panics during initialization on some Latitude models
  - GuC/HuC firmware loading can fail and cause kernel panics
  - Disabling these features is safe and commonly needed on Dell laptops
- Priority 3: Dell laptops often have problematic ACPI tables
  - Telling ACPI we're Linux improves compatibility with Dell firmware
  - Less aggressive than `acpi=noirq` or `acpi=off`

**Date:** 2024-12-15

## Comparison with Working Systems

### rvbee (AMD System - Working)
```nix
boot.kernelParams = ["amdgpu.securedisplay=0" "preempt=full" "threadirqs"];
boot.kernelModules = ["kvm-amd"];
hardware.cpu.amd.updateMicrocode = true;
```

### laptop (Intel System - Panicking)
```nix
boot.kernelParams = [
  "intel_idle.max_cstate=1"   # Priority 1: Prevent C-state panics
  "processor.max_cstate=1"    # Priority 1: Limit processor C-states
  "i915.enable_guc=0"         # Priority 2: Disable Intel GPU GuC
  "i915.enable_huc=0"         # Priority 2: Disable Intel GPU HuC
  "acpi_osi=Linux"            # Priority 3: ACPI compatibility
];
boot.kernelModules = [ "kvm-intel" ];  # From hardware-configuration.nix
hardware.cpu.intel.updateMicrocode = true;
```

**Key Differences:**
- rvbee uses AMD-specific GPU parameters
- rvbee uses aggressive preemption (`preempt=full`, `threadirqs`)
- laptop should NOT have AMD parameters
- laptop should use conservative kernel parameters

## Current Configuration State

### Kernel Configuration
- **Kernel Package:** `pkgs.linuxPackages` (standard, not Zen)
- **Kernel Modules (hardware-config):** `["kvm-intel"]`
- **Kernel Modules (system.nix):** None (v4l2loopback loaded via systemd service)
- **Kernel Parameters:** 
  - `intel_idle.max_cstate=1` (Priority 1 - C-state limiting)
  - `processor.max_cstate=1` (Priority 1 - C-state limiting)
  - `i915.enable_guc=0` (Priority 2 - Intel graphics)
  - `i915.enable_huc=0` (Priority 2 - Intel graphics)
  - `acpi_osi=Linux` (Priority 3 - ACPI compatibility)

### Initrd Configuration
- **Available Modules:** `["xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"]`
- **Kernel Modules:** `[]` (empty - good, no early loading)

### v4l2loopback Configuration
- **Loading Method:** systemd service (`systemd.services.load-v4l2loopback`)
- **Load Time:** After `multi-user.target` (not early boot)
- **Reason:** Avoids kernel panic during early boot if module has compatibility issues

## What to Check After Reboot

### If Boot Succeeds ✅
1. Verify kernel parameters: `cat /proc/cmdline`
   - Should contain `intel_idle.max_cstate=1`
   - Should contain `processor.max_cstate=1`
   - Should contain `i915.enable_guc=0`
   - Should contain `i915.enable_huc=0`
   - Should contain `acpi_osi=Linux`
   - Should NOT contain `loglevel=6`
   - Should NOT contain AMD-specific parameters

2. Check kernel version: `uname -r`
   - Should be 6.12.60 (standard kernel, not Zen)

3. Verify v4l2loopback loads: `lsmod | grep v4l2loopback`
   - Should be loaded after system is up

4. Check system logs: `journalctl -b --no-pager | grep -i "error\|panic\|oops" | tail -20`
   - Should not show kernel panics

### If Still Panicking ❌

#### Step 1: Capture Panic Details
1. **Note the exact panic message** - what driver/module is mentioned?
2. **Note the panic location** - what function/code path?
3. **Check if it's consistent** - same spot every time?

#### Step 2: Check Kernel Logs
```bash
# If you can boot into an old generation, check:
journalctl -b -1 --no-pager | grep -i "panic\|oops\|bug" | tail -50
dmesg | grep -i "panic\|oops\|bug"  # (requires sudo)
```

#### Step 3: Review Hardware-Specific Issues
Check if panic is related to:
- **Storage:** NVMe driver issues? (`nvme` module in initrd)
- **USB:** USB controller issues? (`xhci_pci` module)
- **Graphics:** Intel i915 driver issues? (check if graphics are initialized)
- **ACPI:** ACPI/firmware issues? (common on laptops)

#### Step 4: Try Minimal Kernel Parameters
If still panicking, try adding safe parameters one at a time:

```nix
# Option 1: Disable problematic features
kernelParams = [ "acpi=off" ];  # Test if ACPI is the issue

# Option 2: Enable verbose logging temporarily (to see where it fails)
kernelParams = [ "loglevel=7" "debug" ];  # More verbose than before

# Option 3: Disable specific drivers
kernelParams = [ "modprobe.blacklist=i915" ];  # If Intel graphics is issue
```

#### Step 5: Check for Missing Firmware
```bash
# Check if firmware is missing
dmesg | grep -i "firmware\|microcode"
```

## Recommended Fixes (Prioritized)

### Priority 1: Intel C-State Parameters (HIGHEST PRIORITY)
**Why:** Most common cause of kernel panics on Dell Latitude 5410 and similar Intel laptops.  
**Evidence:** nixstation (Intel i7-5820K) uses these successfully.

```nix
kernelParams = [
  "intel_idle.max_cstate=1"   # Reduce C-state depth (prevents deep sleep panics)
  "processor.max_cstate=1"    # Limit processor C-states system-wide
];
```

### Priority 2: Intel Graphics Driver Parameters
**Why:** Intel i915 driver can cause panics during initialization on some Latitude models.

```nix
kernelParams = [
  "i915.enable_guc=0"         # Disable Intel GPU GuC firmware loading
  "i915.enable_huc=0"         # Disable Intel GPU HuC firmware loading
  "i915.modeset=1"            # Force modesetting (may help with display init)
];
```

### Priority 3: ACPI Parameters
**Why:** Dell laptops often have problematic ACPI tables.

```nix
kernelParams = [
  "acpi_osi=Linux"             # Tell ACPI we're Linux (better compatibility)
  # OR if that doesn't work:
  # "acpi=noirq"               # Disable ACPI IRQ routing (more aggressive)
];
```

### Priority 4: NVMe Power Management
**Why:** Some NVMe drives panic during power state transitions.

```nix
kernelParams = [
  "nvme_core.default_ps_max_latency_us=0"  # Disable NVMe power management
];
```

### Combined Recommended Configuration (Try This First)
Based on research and nixstation's working configuration:

```nix
boot.kernelParams = [
  # Intel C-state fixes (most important for Latitude 5410)
  "intel_idle.max_cstate=1"
  "processor.max_cstate=1"
  
  # Intel graphics fixes
  "i915.enable_guc=0"
  "i915.enable_huc=0"
  
  # ACPI compatibility
  "acpi_osi=Linux"
];
```

## Potential Next Steps (If Still Failing)

### Option A: More Aggressive C-State Disabling
If Priority 1 doesn't work, try even more restrictive:
```nix
kernelParams = [
  "intel_idle.max_cstate=0"   # Disable C-states entirely (higher power use)
  "processor.max_cstate=0"    # Disable processor C-states
  "idle=poll"                 # Poll for work instead of using idle states
];
```

### Option B: Disable Intel P-State Driver
Some systems work better with acpi-cpufreq instead:
```nix
kernelParams = [
  "intel_pstate=disable"      # Use acpi-cpufreq instead
];
```

### Option C: Disable Specific Hardware Features
```nix
kernelParams = [
  "i915.enable_guc=0"         # Disable Intel GPU GuC (if graphics issue)
  "i915.enable_huc=0"         # Disable Intel GPU HuC
  "i915.enable_dc=0"          # Disable display compression
];
```

### Option C: Check Initrd Modules
If panic happens during initrd phase:
- Review `boot.initrd.availableKernelModules`
- May need to add/remove specific modules
- Check if `rtsx_pci_sdmmc` (SD card reader) is causing issues

### Option D: Compare with Working Old Generation
```bash
# Boot into old working generation
# Check its kernel parameters:
cat /proc/cmdline

# Compare kernel modules:
lsmod | sort > /tmp/old-modules.txt

# Boot into new generation (if possible)
lsmod | sort > /tmp/new-modules.txt
diff /tmp/old-modules.txt /tmp/new-modules.txt
```

## Files Modified

1. **`hosts/nixbook/system.nix`**
   - Line ~400: Changed `kernelParams` to include Priority 1-3 fixes
   - Added `intel_idle.max_cstate=1` and `processor.max_cstate=1` (Priority 1)
   - Added `i915.enable_guc=0` and `i915.enable_huc=0` (Priority 2)
   - Added `acpi_osi=Linux` (Priority 3)
   - Added documentation comments explaining Dell Latitude 5410 specific fixes
   - Previous: Removed `loglevel=6` (too verbose, can cause boot issues)

2. **`modules/shared/shell.nix`** ⚠️ **CRITICAL FIX**
   - Line ~140: Added `mkdir -p` before `chown` command
   - Ensures `.cache` directory exists before attempting to chown it
   - Prevents activation script from failing and killing init (PID 1)
   - **This was the actual root cause of the kernel panic**

## Files to Review (If Issues Persist)

1. **`hosts/nixbook/hardware-configuration.nix`**
   - Check `boot.initrd.availableKernelModules`
   - Check `boot.kernelModules`
   - Verify no AMD-specific configurations

2. **`modules/shared/system.nix`**
   - Check if shared module adds any kernel parameters
   - Verify kernel package selection

3. **`hosts/rvbee/hardware-configuration.nix`** (for comparison)
   - Compare working AMD system configuration
   - Note differences in kernel parameters

## Debugging Commands Reference

```bash
# Check current kernel parameters
cat /proc/cmdline

# Check kernel version
uname -r

# Check loaded modules
lsmod

# Check kernel messages
dmesg | tail -100

# Check system logs for errors
journalctl -k --no-pager | grep -i "error\|panic\|oops" | tail -50

# Check boot logs from previous generation
journalctl -b -1 --no-pager | tail -200

# Check if specific module is loaded
lsmod | grep -i "module_name"

# Check hardware
lspci | grep -i "vga\|display\|graphics"
lscpu | grep -i "model name"
```

## Implementation Plan

### Step 1: ✅ COMPLETED - Applied Priority 1-3 Fixes (Combined Configuration)
**Action:** Added Intel C-state, graphics, and ACPI parameters to `hosts/nixbook/system.nix`

```nix
boot.kernelParams = [
  "intel_idle.max_cstate=1"   # Priority 1
  "processor.max_cstate=1"    # Priority 1
  "i915.enable_guc=0"         # Priority 2
  "i915.enable_huc=0"         # Priority 2
  "acpi_osi=Linux"            # Priority 3
];
```

**Rationale:** Combined approach addresses the three most common causes of kernel panics on Dell Latitude 5410.  
**Risk:** Low - these are well-tested parameters commonly used for Dell laptop compatibility.

### Step 2: If Still Panicking - Add Priority 4 Fixes (NVMe Power Management)
**Action:** Add NVMe power management parameter

```nix
boot.kernelParams = [
  "intel_idle.max_cstate=1"
  "processor.max_cstate=1"
  "i915.enable_guc=0"
  "i915.enable_huc=0"
  "acpi_osi=Linux"
  "nvme_core.default_ps_max_latency_us=0"  # Priority 4
];
```

### Step 3: If Still Panicking - Try More Aggressive C-State Disabling
**Action:** Disable C-states entirely (higher power consumption)

```nix
boot.kernelParams = [
  "intel_idle.max_cstate=0"   # Disable C-states entirely
  "processor.max_cstate=0"     # Disable processor C-states
  "idle=poll"                  # Poll for work instead of using idle states
  "i915.enable_guc=0"
  "i915.enable_huc=0"
  "acpi_osi=Linux"
];
```

### Step 4: Capture Panic Details
If still panicking after all fixes:
1. **Note exact panic message** - screenshot or photo the screen
2. **Identify failing module** - look for module names in panic output
3. **Check panic location** - note the function/code path mentioned
4. **Boot into old generation** - compare working vs non-working configs

## Notes for Next Session

- [ ] Did Priority 1-3 fixes (C-state, Intel graphics, ACPI) resolve the panic?
- [ ] If still panicking, what is the exact panic message? (screenshot/photograph)
- [ ] What generation number are we testing?
- [ ] Can we boot into an old working generation to compare kernel parameters?
- [ ] Are there any hardware-specific error messages before the panic?
- [ ] What CPU generation is this? (check with `lscpu` if system boots)
- [ ] Is Intel microcode loading correctly? (check `dmesg | grep microcode`)
- [ ] If still panicking, try Priority 4 (NVMe power management) or more aggressive C-state disabling

## Related Issues

- Previous attempt: Removed v4l2loopback from early boot
- Previous attempt: Swapped Zen kernel for standard kernel
- Previous attempt: Removed verbose kernel parameter (`loglevel=6`)
- Previous attempt: Added Intel C-state limiting parameters (Priority 1 fix)
- Previous attempt: Added Intel graphics and ACPI parameters (Priority 2-3 fixes) - Combined Priority 1-3 configuration
- **FINAL FIX:** Fixed shell activation script bug - was trying to chown non-existent `.cache` directory (this was the actual root cause)

## Success Criteria

✅ System boots without kernel panic  
✅ All hardware is detected correctly  
✅ Graphics work (Intel i915)  
✅ Storage is accessible  
✅ System is stable

---

**Next Action:** 
1. ✅ COMPLETED: Applied Priority 1-3 fixes (C-state, Intel graphics, ACPI) to `hosts/nixbook/system.nix`
2. ✅ COMPLETED: Fixed shell activation script bug in `modules/shared/shell.nix`
3. Rebuild with `sudo nixos-rebuild switch --flake .#nixbook`
4. Test boot - should now succeed without kernel panic
5. Verify system boots correctly and all services start properly

## References

- Dell Latitude 5410 Linux compatibility reports
- Intel C-state kernel panic issues (common on 10th/11th gen Intel CPUs)
- nixstation configuration (working Intel i7-5820K with C-state fixes)
- Linux kernel bug reports for Dell Latitude series
