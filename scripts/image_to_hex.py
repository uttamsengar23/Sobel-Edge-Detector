from PIL import Image
import sys


WIDTH = 256
HEIGHT = 256


if len(sys.argv) != 3:
    print("Usage:")
    print("python scripts/image_to_hex.py <input_image> <output_hex>")
    sys.exit(1)


INPUT_IMAGE = sys.argv[1]
OUTPUT_HEX = sys.argv[2]


# ------------------------------------------------------------
# Load and resize image
# ------------------------------------------------------------

image = Image.open(INPUT_IMAGE).convert("RGB")
image = image.resize((WIDTH, HEIGHT))


# ------------------------------------------------------------
# Convert RGB image to 24-bit HEX
# ------------------------------------------------------------

with open(OUTPUT_HEX, "w") as f:

    for y in range(HEIGHT):
        for x in range(WIDTH):

            r, g, b = image.getpixel((x, y))

            rgb = (r << 16) | (g << 8) | b

            f.write(f"{rgb:06X}\n")


print("-----------------------------------------")
print("Input image :", INPUT_IMAGE)
print("Size        :", WIDTH, "x", HEIGHT)
print("Pixels      :", WIDTH * HEIGHT)
print("HEX created :", OUTPUT_HEX)
print("-----------------------------------------")