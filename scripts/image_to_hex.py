from PIL import Image

# ============================================================
# Configuration
# ============================================================

INPUT_IMAGE = "dataset/natural/mountain.png"
OUTPUT_HEX = "images/image_rgb.hex"

WIDTH = 256
HEIGHT = 256

# ============================================================
# Load and resize image
# ============================================================

image = Image.open(INPUT_IMAGE).convert("RGB")
image = image.resize((WIDTH, HEIGHT))

# ============================================================
# Convert RGB pixels to 24-bit hexadecimal
# ============================================================

with open(OUTPUT_HEX, "w") as f:

    for y in range(HEIGHT):
        for x in range(WIDTH):

            r, g, b = image.getpixel((x, y))

            # 24-bit RGB:
            # RRRRRRRR GGGGGGGG BBBBBBBB
            rgb = (r << 16) | (g << 8) | b

            f.write(f"{rgb:06X}\n")

print("-----------------------------------------")
print("Input image :", INPUT_IMAGE)
print("Size        :", WIDTH, "x", HEIGHT)
print("Pixels      :", WIDTH * HEIGHT)
print("HEX created :", OUTPUT_HEX)
print("-----------------------------------------")