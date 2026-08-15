# RTL Verification

This directory contains the RTL simulation and waveform evidence for the Verilog-based Sobel Edge Detector Accelerator.

The design was verified using a self-checking Verilog testbench with 256×256 RGB input images. Verification was performed at RTL level using Icarus Verilog and GTKWave.

---

## Verification Flow

The complete RTL processing pipeline is:
```text
<div align="center">
RGB Input Image
       │
       ▼
RGB to Grayscale
       │
       ▼
3×3 Sliding Window
       │
       ▼
Sobel X/Y Gradient Computation
       │
       ▼
Gradient Magnitude
       │
       ▼
Thresholding
       │
       ▼
Edge Output
</div>
```
</div>
## Testbench Configuration
<div align="center">
| Parameter | Value |
|---|---:|
| Image Width | 256 pixels |
| Image Height | 256 pixels |
| Input Format | 24-bit RGB |
| Grayscale Output | 8-bit |
| Sobel Window | 3×3 |
| Valid Row Range | 1–254 |
| Valid Column Range | 1–254 |
| Expected Valid Outputs | 64,516 |
</div>
---

## Why 64,516 Valid Outputs?

The Sobel operator requires a complete 3×3 neighborhood for every processed pixel.

Therefore, the outermost one-pixel border of the 256×256 image cannot produce a centered 3×3 Sobel result.

The valid processing region is:
Rows    : 1 → 254
Columns : 1 → 254

Therefore:
254 × 254 = 64,516 valid output pixels

This expected count is used by the testbench as a verification criterion.

---

## Testbench Checks

The self-checking testbench verifies:

- Correct reset and processing initialization
- Start and streaming control behavior
- Valid edge output generation
- `edge_valid` activity
- Output row coordinate range
- Output column coordinate range
- Number of valid edge outputs
- Final output coordinate
- Frame completion
- End-of-frame behavior

The testbench also tracks the minimum and maximum row/column coordinates observed during valid output processing.

---

## Final Verification Result
Expected edge-valid outputs : 64,516
Observed edge-valid outputs : 64,516

Valid row range:
1 → 254

Valid column range:
1 → 254

Final valid coordinate:
(254, 254)

Verification result:
PASS

The observed output count matches the mathematically expected number of valid 3×3 Sobel windows.

---
#  Simulation & Waveform Evidence

RTL simulation was performed using: **Icarus Verilog + GTKWave**

The repository contains waveform captures demonstrating the major stages of the accelerator operation.

## 1. High-Level Testbench Control

<div align="center">

<img src="verification/waveforms/01_tb_control.png" width="900">

</div>

This waveform demonstrates:

- Clock operation
- Reset release
- Start command
- Streaming activity
- `edge_valid` generation
- Frame processing and completion
---

## 2. Sobel Datapath Processing

<div align="center">

<img src="verification/waveforms/02_sobel_processing.png" width="900">

</div>

This waveform shows the 3×3 sliding pixel window:

```text
p00  p01  p02
p10  p11  p12
p20  p21  p22
```

along with:

- `gx`,  `gy`
- `gradient_mag`
- `gradient_valid`

The waveform provides direct RTL-level evidence that pixel neighborhoods are being processed and corresponding Sobel gradients are being generated.

---

## 3. Frame Completion

<div align="center">

<img src="verification/waveforms/03_frame_completion.png" width="900">

</div>

This waveform captures:

- `edge_pixel`
- `edge_valid`
- `out_row`
- `out_col`
- `frame_done`
- `streaming`

The final valid coordinate reaches:

```text
row = 254
col = 254
```
After the final output passes through the pipeline, the frame completion pulse is generated and streaming terminates.

---

## Verification Summary

The RTL implementation successfully processes a 256×256 RGB image through the complete Sobel edge-detection pipeline.

The self-checking testbench confirms:

```text
256×256 input frame
        ↓
3×3 Sobel processing
        ↓
254×254 valid processing region
        ↓
64,516 valid outputs
        ↓
Final coordinate = (254,254)
        ↓
Frame completion
```

The simulation and waveform results provide RTL-level evidence that the accelerator performs the intended streaming Sobel edge-detection operation.
