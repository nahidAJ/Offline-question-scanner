# 📄 Offline Question Paper Scanner & Printable PDF Generator

A **100% offline** Android app for scanning question papers, extracting MCQ/SQ/CQ questions using OCR, and generating printable A4 PDFs with full **Bangla + English** support.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🔴 Offline | No internet required after setup |
| 📷 OCR | Google ML Kit — Bangla + English |
| 📁 Multi-file | PDF, JPG, PNG, DOCX in one batch |
| 🧩 Auto-detect | MCQ, SQ (Short), CQ (Creative) |
| 🔤 Bangla | Full Bangla script OCR + PDF |
| 📐 A4 PDF | Print-ready with margins + fonts |
| 🗂️ Organized | Subject → Chapter → PDF folders |
| 📚 Library | Browse all generated question sets |

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK **3.16+** — [Install Flutter](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter plugin
- Android device / emulator (API 23+, Android 6.0+)

### Step 1 — Clone or Extract the Project
```bash
cd /path/to/your/projects
# If extracted from ZIP:
cd question_scanner_app
```

### Step 2 — Download Bangla Fonts (ONE-TIME, needs internet)
```bash
chmod +x download_fonts.sh
./download_fonts.sh
```
> After this, the app works **100% offline**.

Alternatively, download manually and place in `assets/fonts/`:
- [NotoSansBengali-Regular.ttf](https://fonts.google.com/noto/specimen/Noto+Sans+Bengali)
- [NotoSansBengali-Bold.ttf](https://fonts.google.com/noto/specimen/Noto+Sans+Bengali)
- [NotoSans-Regular.ttf](https://fonts.google.com/noto/specimen/Noto+Sans)
- [NotoSans-Bold.ttf](https://fonts.google.com/noto/specimen/Noto+Sans)

### Step 3 — Install Dependencies
```bash
flutter pub get
```

### Step 4 — Build & Run
```bash
# Run on connected device (debug)
flutter run

# Build APK for distribution
flutter build apk --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📂 Project Structure

```
question_scanner_app/
├── assets/fonts/               ← Bangla + Latin fonts (download first)
├── android/                    ← Android config + permissions
└── lib/
    ├── main.dart               ← Entry point
    ├── app.dart                ← Root widget + theme
    ├── theme/app_theme.dart    ← Material 3 theming
    ├── models/
    │   ├── question.dart       ← MCQ / SQ / CQ data models
    │   └── subject.dart        ← Subject, Chapter, QuestionSet
    ├── providers/
    │   ├── scan_provider.dart  ← Scan workflow state
    │   └── app_provider.dart   ← App-level state + library
    ├── services/
    │   ├── ocr_service.dart           ← ML Kit OCR (Bangla + Latin)
    │   ├── docx_service.dart          ← DOCX text extraction
    │   ├── pdf_reader_service.dart    ← PDF text extraction + OCR fallback
    │   ├── question_extractor_service.dart  ← NLP question parsing
    │   ├── pdf_generator_service.dart ← A4 printable PDF generation
    │   ├── storage_service.dart       ← File system organization
    │   └── database_service.dart      ← SQLite persistence
    ├── screens/
    │   ├── home_screen.dart    ← Main nav (Scan + Library tabs)
    │   ├── scan_screen.dart    ← Step-by-step scan workflow
    │   ├── preview_screen.dart ← Question preview + selection
    │   └── library_screen.dart ← Browse saved PDFs
    └── widgets/
        ├── subject_chapter_selector.dart  ← Subject/chapter picker
        ├── file_upload_card.dart          ← Multi-file upload UI
        ├── question_preview_card.dart     ← Question display card
        └── progress_overlay.dart          ← Processing overlay
```

---

## 📱 App Workflow

```
1. Open App
   └── 2. Select Subject (উচ্চতর গণিত, Physics, etc.)
           └── 3. Select Chapter (Differentiation, etc.)
                   └── 4. Upload Files (PDF/JPG/PNG/DOCX)
                           └── 5. Auto Scan (OCR + text extraction)
                                   └── 6. Preview Questions (MCQ/SQ/CQ)
                                           └── 7. Generate A4 PDF
                                                   └── 8. Saved to Internal Storage
                                                           └── 9. Open / Print
```

---

## 📁 Output Storage

Generated PDFs are saved at:
```
Internal Storage/
└── QuestionScanner/
    └── Higher_Mathematics/
        └── Differentiation/
            └── Higher_Mathematics_Differentiation_20250523_1430.pdf
```

---

## 🔧 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `google_mlkit_text_recognition` | ^0.13.0 | Bangla + English OCR |
| `syncfusion_flutter_pdf` | ^26.1.39 | PDF text extraction |
| `pdf` + `printing` | ^3.10.8 / ^5.13.0 | A4 PDF generation |
| `file_picker` | ^8.0.7 | Multi-file selection |
| `archive` + `xml` | ^3.6.1 / ^6.5.0 | DOCX parsing |
| `sqflite` | ^2.3.3 | Local SQLite database |
| `path_provider` | ^2.1.4 | Storage paths |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `provider` | ^6.1.2 | State management |
| `open_file` | ^3.5.8 | Open PDF in viewer |
| `image` | ^4.2.0 | Image pre-processing |

---

## 📝 Question Types Detected

### MCQ (বহু নির্বাচনি প্রশ্ন)
- Detects options: **ক, খ, গ, ঘ** or **A, B, C, D**
- Preserves option text and labels
- Generates MCQ answer sheet in PDF

### SQ (সংক্ষিপ্ত প্রশ্ন)
- Short answer questions
- Left-border styled in PDF

### CQ (সৃজনশীল প্রশ্ন)
- Detects stem (উদ্দীপক) + parts ক/খ/গ/ঘ
- Extracts marks per part
- Boxed layout in PDF

---

## 🖨️ PDF Features

- ✅ A4 size (210 × 297 mm)
- ✅ 1.06 cm margins
- ✅ Bangla + English fonts (Noto Sans)
- ✅ Subject + Chapter header
- ✅ Institution name, time, marks
- ✅ Sectioned: MCQ → SQ → CQ
- ✅ MCQ answer bubble sheet
- ✅ Page numbers + footer
- ✅ Print-ready

---

## ⚠️ Notes

- **ML Kit Bengali OCR** works offline after the initial model download (happens automatically on first use).
- For best OCR results: use **clear, well-lit photos** of question papers.
- DOCX files are parsed natively — no MS Office required.
- Scanned (image-based) PDFs are OCR'd page-by-page automatically.

---

## 📞 Troubleshooting

| Problem | Solution |
|---|---|
| Font rendering issues | Run `download_fonts.sh` again |
| OCR not detecting Bangla | Ensure ML Kit model downloaded (needs internet once) |
| Permission denied | Go to Settings → Apps → Question Scanner → Permissions → Storage |
| PDF not opening | Install a PDF viewer (Adobe, Google PDF, etc.) |
| DOCX text missing | Ensure file is not password protected |

---

*Built for personal educational use. Supports Bangladesh HSC/SSC curriculum.*
