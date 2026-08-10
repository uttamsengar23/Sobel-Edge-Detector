"""
==============================================================
File        : generate_shapes.py
Author      : Uttam Sengar
Project     : Parameterized Sobel Edge Detection Accelerator

Description :
Generates a dataset of geometric shapes for testing the Sobel
Edge Detector. Images are stored in dataset/shapes/.

Generated Images:
    - square.png
    - circle.png
    - triangle.png
    - star.png
    - hexagon.png
==============================================================
"""

from pathlib import Path
from PIL import Image, ImageDraw
import math

# ==========================================================
# Project Paths
# ==========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = PROJECT_ROOT / "dataset" / "shapes"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ==========================================================
# Image Configuration
# ==========================================================

IMAGE_SIZE = (256, 256)

BACKGROUND_COLOR = "white"
SHAPE_COLOR = "black"

LINE_WIDTH = 5

CENTER = (128, 128)

# ==========================================================
# Helper Functions
# ==========================================================

def create_canvas():
    """Creates a blank white image."""
    image = Image.new("RGB", IMAGE_SIZE, BACKGROUND_COLOR)
    draw = ImageDraw.Draw(image)
    return image, draw


def save_image(image, filename):
    """Saves image to dataset/shapes."""
    image.save(OUTPUT_DIR / filename)
    print(f"[✓] Saved {filename}")


# ==========================================================
# Shape Functions
# ==========================================================

def draw_square():

    image, draw = create_canvas()

    draw.rectangle(
        [(60, 60), (196, 196)],
        outline=SHAPE_COLOR,
        width=LINE_WIDTH
    )

    save_image(image, "square.png")


def draw_circle():

    image, draw = create_canvas()

    draw.ellipse(
        [(50, 50), (206, 206)],
        outline=SHAPE_COLOR,
        width=LINE_WIDTH
    )

    save_image(image, "circle.png")


def draw_triangle():

    image, draw = create_canvas()

    points = [
        (128, 40),
        (50, 210),
        (206, 210)
    ]

    draw.polygon(
        points,
        outline=SHAPE_COLOR,
        width=LINE_WIDTH
    )

    save_image(image, "triangle.png")


def draw_polygon(sides, filename):

    image, draw = create_canvas()

    radius = 80

    points = []

    for i in range(sides):

        angle = math.radians((360 / sides) * i - 90)

        x = CENTER[0] + radius * math.cos(angle)
        y = CENTER[1] + radius * math.sin(angle)

        points.append((x, y))

    draw.polygon(
        points,
        outline=SHAPE_COLOR,
        width=LINE_WIDTH
    )

    save_image(image, filename)


def draw_star():

    image, draw = create_canvas()

    outer = 85
    inner = 35

    points = []

    for i in range(10):

        angle = math.radians(i * 36 - 90)

        radius = outer if i % 2 == 0 else inner

        x = CENTER[0] + radius * math.cos(angle)
        y = CENTER[1] + radius * math.sin(angle)

        points.append((x, y))

    draw.polygon(
        points,
        outline=SHAPE_COLOR,
        width=LINE_WIDTH
    )

    save_image(image, "star.png")


# ==========================================================
# Main Function 
# ==========================================================

def main():

    print("\nGenerating Shape Dataset...\n")

    draw_square()
    draw_circle()
    draw_triangle()
    draw_star()
    draw_polygon(6, "hexagon.png")

    print("\nDataset Generation Complete!\n")


if __name__ == "__main__":
    main()