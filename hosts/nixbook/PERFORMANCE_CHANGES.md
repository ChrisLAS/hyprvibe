# Performance Optimization Changes - Dell Latitude 5410 (nixbook)

## Summary
Comprehensive performance optimizations have been applied to the nixbook configuration for the Intel Core i7-10810U (Comet Lake) CPU and Intel UHD Graphics GPU.

## Changes Made

### 1. Kernel Selection ⚠️ **IMPORTANT**
**Changed from:** `pkgs.linuxPackages` (regular kernel)  
**Changed to:** `pkgs.linuxPackages_zen` (Zen kernel)

**Rationale:**
- Zen kernel provides better desktop performance and lower latency
- Previous issues were with Zen 6.18; newer versions (6.12+) are more stable
- Current stability fixes (C-state limiting, i915 fixes) should prevent previous panics

**If you experience kernel panics:**
- Change line 334 in `system.nix` to: `hyprvibe.system.kernelPackages = pkgs.linuxPackages_latest;`
- Or fallback to: `hyprvibe.system.kernelPackages = pkgs.linuxPackages;`

### 2. Kernel Parameters (Performance Additions)

#### CPU Optimizations
- `rcu_nocbs=0-11` - Offloads RCU callbacks from all 12 threads (6-core CPU)
- `nohz_full=0-11` - Enables full dynticks, reducing timer interrupts

#### Intel GPU Optimizations
- `i915.enable_fbc=1` - Frame buffer compression (saves power, improves performance)
- `i915.enable_psr=1` - Panel self-refresh (saves power)
- `i915.enable_dc=1` - Display C-states (power saving)
- `i915.modeset=1` - Explicit modesetting

#### I/O Optimizations
- `elevator=none` - No-op scheduler for NVMe drives (best performance)

#### Memory Optimizations
- `transparent_hugepage=always` - Always use hugepages when possible

**Existing stability parameters preserved:**
- `intel_idle.max_cstate=1`
- `processor.max_cstate=1`
- `i915.enable_guc=0`
- `i915.enable_huc=0`
- `acpi_osi=Linux`

### 3. Kernel sysctl Tuning

#### Memory Management
- `vm.swappiness=10` (reduced from 60) - Less aggressive swapping
- `vm.vfs_cache_pressure=50` - Balanced cache pressure
- `vm.dirty_background_ratio=5` - More aggressive dirty page flushing
- `vm.dirty_ratio=10` - Lower dirty page limit
- `vm.min_free_kbytes=65536` - Ensures minimum free memory
- `vm.zone_reclaim_mode=0` - Better for UMA systems

#### Network TCP Tuning
- Increased TCP buffer sizes (64MB max)
- TCP Fast Open enabled
- Network device backlog increased
- Slow start after idle disabled

### 4. Filesystem Optimizations
- Added `noatime` and `nodiratime` to `/` and `/home`
- Reduces disk writes (improves performance, especially on SSDs)
- Kept `discard` for TRIM support

### 5. Systemd Optimizations
- Increased `DefaultLimitNOFILE` to 65535
- Increased `DefaultLimitNPROC` to 32768
- Journald tuning: reduced flush frequency, limited size

### 6. ZRAM Configuration
- Set to 50% of RAM (good for systems with 16GB+)
- Already using zstd compression (best performance)

### 7. Intel GPU Hardware Acceleration
- Added `intel-media-driver` for VAAPI video acceleration
- Added legacy `vaapiIntel` as fallback
- Added VDPAU wrappers for compatibility
- Enables hardware video decoding/encoding

### 8. Security Limits
- Increased file descriptor limits (soft and hard) to 65535
- Better for development and high-concurrency workloads

## Expected Performance Improvements

### CPU Performance
- **Lower latency** from RCU/nohz tuning
- **Better responsiveness** from Zen kernel preemption
- **Reduced interrupt overhead** from nohz_full

### GPU Performance
- **Better video playback** from hardware acceleration
- **Power savings** from FBC, PSR, and DC
- **Smoother desktop** from optimized i915 driver

### Memory Performance
- **Faster large allocations** from transparent hugepages
- **Less swapping** from reduced swappiness
- **Better cache behavior** from tuned vfs_cache_pressure

### I/O Performance
- **Faster NVMe** from no-op scheduler
- **Reduced disk writes** from noatime
- **Better sequential performance** from tuned dirty ratios

### Network Performance
- **Higher throughput** from increased TCP buffers
- **Faster connections** from TCP Fast Open
- **Better persistent connections** from disabled slow start

## Testing Recommendations

### 1. Stability Testing (CRITICAL)
After applying changes, test for kernel panics:
```bash
# Monitor system logs
journalctl -f

# Stress test CPU
stress-ng --cpu 12 --timeout 60s

# Test GPU
glxgears
vulkaninfo

# Test video acceleration
mpv --hwdec=vaapi test-video.mp4
```

### 2. Performance Benchmarks
```bash
# CPU benchmark
sysbench cpu --threads=12 run

# Memory benchmark
sysbench memory --threads=12 run

# I/O benchmark
fio --name=random-write --ioengine=posixaio --rw=randwrite --bs=4k --size=4g --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1

# Overall system
phoronix-test-suite benchmark system
```

### 3. Power Consumption
Monitor power usage (may increase with performance governor):
```bash
powertop --html=power-report.html
```

### 4. Application-Specific Testing
- **Gaming**: Test games that previously had performance issues
- **Video editing**: Test video encoding/decoding performance
- **Development**: Test compilation times
- **Multimedia**: Test video playback, audio latency

## Rollback Instructions

If you experience issues, you can rollback specific changes:

### Rollback Kernel (if panics occur)
Edit `system.nix` line 334:
```nix
hyprvibe.system.kernelPackages = pkgs.linuxPackages;  # Regular kernel
```

### Rollback Kernel Parameters (if instability)
Remove or comment out performance parameters in `kernelParams`:
- Keep stability parameters (C-state, i915 GuC/HuC)
- Remove: `rcu_nocbs`, `nohz_full`, `transparent_hugepage`

### Rollback sysctl (if issues)
Remove the `kernel.sysctl` block or reduce values to defaults.

## Monitoring Commands

### Check Current Kernel
```bash
uname -r
```

### Check CPU Governor
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Check GPU Parameters
```bash
cat /sys/module/i915/parameters/enable_fbc
cat /sys/module/i915/parameters/enable_psr
```

### Check Memory Settings
```bash
cat /proc/sys/vm/swappiness
cat /sys/kernel/mm/transparent_hugepage/enabled
```

### Check ZRAM
```bash
zramctl
```

### Check VAAPI Support
```bash
vainfo
```

## Notes

1. **Power Consumption**: Performance optimizations may increase power consumption. Consider using `schedutil` governor on battery if needed.

2. **Thermal Management**: Monitor temperatures, especially under load. The performance governor keeps CPU at higher frequencies.

3. **Dell-Specific**: Some optimizations are tailored for Dell Latitude 5410. Test thoroughly on your specific hardware configuration.

4. **Incremental Testing**: If you want to test incrementally, you can comment out sections and enable them one at a time.

5. **Documentation**: See `PERFORMANCE_OPTIMIZATIONS.md` for detailed explanations of each optimization.

## Next Steps

1. **Rebuild system**: `sudo nixos-rebuild switch --flake .#nixbook`
2. **Reboot**: Required for kernel changes
3. **Monitor**: Watch for stability issues
4. **Benchmark**: Compare before/after performance
5. **Tune**: Adjust based on your specific workload

## Questions or Issues?

- Check system logs: `journalctl -b -p err`
- Review kernel messages: `dmesg | tail -50`
- Test individual components before full system stress test
- Consider reverting to regular kernel if Zen causes issues
