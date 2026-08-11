# Verilog Sobel Edge Detector Accelerator

> A modular, pipelined RTL implementation of real-time Sobel edge detection for 256×256 RGB images, designed and functionally verified using Verilog simulation.

![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)
![RTL](https://img.shields.io/badge/Design-RTL-orange)
![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog-green)

![Waveform](https://img.shields.io/badge/Verification-GTKWave-purple)
![Python](https://img.shields.io/badge/Automation-Python-yellow)

---

## Project Overview

This project implements a **hardware Sobel Edge Detector Accelerator** using
modular Verilog RTL.

The design converts RGB image pixels to grayscale, generates a 3×3 sliding
window, computes horizontal and vertical Sobel gradients, calculates the
gradient magnitude, and produces a binary edge map.

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
