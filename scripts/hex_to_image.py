from PIL import Image
import sys


WIDTH = 256
HEIGHT = 256


if len(sys.argv) != 3:
    print("Usage:")
    print("python scripts/hex_to_image.py <input_hex> <output_png>")
    sys.exit(1)


INPUT_FILE = sys.argv[1]
OUTPUT_FILE = sys.argv[2]


# ------------------------------------------------------------
# Read Verilog $writememh HEX file
# ------------------------------------------------------------

pixels = []

with open(INPUT_FILE, "r") as f:

    for line in f:

        line = line.strip()

        if not line:
            continue

        # Skip Verilog memory-address comments
        if line.startswith("//"):
            continue

        value = int(line, 16)

        # Keep only 8 bits
        value &= 0xFF

        pixels.append(value)


# ------------------------------------------------------------
# Check pixel count
# ------------------------------------------------------------

expected_pixels = WIDTH * HEIGHT

print("Expected pixels :", expected_pixels)
print("Pixels read     :", len(pixels))

if len(pixels) != expected_pixels:

    raise ValueError(
        f"Pixel count mismatch! "
        f"Expected {expected_pixels}, got {len(pixels)}"
    )


# ------------------------------------------------------------
# Create grayscale image
# ------------------------------------------------------------

image = Image.new("L", (WIDTH, HEIGHT))
image.putdata(pixels)


# ------------------------------------------------------------
# Save output
# ------------------------------------------------------------

image.save(OUTPUT_FILE)

print("-----------------------------------------")
print("Image generated successfully!")
print("Output :", OUTPUT_FILE)
print("-----------------------------------------")