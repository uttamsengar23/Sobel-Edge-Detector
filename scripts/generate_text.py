"""
==============================================================
File        : generate_text.py
Author      : Uttam Sengar
Project     : Parameterized Sobel Edge Detection Accelerator

Description :
Generates text images for testing the Sobel Edge Detector.
==============================================================
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# ==========================================================
# Project Paths
# ==========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = PROJECT_ROOT / "dataset" / "text"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ==========================================================
# Configuration
# ==========================================================

IMAGE_SIZE = (256, 256)

BACKGROUND = "white"
TEXT_COLOR = "black"

WORDS = [
    "HELLO",
    "VLSI",
    "RTL",
    "SOBEL",
    "EDGE",
    "NITJ",
    "VERILOG",
    "FPGA"
]

# ==========================================================
# Load Font
# ==========================================================

try:
    font = ImageFont.truetype("arial.ttf", 40)
except:
    font = ImageFont.load_default()

# ==========================================================
# Generate Images
# ==========================================================

for word in WORDS:

    image = Image.new("RGB", IMAGE_SIZE, BACKGROUND)
    draw = ImageDraw.Draw(image)

    bbox = draw.textbbox((0, 0), word, font=font)

    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (IMAGE_SIZE[0] - text_width) // 2
    y = (IMAGE_SIZE[1] - text_height) // 2

    draw.text(
        (x, y),
        word,
        fill=TEXT_COLOR,
        font=font
    )

    image.save(OUTPUT_DIR / f"{word.lower()}.png")

    print(f"Generated : {word.lower()}.png")

print("\nText dataset generated successfully!")