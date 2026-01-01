#!/usr/bin/env python3
"""
Generate a Signed Distance Field (SDF) from a PNG image.

The script takes a PNG image (typically white pixels on transparent background,
but works with any color) and generates a signed distance field where:
- Negative values inside the shape
- Positive values outside the shape
- Distance measured in pixels

Usage:
    python generate_sdf.py input.png

Output:
    input_sdf.png (grayscale 8-bit image, normalized to 0-255 range)
"""

import sys
import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt


def generate_sdf(input_path: str) -> None:
    """Generate SDF from input PNG and save with _sdf suffix."""

    # Load image
    try:
        img = Image.open(input_path)
    except FileNotFoundError:
        print(f"Error: File not found: {input_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error loading image: {e}")
        sys.exit(1)

    # Convert to RGBA if needed
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    # Extract alpha channel to determine shape
    # Any pixel with alpha > 128 is considered "inside"
    alpha = np.array(img.split()[-1])
    binary = alpha > 128

    # Compute Euclidean distance transform
    # dist_inside: distance from each point to nearest non-shape pixel
    # dist_outside: distance from each point to nearest shape pixel
    dist_inside = distance_transform_edt(binary)
    dist_outside = distance_transform_edt(~binary)

    # Create SDF: negative inside, positive outside
    sdf = np.where(binary, -dist_inside, dist_outside)

    # Normalize to 0-255 for 8-bit image
    # We need a reasonable range. Typical SDFs use a max distance of 64-128 pixels
    # Clamp to [-128, 128] range, then shift to [0, 255]
    sdf_clamped = np.clip(sdf, -128, 128)
    sdf_normalized = ((sdf_clamped + 128) / 256 * 255).astype(np.uint8)

    # Create output path
    base_path = input_path.rsplit(".", 1)[0]
    output_path = f"{base_path}_sdf.png"

    # Save as grayscale
    sdf_image = Image.fromarray(sdf_normalized, "L")
    sdf_image.save(output_path)

    print(f"✓ SDF generated: {output_path}")
    print(f"  Input: {input_path}")
    print(f"  SDF range (pixels): [{int(np.min(sdf))}, {int(np.max(sdf))}]")
    print(f"  Image size: {img.size}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python generate_sdf.py <input.png>")
        sys.exit(1)

    generate_sdf(sys.argv[1])
