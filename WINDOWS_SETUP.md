# 🖥️ Windows Desktop Setup Guide

## Step-by-step instructions to run Question Scanner on Windows

---

## Prerequisites

- Windows 10 or 11 (64-bit)
- Flutter SDK installed → https://docs.flutter.dev/get-started/install/windows

---

## Step 1 — Install Tesseract OCR (for image/PDF scanning)

Open **PowerShell as Administrator** and run:

```powershell
winget install UB-Mannheim.TesseractOCR
```

OR download the installer from:
https://github.com/UB-Mannheim/tesseract/wiki

During installation:
- ✅ Check "Additional language data (download)" 
- ✅ Select **Bengali** from the language list
- ✅ Add Tesseract to PATH

---

## Step 2 — Install Bangla language data (if not done during install)

Download `ben.traineddata` from:
https://github.com/tesseract-ocr/tessdata/raw/main/ben.traineddata

Place it at:
```
C:\Program Files\Tesseract-OCR\tessdata\ben.traineddata
```

---

## Step 3 — Enable Windows desktop Flutter support

Open PowerShell in the project folder:

```powershell
flutter config --enable-windows-desktop
```

---

## Step 4 — Download fonts and get packages

```powershell
# Download Bangla fonts (needs internet once)
bash download_fonts.sh

# Get Flutter dependencies
flutter pub get
```

---

## Step 5 — Build the Windows .exe

```powershell
flutter build windows --release
```

The app will be built at:
```
build\windows\x64\runner\Release\question_scanner.exe
```

To run it, just double-click `question_scanner.exe`.

---

## Step 6 — (Optional) Create a Desktop Shortcut

Right-click `question_scanner.exe` → **Send to** → **Desktop (create shortcut)**

---

## ✅ Features on Desktop

| Feature | Desktop | Android |
|---|---|---|
| OCR (image scanning) | ✅ Tesseract | ✅ ML Kit |
| Bangla OCR | ✅ (with ben.traineddata) | ✅ |
| DOCX reading | ✅ | ✅ |
| PDF reading | ✅ | ✅ |
| PDF generation | ✅ | ✅ |
| Drag & drop files | ✅ | ❌ |
| Keyboard shortcuts | ✅ | ❌ |
| Sidebar navigation | ✅ | ❌ |
| File browser | ✅ | ✅ |
| Save to Documents | ✅ | ✅ |

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + N` | New scan |
| `Ctrl + L` | Open library |
| `Ctrl + B` | Toggle sidebar |

You can also **drag and drop** PDF/JPG/PNG/DOCX files directly onto the app window.

---

## Storage Location on Windows

Generated PDFs are saved to:
```
C:\Users\YourName\Documents\QuestionScanner\
    Higher_Mathematics\
        Differentiation\
            Higher_Mathematics_Differentiation_20250523_1430.pdf
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| "tesseract not found" | Make sure Tesseract is in PATH. Restart app after installing. |
| Bangla not detected | Install ben.traineddata (Step 2 above) |
| App won't open | Install Visual C++ Redistributable 2019+ |
| flutter build fails | Run `flutter doctor` and fix any issues |
