#!/bin/bash

# Generate placeholder app icons for Paint My Town
# This creates minimal valid PNG files for each required size

set -e

ASSETS_DIR="PaintMyTown/Assets.xcassets/AppIcon.appiconset"

# Check if we're in the right directory
if [ ! -d "$ASSETS_DIR" ]; then
    echo "Error: Run this script from the Paint-my-town project root"
    exit 1
fi

echo "🎨 Generating placeholder app icons..."
echo "======================================"

# Function to create a solid color PNG using base64 encoded data
create_icon() {
    local filename=$1
    local size=$2
    local output="$ASSETS_DIR/$filename"

    # Use Python to create a simple PNG if available
    if command -v python3 &> /dev/null; then
        python3 << EOF
import struct
import zlib

def create_png(width, height, color_rgb):
    """Create a simple solid color PNG"""

    # PNG signature
    png = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_chunk = b'IHDR' + ihdr_data
    ihdr_crc = struct.pack('>I', zlib.crc32(ihdr_chunk))
    png += struct.pack('>I', len(ihdr_data)) + ihdr_chunk + ihdr_crc

    # Create image data (solid color)
    r, g, b = color_rgb
    row = b'\x00' + bytes([r, g, b] * width)  # Filter byte + RGB pixels
    idat_raw = row * height
    idat_compressed = zlib.compress(idat_raw, 9)

    idat_chunk = b'IDAT' + idat_compressed
    idat_crc = struct.pack('>I', zlib.crc32(idat_chunk))
    png += struct.pack('>I', len(idat_compressed)) + idat_chunk + idat_crc

    # IEND chunk
    iend_chunk = b'IEND'
    iend_crc = struct.pack('>I', zlib.crc32(iend_chunk))
    png += struct.pack('>I', 0) + iend_chunk + iend_crc

    return png

# Create icon with blue color (#3498DB)
png_data = create_png($size, $size, (52, 152, 219))

with open('$output', 'wb') as f:
    f.write(png_data)

print('✓ Created $filename (${size}x$size)')
EOF
    else
        # Fallback: create a minimal PNG placeholder
        # This is a 1x1 blue pixel PNG encoded in base64
        # We'll just copy it for all sizes (not ideal but will pass validation)
        MINI_PNG="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        echo "$MINI_PNG" | base64 -d > "$output"
        echo "⚠️  Created minimal placeholder: $filename (${size}x$size)"
    fi
}

# Icon sizes (filename:size)
declare -A ICONS=(
    # iPhone
    ["icon-20@2x.png"]=40
    ["icon-20@3x.png"]=60
    ["icon-29@2x.png"]=58
    ["icon-29@3x.png"]=87
    ["icon-40@2x.png"]=80
    ["icon-40@3x.png"]=120
    ["icon-60@2x.png"]=120
    ["icon-60@3x.png"]=180

    # iPad
    ["icon-20.png"]=20
    ["icon-20@2x-ipad.png"]=40
    ["icon-29.png"]=29
    ["icon-29@2x-ipad.png"]=58
    ["icon-40.png"]=40
    ["icon-40@2x-ipad.png"]=80
    ["icon-76.png"]=76
    ["icon-76@2x.png"]=152
    ["icon-83.5@2x.png"]=167

    # App Store
    ["icon-1024.png"]=1024
)

# Generate all icons
for filename in "${!ICONS[@]}"; do
    size=${ICONS[$filename]}
    create_icon "$filename" "$size"
done

echo ""
echo "======================================"
echo "✅ Icon generation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Icons are generated in: $ASSETS_DIR/"
echo "2. Build your app in Xcode (should now pass validation)"
echo "3. For production: replace with professionally designed icons"
echo ""
echo "💡 Production icons should have:"
echo "   - Consistent branding across all sizes"
echo "   - Clear, simple design that works at small sizes"
echo "   - No transparency (solid background)"
echo "   - Rounded corners are added by iOS automatically"
echo ""
echo "🎨 You can create custom icons using:"
echo "   - Figma, Sketch, or Adobe Illustrator"
echo "   - Online tools like appicon.co or makeappicon.com"
echo "   - Icon generators in Xcode"

