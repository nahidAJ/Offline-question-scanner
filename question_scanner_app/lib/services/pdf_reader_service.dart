import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'ocr_service.dart';

/// Extracts text from PDF files. Uses Syncfusion's built-in text extraction first.
/// Falls back to OCR on each page image if text extraction yields nothing (scanned PDFs).
class PdfReaderService {
  final OcrService _ocrService;

  PdfReaderService({required OcrService ocrService}) : _ocrService = ocrService;

  /// Extract text from all pages of a PDF
  Future<PdfExtractionResult> extractText(
    String pdfPath, {
    void Function(int page, int total)? onProgress,
  }) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      final allText = StringBuffer();
      bool isScanned = false;
      int emptyPages = 0;

      for (int i = 0; i < pageCount; i++) {
        onProgress?.call(i + 1, pageCount);

        final extractor = PdfTextExtractor(document);
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);

        if (pageText.trim().isEmpty || pageText.trim().length < 20) {
          emptyPages++;
        } else {
          allText.writeln(pageText);
          allText.writeln(); // Page separator
        }
      }

      // If most pages are empty, this is likely a scanned PDF → use OCR
      if (emptyPages > pageCount * 0.7) {
        isScanned = true;
        document.dispose();
        return await _ocrOnPdf(pdfPath, bytes, pageCount, onProgress: onProgress);
      }

      document.dispose();

      return PdfExtractionResult(
        text: allText.toString(),
        pageCount: pageCount,
        wasOcr: false,
        isScanned: false,
      );
    } catch (e) {
      return PdfExtractionResult(
        text: 'Error reading PDF: $e',
        pageCount: 0,
        wasOcr: false,
        isScanned: false,
      );
    }
  }

  /// OCR each page of a PDF by rendering it to an image first
  Future<PdfExtractionResult> _ocrOnPdf(
    String pdfPath,
    Uint8List pdfBytes,
    int pageCount, {
    void Function(int page, int total)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final allText = StringBuffer();

    try {
      final document = PdfDocument(inputBytes: pdfBytes);

      for (int i = 0; i < pageCount; i++) {
        onProgress?.call(i + 1, pageCount);

        try {
          // Render page to bitmap image
          final page = document.pages[i];
          final image = await page.convertToImage(
            imageWidth: 1654, // A4 at 196 DPI
            imageHeight: 2339,
          );

          final imageBytes = image.bytes;
          if (imageBytes != null && imageBytes.isNotEmpty) {
            final imgFile = File('${tempDir.path}/pdf_page_${i + 1}.jpg');
            await imgFile.writeAsBytes(imageBytes);
            final text = await _ocrService.preprocessAndRecognize(imgFile.path);
            if (text.isNotEmpty) {
              allText.writeln('--- Page ${i + 1} ---');
              allText.writeln(text);
              allText.writeln();
            }
            await imgFile.delete();
          }
        } catch (pageError) {
          // Skip failed pages
          continue;
        }
      }

      document.dispose();
    } catch (e) {
      allText.writeln('OCR Error: $e');
    }

    return PdfExtractionResult(
      text: allText.toString(),
      pageCount: pageCount,
      wasOcr: true,
      isScanned: true,
    );
  }
}

class PdfExtractionResult {
  final String text;
  final int pageCount;
  final bool wasOcr;
  final bool isScanned;

  PdfExtractionResult({
    required this.text,
    required this.pageCount,
    required this.wasOcr,
    required this.isScanned,
  });
}
