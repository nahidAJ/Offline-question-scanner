import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Handles OCR text recognition from image files using Google ML Kit.
/// Supports Bangla (Devanagari script block) and Latin (English) scripts offline.
class OcrService {
  // ML Kit recognizers — created once, disposed when done
  final TextRecognizer _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final TextRecognizer _devanagariRecognizer =
      TextRecognizer(script: TextRecognitionScript.devanagari);

  bool _disposed = false;

  /// Recognize text from an image file path.
  /// Returns combined text from both Latin and Bengali recognizers.
  Future<String> recognizeFromImageFile(String imagePath) async {
    if (_disposed) throw StateError('OcrService has been disposed');

    final inputImage = InputImage.fromFilePath(imagePath);
    return await _processInputImage(inputImage);
  }

  /// Recognize text from raw bytes (e.g., extracted PDF page image).
  Future<String> recognizeFromBytes(Uint8List bytes, {String? tempFileName}) async {
    if (_disposed) throw StateError('OcrService has been disposed');

    final tempDir = await getTemporaryDirectory();
    final fname = tempFileName ?? 'ocr_tmp_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final tempFile = File('${tempDir.path}/$fname');
    await tempFile.writeAsBytes(bytes);

    try {
      return await recognizeFromImageFile(tempFile.path);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  Future<String> _processInputImage(InputImage inputImage) async {
    // Run both recognizers in parallel for speed
    final results = await Future.wait([
      _latinRecognizer.processImage(inputImage),
      _devanagariRecognizer.processImage(inputImage),
    ]);

    final latinResult = results[0];
    final banglaResult = results[1];

    // Merge blocks from both recognizers, preserving page order
    final allBlocks = <_TextBlock>[];

    for (final block in latinResult.blocks) {
      if (block.text.trim().isNotEmpty) {
        allBlocks.add(_TextBlock(
          text: block.text,
          top: block.boundingBox?.top ?? 0,
          left: block.boundingBox?.left ?? 0,
          script: 'latin',
        ));
      }
    }

    for (final block in banglaResult.blocks) {
      if (block.text.trim().isNotEmpty) {
        allBlocks.add(_TextBlock(
          text: block.text,
          top: block.boundingBox?.top ?? 0,
          left: block.boundingBox?.left ?? 0,
          script: 'bangla',
        ));
      }
    }

    // Sort by vertical position then horizontal
    allBlocks.sort((a, b) {
      final vDiff = a.top.compareTo(b.top);
      if (vDiff.abs() > 30) return vDiff;
      return a.left.compareTo(b.left);
    });

    // Deduplicate (ML Kit may return same text from both recognizers)
    final seen = <String>{};
    final uniqueBlocks = allBlocks.where((b) {
      final key = b.text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    return uniqueBlocks.map((b) => b.text).join('\n');
  }

  /// Pre-process image for better OCR accuracy:
  /// - Convert to grayscale
  /// - Increase contrast
  /// - Sharpen
  Future<String> preprocessAndRecognize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return recognizeFromImageFile(imagePath);

    // Convert to grayscale
    image = img.grayscale(image);

    // Increase contrast
    image = img.contrast(image, contrast: 130);

    // Sharpen
    image = img.sharpen(image, amount: 0.5);

    // If image is very small, upscale for better OCR
    if (image.width < 800) {
      final scale = 800 / image.width;
      image = img.copyResize(
        image,
        width: 800,
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    final processedBytes = img.encodeJpg(image, quality: 95);
    return recognizeFromBytes(Uint8List.fromList(processedBytes));
  }

  void dispose() {
    if (!_disposed) {
      _latinRecognizer.close();
      _devanagariRecognizer.close();
      _disposed = true;
    }
  }
}

class _TextBlock {
  final String text;
  final double top;
  final double left;
  final String script;

  _TextBlock({
    required this.text,
    required this.top,
    required this.left,
    required this.script,
  });
}
