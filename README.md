# Verilog Sobel Edge Detector Accelerator

> A modular, pipelined RTL implementation of real-time Sobel edge detection for 256×256 RGB images, designed and functionally verified using Verilog simulation.

![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)
![RTL](https://img.shields.io/badge/Design-RTL-orange)
![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog-green)

![Waveform](https://img.shields.io/badge/Verification-GTKWave-purple)
![Python](https://img.shields.io/badge/Automation-Python-yellow)

---

## Project Overview

Edge detection is a fundamental operation in computer vision used to identify
boundaries, contours, and structural features in an image.

Software implementations of image processing are flexible, but many
applications benefit from dedicated hardware pipelines that can process
pixels continuously with predictable latency.

This project explores that hardware approach by implementing a **Sobel Edge
Detector entirely at RTL level using Verilog**.

The design accepts a 24-bit RGB image, converts it to grayscale, generates a
3×3 sliding window, computes the Sobel X/Y gradients, calculates a
hardware-efficient gradient magnitude, and produces a binary edge map.

The RTL was verified using a self-checking testbench and tested across
multiple categories of input images.

### Processing Pipeline

```text
                         RGB IMAGE
                             │
                             ▼
                  ┌─────────────────────┐
                  │   RGB → Grayscale   │
                  │       24 → 8 bit    │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │    3×3 Window       │
                  │       Buffer        │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │     Sobel Core      │
                  │    Gx       Gy      │
                  │      \     /        │
                  │    |Gx| + |Gy|      │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │      Threshold      │
                  │     0x00 / 0xFF     │
                  └──────────┬──────────┘
                             │
                             ▼
                         EDGE MAP

##  Key Design Features

- 256×256 RGB image processing
- 24-bit RGB input
- 8-bit grayscale datapath
- 3×3 sliding-window architecture
- Sobel X/Y gradient computation
- Hardware-efficient `|Gx| + |Gy|` gradient magnitude
- Pipelined datapath
- Raster-order pixel streaming
- Row/column coordinate tracking
- Configurable edge threshold
- Self-checking RTL testbench
- Automated multi-image processing using Python
- RTL waveform verification using GTKWave

---

##  Sobel Edge Detection

For each 3×3 pixel neighborhood:

```text
p00  p01  p02
p10  p11  p12
p20  p21  p22
```

The Sobel gradients are calculated using:

```text
Gx = (p02 + 2p12 + p22)
     - (p00 + 2p10 + p20)

Gy = (p20 + 2p21 + p22)
     - (p00 + 2p01 + p02)
```

The gradient magnitude is approximated using:

```text
G = |Gx| + |Gy|
```

instead of the mathematically exact:

```text
G = √(Gx² + Gy²)
```

This hardware-friendly approximation avoids expensive multiplication and
square-root operations, reducing computational complexity in the RTL
datapath.

The resulting gradient magnitude is compared against a configurable
threshold to generate the binary edge output:

```text
Gradient ≥ Threshold  →  0xFF → Edge
Gradient < Threshold  →  0x00 → Non-edge
```

This produces the final binary edge map used for the output image.
