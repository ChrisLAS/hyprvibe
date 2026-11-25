"""Verify OpenVINO discovery, compilation, output, and NPU activity."""
from pathlib import Path

import numpy as np
import openvino as ov
import openvino.opset13 as ops

core = ov.Core()
print("OpenVINO:", ov.__version__)
print("Devices:", core.available_devices)
if "NPU" not in core.available_devices:
    raise SystemExit("NPU not detected; check the userspace driver and loader")
print("NPU:", core.get_property("NPU", "FULL_DEVICE_NAME"))
x = ops.parameter([1, 512, 512], np.float32)
weights = ops.constant(np.ones((512, 512), dtype=np.float32))
model = ov.Model([ops.relu(ops.matmul(x, weights, False, False))], [x])
compiled = core.compile_model(model, "NPU")
value = np.ones((1, 512, 512), dtype=np.float32)
busy = Path("/sys/class/accel/accel0/device/npu_busy_time_us")
before = int(busy.read_text())
for _ in range(50):
    result = compiled(value)[0]
after = int(busy.read_text())
np.testing.assert_allclose(result, 512, rtol=0, atol=0)
print("NPU busy time increase:", after - before, "us")
if after <= before:
    raise SystemExit("NPU busy counter did not increase")
print("PASS: NPU discovery, inference and activity")
