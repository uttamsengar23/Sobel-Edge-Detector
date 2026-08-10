from PIL import Image

# ============================================================
# Configuration
# ============================================================

WIDTH = 256
HEIGHT = 256

INPUT_FILE = "results/edge_output.hex"
OUTPUT_FILE = "results/edge_output.png"

# ============================================================
# Read Verilog $writememh HEX file
# ============================================================

pixels = []

with open(INPUT_FILE, "r") as f:
    for line in f:
        line = line.strip()

        # Skip empty lines
        if not line:
            continue

        # Skip Verilog memory-address comments
        if line.startswith("//"):
            continue

        # Convert hexadecimal pixel value to integer
        value = int(line, 16)

        # Make sure value is 8-bit
        value &= 0xFF

        pixels.append(value)

# ============================================================
# Check pixel count
# ============================================================

expected_pixels = WIDTH * HEIGHT

print("Expected pixels :", expected_pixels)
print("Pixels read     :", len(pixels))

if len(pixels) != expected_pixels:
    raise ValueError(
        f"Pixel count mismatch! "
        f"Expected {expected_pixels}, got {len(pixels)}"
    )

# ============================================================
# Create grayscale image
# ============================================================

image = Image.new("L", (WIDTH, HEIGHT))

image.putdata(pixels)

# ============================================================
# Save image
# ============================================================

image.save(OUTPUT_FILE)

print("-----------------------------------------")
print("Image generated successfully!")
print("Output :", OUTPUT_FILE)
print("-----------------------------------------")