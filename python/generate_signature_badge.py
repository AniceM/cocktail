#!/usr/bin/env python3
"""
Generate signature badge assets for the cocktail mixing game.
Creates both gold (unlocked) and gray (discovered but not unlocked) variants.
Steampunk/cosmic aesthetic with radial gradient and shine.
"""

import argparse
from PIL import Image, ImageDraw, ImageFilter
import math


def lerp_color(c1, c2, t):
    """Linearly interpolate between two RGBA colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def create_signature_badge(size=128, output_path="badge.png", variant="gold"):
    """
    Create a signature badge with radial gradient fill.
    """
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2

    # Color schemes
    if variant == "gold":
        edge_color = (139, 90, 0, 255)        # Dark brown-gold edge
        outer_color = (184, 134, 11, 255)     # Dark goldenrod
        mid_color = (218, 165, 32, 255)       # Goldenrod
        inner_color = (255, 215, 0, 255)      # Bright gold
        highlight_color = (255, 245, 180, 255) # Bright highlight
    else:
        edge_color = (80, 80, 80, 255)
        outer_color = (120, 120, 120, 255)
        mid_color = (160, 160, 160, 255)
        inner_color = (190, 190, 190, 255)
        highlight_color = (210, 210, 210, 255)

    # Diamond shape
    max_radius = size * 0.45

    # Draw radial gradient by drawing many concentric diamonds
    num_steps = 40
    for i in range(num_steps):
        t = i / (num_steps - 1)  # 0 to 1, outer to inner
        radius = max_radius * (1 - t)

        # Color gradient: edge -> outer -> mid -> inner -> highlight
        if t < 0.1:
            color = lerp_color(edge_color, outer_color, t / 0.1)
        elif t < 0.4:
            color = lerp_color(outer_color, mid_color, (t - 0.1) / 0.3)
        elif t < 0.7:
            color = lerp_color(mid_color, inner_color, (t - 0.4) / 0.3)
        else:
            color = lerp_color(inner_color, highlight_color, (t - 0.7) / 0.3)

        # Diamond points (rotated square)
        points = [
            (center, center - radius),          # Top
            (center + radius, center),          # Right
            (center, center + radius),          # Bottom
            (center - radius, center),          # Left
        ]

        draw.polygon(points, fill=color)

    # Add subtle border
    border_radius = max_radius
    border_points = [
        (center, center - border_radius),
        (center + border_radius, center),
        (center, center + border_radius),
        (center - border_radius, center),
    ]
    draw.polygon(border_points, outline=edge_color, width=max(2, size // 50))

    # Add sparkle star for gold (top-left area)
    if variant == "gold":
        shine_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        shine_draw = ImageDraw.Draw(shine_img)

        # Position of sparkle
        sparkle_cx = center - max_radius * 0.3
        sparkle_cy = center - max_radius * 0.3

        # Draw 4-pointed star sparkle (+ shape with tapered points)
        # Main rays (vertical and horizontal)
        ray_length = max_radius * 0.25
        ray_width = max_radius * 0.04

        # Vertical ray
        shine_draw.polygon([
            (sparkle_cx, sparkle_cy - ray_length),  # Top
            (sparkle_cx + ray_width, sparkle_cy),   # Right
            (sparkle_cx, sparkle_cy + ray_length),  # Bottom
            (sparkle_cx - ray_width, sparkle_cy),   # Left
        ], fill=(255, 255, 255, 200))

        # Horizontal ray
        shine_draw.polygon([
            (sparkle_cx - ray_length, sparkle_cy),  # Left
            (sparkle_cx, sparkle_cy - ray_width),   # Top
            (sparkle_cx + ray_length, sparkle_cy),  # Right
            (sparkle_cx, sparkle_cy + ray_width),   # Bottom
        ], fill=(255, 255, 255, 200))

        # Diagonal rays (smaller, for 8-point effect)
        diag_length = ray_length * 0.6
        diag_width = ray_width * 0.7
        diag_offset = diag_length * 0.707  # cos(45)

        # Top-left to bottom-right diagonal
        shine_draw.polygon([
            (sparkle_cx - diag_offset, sparkle_cy - diag_offset),
            (sparkle_cx + diag_width * 0.5, sparkle_cy - diag_width * 0.5),
            (sparkle_cx + diag_offset, sparkle_cy + diag_offset),
            (sparkle_cx - diag_width * 0.5, sparkle_cy + diag_width * 0.5),
        ], fill=(255, 255, 255, 150))

        # Top-right to bottom-left diagonal
        shine_draw.polygon([
            (sparkle_cx + diag_offset, sparkle_cy - diag_offset),
            (sparkle_cx + diag_width * 0.5, sparkle_cy + diag_width * 0.5),
            (sparkle_cx - diag_offset, sparkle_cy + diag_offset),
            (sparkle_cx - diag_width * 0.5, sparkle_cy - diag_width * 0.5),
        ], fill=(255, 255, 255, 150))

        # Small center dot
        dot_radius = ray_width * 1.2
        shine_draw.ellipse([
            sparkle_cx - dot_radius, sparkle_cy - dot_radius,
            sparkle_cx + dot_radius, sparkle_cy + dot_radius
        ], fill=(255, 255, 255, 220))

        img = Image.alpha_composite(img, shine_img)

    # Slight blur for smoothness
    img = img.filter(ImageFilter.SMOOTH_MORE)

    img.save(output_path, 'PNG')
    print(f"Created {variant} badge: {output_path} ({size}x{size})")


def main():
    parser = argparse.ArgumentParser(
        description="Generate signature badge assets (gold and gray variants)"
    )
    parser.add_argument(
        '--size', type=int, default=128,
        help='Badge size in pixels (default: 128)'
    )
    parser.add_argument(
        '--output-dir', type=str, default='.',
        help='Output directory (default: current directory)'
    )
    parser.add_argument(
        '--prefix', type=str, default='signature_badge',
        help='Filename prefix (default: signature_badge)'
    )

    args = parser.parse_args()

    gold_path = f"{args.output_dir}/{args.prefix}_gold.png"
    gray_path = f"{args.output_dir}/{args.prefix}_gray.png"

    create_signature_badge(args.size, gold_path, "gold")
    create_signature_badge(args.size, gray_path, "gray")

    print(f"\nDone! Generated 2 badge variants at {args.size}x{args.size}")


if __name__ == "__main__":
    main()
