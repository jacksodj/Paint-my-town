#!/usr/bin/env python3

"""
App Icon Generator for Paint My Town
Generates placeholder app icons in all required sizes

Usage:
    python3 generate_app_icons.py

Requirements:
    pip3 install Pillow
"""

import os
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Error: Pillow not installed. Install with: pip3 install Pillow")
    exit(1)

# Icon sizes required for iOS
ICON_SIZES = {
    # iPhone
    "icon-20@2x.png": 40,
    "icon-20@3x.png": 60,
    "icon-29@2x.png": 58,
    "icon-29@3x.png": 87,
    "icon-40@2x.png": 80,
    "icon-40@3x.png": 120,
    "icon-60@2x.png": 120,
    "icon-60@3x.png": 180,

    # iPad
    "icon-20.png": 20,
    "icon-20@2x-ipad.png": 40,
    "icon-29.png": 29,
    "icon-29@2x-ipad.png": 58,
    "icon-40.png": 40,
    "icon-40@2x-ipad.png": 80,
    "icon-76.png": 76,
    "icon-76@2x.png": 152,
    "icon-83.5@2x.png": 167,

    # App Store
    "icon-1024.png": 1024,
}

def create_placeholder_icon(size, output_path):
    """Create a placeholder app icon with a simple design"""

    # Create image with gradient background
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)

    # Draw gradient background (blue to purple)
    for y in range(size):
        ratio = y / size
        r = int(52 + (147 - 52) * ratio)    # 52 -> 147
        g = int(152 + (51 - 152) * ratio)   # 152 -> 51
        b = int(219 + (234 - 219) * ratio)  # 219 -> 234
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    # Draw a paint brush icon (simple representation)
    center_x, center_y = size // 2, size // 2
    icon_size = int(size * 0.5)

    # Brush handle (diagonal line)
    brush_width = max(2, size // 20)
    handle_start_x = center_x - icon_size // 3
    handle_start_y = center_y - icon_size // 3
    handle_end_x = center_x + icon_size // 3
    handle_end_y = center_y + icon_size // 3

    draw.line(
        [(handle_start_x, handle_start_y), (handle_end_x, handle_end_y)],
        fill='white',
        width=brush_width
    )

    # Brush tip (circle)
    brush_radius = icon_size // 4
    draw.ellipse(
        [
            handle_end_x - brush_radius,
            handle_end_y - brush_radius,
            handle_end_x + brush_radius,
            handle_end_y + brush_radius
        ],
        fill='white',
        outline='white'
    )

    # Add "P" text for larger icons
    if size >= 120:
        try:
            # Try to use a system font
            font_size = int(size * 0.3)
            try:
                # Try different font paths
                font_paths = [
                    "/System/Library/Fonts/Helvetica.ttc",
                    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
                ]
                font = None
                for font_path in font_paths:
                    if os.path.exists(font_path):
                        font = ImageFont.truetype(font_path, font_size)
                        break

                if font:
                    text = "P"
                    bbox = draw.textbbox((0, 0), text, font=font)
                    text_width = bbox[2] - bbox[0]
                    text_height = bbox[3] - bbox[1]

                    text_x = (size - text_width) // 2
                    text_y = (size - text_height) // 2 - int(size * 0.05)

                    # Draw text with shadow for depth
                    shadow_offset = max(1, size // 100)
                    draw.text((text_x + shadow_offset, text_y + shadow_offset), text,
                             fill=(0, 0, 0, 128), font=font)
                    draw.text((text_x, text_y), text, fill='white', font=font)
            except:
                pass
        except:
            pass

    # Save with optimization
    img.save(output_path, 'PNG', optimize=True)
    print(f"✓ Created {output_path.name} ({size}x{size})")


def main():
    # Determine output directory
    script_dir = Path(__file__).parent
    assets_dir = script_dir / "PaintMyTown" / "Assets.xcassets" / "AppIcon.appiconset"

    if not assets_dir.exists():
        print(f"Error: Assets directory not found: {assets_dir}")
        print("Please run this script from the Paint-my-town project root.")
        return 1

    print("🎨 Generating Paint My Town App Icons")
    print("=" * 50)
    print(f"Output directory: {assets_dir}")
    print()

    # Generate all icons
    for filename, size in ICON_SIZES.items():
        output_path = assets_dir / filename
        create_placeholder_icon(size, output_path)

    print()
    print("=" * 50)
    print("✅ All icons generated successfully!")
    print()
    print("📝 Next steps:")
    print("1. Review the generated icons")
    print("2. Replace with custom designed icons (optional)")
    print("3. Build your app in Xcode")
    print()
    print("💡 Tip: For production, create custom icons with:")
    print("   - Your app's branding colors")
    print("   - Clear, simple icon design")
    print("   - Professional graphic design tool")

    return 0


if __name__ == "__main__":
    exit(main())
