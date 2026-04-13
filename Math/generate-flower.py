#!/usr/bin/env python3
"""
Phyllotaxis Flower Image Generator
Based on: phyllotaxis-flower-constants.json
Author: bonsai/qwen3.6-plus
Date: 2026-04-13

Generates smartphone portrait images (390x844) of golden-angle phyllotaxis flowers
using matplotlib. No AI/SD — pure mathematical generation from constants.
"""

import json
import math
import os
import numpy as np
from pathlib import Path

# ============================================================
# Load constants from JSON
# ============================================================
CONSTANTS_FILE = Path(__file__).parent / "phyllotaxis-flower-constants.json"

with open(CONSTANTS_FILE, 'r', encoding='utf-8') as f:
    config = json.load(f)

C = config["constants"]
FG = config["flower_generation"]
SA = config["spiral_arms"]
CP = config["color_palette"]

PHI = C["PHI"]
GOLDEN_ANGLE_DEG = C["GOLDEN_ANGLE_DEG"]
GOLDEN_ANGLE_RAD = math.radians(GOLDEN_ANGLE_DEG)

# Smartphone portrait dimensions
WIDTH = 390
HEIGHT = 844

# Output directory
OUTPUT_DIR = Path(__file__).parent / "generated"
OUTPUT_DIR.mkdir(exist_ok=True)


def generate_phyllotaxis_image(
    filename: str = None,
    variant: str = "classic",
    point_count: int = None,
    scale_factor: float = None,
    bg_color: str = None,
    title_text: str = None,
):
    """
    Generate a phyllotaxis flower image.
    
    Variants:
      - classic: Warm gold palette on dark background
      - pastel: Soft pastel colors on white background
      - neon: Neon colors on black background
      - fire: Red-orange gradient
      - ocean: Blue-green gradient
      - rainbow: Full spectrum
      - sakura: Pink cherry blossom theme
    """
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import matplotlib.patches as patches
    from matplotlib.colors import hsv_to_rgb

    n = point_count or FG["point_count"]
    scale = scale_factor or FG["scale_factor"]
    
    # Canvas
    cx = WIDTH / 2
    cy = HEIGHT / 2.2  # Slightly above center for title space
    
    # Colors per variant
    variant_palettes = {
        "classic": {
            "bg": (0.024, 0.024, 0.067),  # #0a0a1a
            "hue_fn": lambda i: (40 + i * 3 % 20) / 360,
            "sat": 0.7,
            "light_fn": lambda i: 0.55 + math.sqrt(i) * 0.003,
        },
        "pastel": {
            "bg": (0.98, 0.96, 0.94),
            "hue_fn": lambda i: (30 + i * 2 % 25) / 360,
            "sat": 0.4,
            "light_fn": lambda i: 0.75 + math.sqrt(i) * 0.002,
        },
        "neon": {
            "bg": (0.0, 0.0, 0.0),
            "hue_fn": lambda i: (i * 360 / n) / 360,
            "sat": 1.0,
            "light_fn": lambda i: 0.5 + math.sin(i * 0.1) * 0.2,
        },
        "fire": {
            "bg": (0.05, 0.02, 0.0),
            "hue_fn": lambda i: (i / n * 30) / 360,  # Red to orange
            "sat": 0.9,
            "light_fn": lambda i: 0.4 + math.sqrt(i/n) * 0.3,
        },
        "ocean": {
            "bg": (0.0, 0.05, 0.08),
            "hue_fn": lambda i: (180 + i * 40 / n) / 360,  # Cyan to blue
            "sat": 0.8,
            "light_fn": lambda i: 0.45 + math.sqrt(i/n) * 0.25,
        },
        "rainbow": {
            "bg": (0.02, 0.02, 0.05),
            "hue_fn": lambda i: (i * 360 / n) / 360,
            "sat": 0.85,
            "light_fn": lambda i: 0.5 + 0.2 * math.sin(i * 0.05),
        },
        "sakura": {
            "bg": (0.95, 0.92, 0.94),
            "hue_fn": lambda i: (330 + i * 30 / n) / 360,  # Pink
            "sat": 0.5,
            "light_fn": lambda i: 0.7 + math.sqrt(i/n) * 0.2,
        },
    }
    
    pal = variant_palettes.get(variant, variant_palettes["classic"])
    
    if bg_color:
        if bg_color.startswith('#'):
            r = int(bg_color[1:3], 16) / 255
            g = int(bg_color[3:5], 16) / 255
            b = int(bg_color[5:7], 16) / 255
            pal["bg"] = (r, g, b)
    
    # Generate points
    points = []
    for i in range(n):
        angle = i * GOLDEN_ANGLE_RAD
        r = scale * math.sqrt(i)
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        
        # Skip if outside canvas
        if x < 0 or x > WIDTH or y < 0 or y > HEIGHT:
            continue
            
        # Dot size
        dot_size = FG["dot_size_base"] + math.sqrt(i) * FG["dot_size_growth"]
        
        # Color
        h = pal["hue_fn"](i)
        s = pal["sat"]
        l = pal["light_fn"](i)
        color = hsv_to_rgb([h, s, l])
        
        points.append({
            'x': x, 'y': y, 'size': dot_size,
            'color': color, 'index': i
        })
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(WIDTH/100, HEIGHT/100), dpi=100)
    fig.patch.set_facecolor(pal["bg"])
    ax.set_facecolor(pal["bg"])
    
    ax.set_xlim(0, WIDTH)
    ax.set_ylim(HEIGHT, 0)  # Inverted y for image coords
    ax.set_aspect('equal')
    ax.axis('off')
    
    # Draw glow background circle
    glow = patches.Circle((cx, cy), radius=160, facecolor='none',
                          edgecolor=(1, 0.8, 0.4), linewidth=1, alpha=0.1)
    ax.add_patch(glow)
    
    # Draw dots
    for p in points:
        circle = patches.Circle((p['x'], p['y']), radius=p['size'],
                               facecolor=p['color'], alpha=0.85,
                               edgecolor='none')
        ax.add_patch(circle)
    
    # Draw 5 parastichy spiral arms
    arm_count = SA["count"]
    for s in range(arm_count):
        arm_points = []
        start_angle = math.radians(s * 360 / arm_count)
        for i in range(SA["points_per_arm"]):
            angle = start_angle + i * GOLDEN_ANGLE_RAD
            r = scale * math.sqrt(i * SA["growth_rate"] + s * SA["offset_base"])
            x = cx + r * math.cos(angle)
            y = cy + r * math.sin(angle)
            if 0 <= x <= WIDTH and 0 <= y <= HEIGHT:
                arm_points.append((x, y))
        
        if len(arm_points) > 1:
            xs, ys = zip(*arm_points)
            arm_color = hsv_to_rgb([pal["hue_fn"](s * 30), 0.6, 0.7])
            ax.plot(xs, ys, color=arm_color, linewidth=1.2, alpha=0.35)
    
    # Add title text
    display_title = title_text or f"φ={PHI:.10f}"
    ax.text(WIDTH/2, 40, display_title,
           fontsize=14, color=(0.9, 0.8, 0.5),
           fontfamily='serif', ha='center', va='top',
           fontweight='bold', alpha=0.8)
    
    # Add subtitle
    ax.text(WIDTH/2, 62, f"θ={GOLDEN_ANGLE_DEG}° | n={n} points | {variant}",
           fontsize=9, color=(0.7, 0.65, 0.5),
           fontfamily='sans-serif', ha='center', va='top',
           alpha=0.6)
    
    # Add footer
    ax.text(WIDTH/2, HEIGHT - 20, "bonsai/qwen3.6-plus | onsen.bonsai@gmail.com",
           fontsize=7, color=(0.5, 0.45, 0.35),
           fontfamily='sans-serif', ha='center', va='bottom',
           alpha=0.5)
    
    plt.tight_layout(pad=0)
    
    # Save
    if filename is None:
        filename = f"phyllotaxis-{variant}-{n}pts.png"
    output_path = OUTPUT_DIR / filename
    plt.savefig(output_path, dpi=100, bbox_inches='tight',
                pad_inches=0, facecolor=pal["bg"])
    plt.close()
    
    print(f"✓ Generated: {output_path}")
    print(f"  Variant: {variant} | Points: {n} | Size: {WIDTH}x{HEIGHT}")
    return output_path


def generate_all_variants():
    """Generate all variant images."""
    variants = ["classic", "pastel", "neon", "fire", "ocean", "rainbow", "sakura"]
    for v in variants:
        generate_phyllotaxis_image(variant=v)


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "all":
            generate_all_variants()
        else:
            # Generate single variant
            variant = cmd
            n = int(sys.argv[2]) if len(sys.argv) > 2 else FG["point_count"]
            generate_phyllotaxis_image(variant=variant, point_count=n)
    else:
        print("Phyllotaxis Flower Generator")
        print(f"Constants: {CONSTANTS_FILE}")
        print(f"Output: {OUTPUT_DIR}")
        print()
        print("Usage:")
        print("  python generate-flower.py              # Show help")
        print("  python generate-flower.py classic      # Generate classic variant")
        print("  python generate-flower.py all          # Generate all 7 variants")
        print()
        print("Variants: classic, pastel, neon, fire, ocean, rainbow, sakura")
        print(f"Output size: {WIDTH}x{HEIGHT} (smartphone portrait)")
        print()
        print("Generating default (classic) variant...")
        generate_phyllotaxis_image()
