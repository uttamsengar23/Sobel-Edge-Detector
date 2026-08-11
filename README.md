# RTL Verification

This directory contains the RTL simulation and waveform evidence for the Verilog-based Sobel Edge Detector Accelerator.

The design was verified using a self-checking Verilog testbench with 256×256 RGB input images. Verification was performed at RTL level using Icarus Verilog and GTKWave.

---

## Verification Flow

The complete RTL processing pipeline is:

```text
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
```

---

## Testbench Configuration

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

## Waveform Evidence

The waveform captures below provide RTL-level evidence of the main stages of the accelerator operation.

### 1. High-Level Testbench Control

**File:** `waveforms/01_tb_control.png`

This waveform shows the high-level control behavior of the accelerator, including:

- Clock operation
- Reset release
- Start command
- Streaming activity
- `edge_valid` generation
- Frame processing
- Frame completion

The waveform demonstrates that the design enters its streaming processing phase and generates valid outputs during frame processing.

---

### 2. Sobel Datapath Processing

**File:** `waveforms/02_sobel_processing.png`

This waveform provides the main datapath-level verification evidence.

It shows the 3×3 sliding pixel window:

```text
p00  p01  p02
p10  p11  p12
p20  p21  p22
```

along with:

- `gx` — horizontal Sobel gradient
- `gy` — vertical Sobel gradient
- `gradient_mag` — gradient magnitude
- `gradient_valid` — validity of the computed gradient

An example captured window demonstrates changing pixel values producing corresponding non-zero Sobel gradient values while `gradient_valid` is asserted.

This provides direct waveform-level evidence that the Sobel datapath is actively processing the pixel neighborhood.

---

### 3. Frame Completion

**File:** `waveforms/03_frame_completion.png`

This waveform captures the end of frame processing and shows:

- `edge_pixel`
- `edge_valid`
- `out_col`
- `out_row`
- `frame_done`
- `streaming`

The final valid row reaches:

```text
FE = 254
```

and the output column progresses to the final valid column:

```text
FE = 254
```

The frame completion pulse occurs after the final output processing, followed by the end of streaming activity.

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