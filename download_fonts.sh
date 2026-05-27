#!/bin/bash
# ============================================================
# Font Downloader for Question Scanner App
# Run this script once before building the app
# ============================================================

echo "📥 Downloading fonts for Question Scanner App..."

FONTS_DIR="assets/fonts"
mkdir -p "$FONTS_DIR"

# Download Noto Sans Bengali (supports Bangla script)
echo "Downloading NotoSansBengali-Regular..."
curl -L "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansBengali/NotoSansBengali-Regular.ttf" \
     -o "$FONTS_DIR/NotoSansBengali-Regular.ttf"

echo "Downloading NotoSansBengali-Bold..."
curl -L "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansBengali/NotoSansBengali-Bold.ttf" \
     -o "$FONTS_DIR/NotoSansBengali-Bold.ttf"

# Download Noto Sans (Latin / English)
echo "Downloading NotoSans-Regular..."
curl -L "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf" \
     -o "$FONTS_DIR/NotoSans-Regular.ttf"

echo "Downloading NotoSans-Bold..."
curl -L "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans-Bold.ttf" \
     -o "$FONTS_DIR/NotoSans-Bold.ttf"

echo ""
echo "✅ All fonts downloaded to $FONTS_DIR/"
echo ""
ls -lh "$FONTS_DIR/"
