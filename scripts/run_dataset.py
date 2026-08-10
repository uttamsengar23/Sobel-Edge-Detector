import subprocess
from pathlib import Path
import shutil
import sys


# ============================================================
# Project paths
# ============================================================

ROOT = Path(__file__).resolve().parent.parent

DATASET_DIR = ROOT / "dataset"
IMAGE_HEX = ROOT / "images" / "image_rgb.hex"

EDGE_HEX = ROOT / "results" / "edge_output.hex"

RESULTS_DIR = ROOT / "results"

SIM_EXE = ROOT / "sim_out"


# ============================================================
# RTL source files
# ============================================================

RTL_FILES = [
    ROOT / "rtl" / "image_memory.v",
    ROOT / "rtl" / "rgb_to_gray.v",
    ROOT / "rtl" / "window_buffer.v",
    ROOT / "rtl" / "sobel_core.v",
    ROOT / "rtl" / "threshold.v",
    ROOT / "rtl" / "sobel_edge_detector.v",
    ROOT / "tb" / "tb_sobel_edge_detector.v",
]


# ============================================================
# Compile Verilog
# ============================================================

def compile_design():

    print("\n=========================================")
    print("Compiling Verilog design...")
    print("=========================================")

    command = [
        "iverilog",
        "-g2012",
        "-Wall",
        "-o",
        str(SIM_EXE),
    ]

    command += [str(file) for file in RTL_FILES]

    result = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True
    )

    if result.stdout:
        print(result.stdout)

    if result.stderr:
        print(result.stderr)

    if result.returncode != 0:
        print("\nERROR: Verilog compilation failed.")
        sys.exit(1)

    print("Compilation successful.")


# ============================================================
# Process one image
# ============================================================

def process_image(image_path):

    relative_path = image_path.relative_to(DATASET_DIR)

    category = relative_path.parent.name
    image_name = image_path.stem

    output_dir = RESULTS_DIR / category
    output_dir.mkdir(parents=True, exist_ok=True)

    output_png = output_dir / f"{image_name}_edge.png"

    print("\n")
    print("=========================================")
    print(f"Processing : {relative_path}")
    print(f"Category   : {category}")
    print(f"Output     : {output_png.relative_to(ROOT)}")
    print("=========================================")


    # --------------------------------------------------------
    # Step 1: Generate RGB HEX
    # --------------------------------------------------------

    hex_command = [
        sys.executable,
        str(ROOT / "scripts" / "image_to_hex.py"),
        str(image_path),
        str(IMAGE_HEX),
    ]

    result = subprocess.run(
        hex_command,
        cwd=ROOT,
        text=True
    )

    if result.returncode != 0:
        print("ERROR: Image-to-HEX conversion failed.")
        return False


    # --------------------------------------------------------
    # Step 2: Run Verilog simulation
    # --------------------------------------------------------

    print("\nRunning Sobel RTL simulation...")

    result = subprocess.run(
        ["vvp", str(SIM_EXE)],
        cwd=ROOT,
        text=True
    )

    if result.returncode != 0:
        print("ERROR: Verilog simulation failed.")
        return False


    # --------------------------------------------------------
    # Step 3: Convert Sobel HEX output to PNG
    # --------------------------------------------------------

    print("\nConverting edge output to PNG...")

    png_command = [
        sys.executable,
        str(ROOT / "scripts" / "hex_to_image.py"),
        str(EDGE_HEX),
        str(output_png),
    ]

    result = subprocess.run(
        png_command,
        cwd=ROOT,
        text=True
    )

    if result.returncode != 0:
        print("ERROR: HEX-to-image conversion failed.")
        return False


    print(f"\nSUCCESS: {output_png.relative_to(ROOT)}")

    return True


# ============================================================
# Main
# ============================================================

def main():

    print("\n")
    print("==============================================")
    print("   SOBEL EDGE DETECTOR - DATASET RUNNER")
    print("==============================================")
    print("Project :", ROOT)
    print("Dataset :", DATASET_DIR)
    print("==============================================\n")


    # --------------------------------------------------------
    # Compile once
    # --------------------------------------------------------

    compile_design()


    # --------------------------------------------------------
    # Find all PNG images in dataset
    # --------------------------------------------------------

    images = sorted(DATASET_DIR.rglob("*.png"))


    if not images:

        print("ERROR: No PNG images found in dataset/")
        sys.exit(1)


    print(f"\nFound {len(images)} input images.")


    # --------------------------------------------------------
    # Process every image
    # --------------------------------------------------------

    successful = 0
    failed = 0

    for image in images:

        if process_image(image):
            successful += 1
        else:
            failed += 1


    # --------------------------------------------------------
    # Final summary
    # --------------------------------------------------------

    print("\n")
    print("==============================================")
    print("              DATASET COMPLETE")
    print("==============================================")
    print(f"Total images : {len(images)}")
    print(f"Successful   : {successful}")
    print(f"Failed       : {failed}")
    print("==============================================")

    print("\nGenerated results are stored in:")
    print("results/<category>/<image_name>_edge.png")


if __name__ == "__main__":
    main()