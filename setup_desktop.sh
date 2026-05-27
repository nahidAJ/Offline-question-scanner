#!/bin/bash
# ============================================================
# Desktop Setup Script for Question Scanner
# Run this ONCE before building the desktop app.
# ============================================================

set -e

OS="$(uname -s)"
echo "🖥️  Setting up Question Scanner for Desktop..."
echo "Detected OS: $OS"
echo ""

mkdir -p assets/tessdata
mkdir -p assets/fonts

# ── STEP 1: Download fonts (if not already done) ─────────────
if [ ! -f "assets/fonts/NotoSansBengali-Regular.ttf" ]; then
    echo "📥 Downloading fonts..."
    bash download_fonts.sh
else
    echo "✅ Fonts already downloaded."
fi

# ── STEP 2: Install Tesseract OCR ────────────────────────────
echo ""
echo "📥 Checking Tesseract OCR..."

if command -v tesseract &> /dev/null; then
    echo "✅ Tesseract already installed: $(tesseract --version 2>&1 | head -1)"
else
    if [[ "$OS" == "Darwin" ]]; then
        echo "Installing Tesseract via Homebrew..."
        brew install tesseract tesseract-lang

    elif [[ "$OS" == "Linux" ]]; then
        echo "Installing Tesseract via apt..."
        sudo apt-get update
        sudo apt-get install -y tesseract-ocr tesseract-ocr-ben tesseract-ocr-eng

    elif [[ "$OS" == MINGW* ]] || [[ "$OS" == CYGWIN* ]] || [[ "$OS" == MSYS* ]]; then
        echo "Windows detected."
        echo ""
        echo "Please install Tesseract manually:"
        echo "  Option 1 (recommended): winget install UB-Mannheim.TesseractOCR"
        echo "  Option 2: Download from https://github.com/UB-Mannheim/tesseract/wiki"
        echo ""
        echo "After installing:"
        echo "  1. Add Tesseract to PATH (usually C:\\Program Files\\Tesseract-OCR)"
        echo "  2. Download Bangla language file (ben.traineddata) from:"
        echo "     https://github.com/tesseract-ocr/tessdata/raw/main/ben.traineddata"
        echo "  3. Place ben.traineddata in:"
        echo "     C:\\Program Files\\Tesseract-OCR\\tessdata\\"
        echo ""
    fi
fi

# ── STEP 3: Download Bangla tessdata (Linux/macOS fallback) ───
if [[ "$OS" == "Linux" ]] || [[ "$OS" == "Darwin" ]]; then
    TESSDATA_DIR=""
    POSSIBLE_DIRS=(
        "/usr/share/tesseract-ocr/4.00/tessdata"
        "/usr/share/tesseract-ocr/5/tessdata"
        "/usr/share/tessdata"
        "/opt/homebrew/share/tessdata"
        "/usr/local/share/tessdata"
    )

    for dir in "${POSSIBLE_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            TESSDATA_DIR="$dir"
            break
        fi
    done

    if [ -n "$TESSDATA_DIR" ]; then
        if [ ! -f "$TESSDATA_DIR/ben.traineddata" ]; then
            echo "📥 Downloading Bangla (ben) tessdata..."
            curl -L "https://github.com/tesseract-ocr/tessdata/raw/main/ben.traineddata" \
                 -o "$TESSDATA_DIR/ben.traineddata"
            echo "✅ Bangla tessdata installed."
        else
            echo "✅ Bangla tessdata already present."
        fi
    fi
fi

# ── STEP 4: Enable desktop platform ──────────────────────────
echo ""
echo "⚙️  Enabling Flutter desktop platform..."
if [[ "$OS" == "Darwin" ]]; then
    flutter config --enable-macos-desktop
elif [[ "$OS" == "Linux" ]]; then
    flutter config --enable-linux-desktop
else
    flutter config --enable-windows-desktop
fi

# ── STEP 5: Get Flutter packages ─────────────────────────────
echo ""
echo "📦 Getting Flutter packages..."
flutter pub get

# ── STEP 6: Build ─────────────────────────────────────────────
echo ""
echo "🔨 Building desktop application..."
if [[ "$OS" == "Darwin" ]]; then
    flutter build macos --release
    echo ""
    echo "✅ macOS app: build/macos/Build/Products/Release/question_scanner.app"
    echo "   Drag to /Applications to install."

elif [[ "$OS" == "Linux" ]]; then
    flutter build linux --release
    echo ""
    echo "✅ Linux app: build/linux/x64/release/bundle/question_scanner"
    echo "   Run:  ./build/linux/x64/release/bundle/question_scanner"

else
    echo "For Windows, run in PowerShell:"
    echo "   flutter build windows --release"
    echo ""
    echo "App will be at: build\\windows\\x64\\runner\\Release\\question_scanner.exe"
fi

echo ""
echo "🎉 Desktop setup complete!"
