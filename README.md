# ⚡ Verilog Sobel Edge Detector Accelerator

> A modular, pipelined RTL implementation of real-time Sobel edge detection for 256×256 RGB images, designed and functionally verified using Verilog simulation.

![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)
![RTL](https://img.shields.io/badge/Design-RTL-orange)
![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog-green)
![Waveform](https://img.shields.io/badge/Verification-GTKWave-purple)
![Python](https://img.shields.io/badge/Automation-Python-yellow)

---

## 📌 Project Overview

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

---

## 🎯 What Was Built

```text
RGB Image
    │
    ▼
┌─────────────────┐
│ RGB → Grayscale │
└────────┬────────┘
         ▼
┌─────────────────┐
│  3×3 Window     │
│     Buffer      │
└────────┬────────┘
         ▼
┌─────────────────┐
│   Sobel Core    │
│    Gx / Gy      │
│  |Gx| + |Gy|    │
└────────┬────────┘
         ▼
┌─────────────────┐
│   Threshold     │
└────────┬────────┘
         ▼
     Edge Map
