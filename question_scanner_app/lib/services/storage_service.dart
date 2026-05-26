import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

/// Handles all file system operations: organizing, saving, and opening generated PDFs.
/// Directory structure: InternalStorage/QuestionScanner/Subject/Chapter/PDFs/
class StorageService {
  static const String _rootFolderName = 'QuestionScanner';

  /// Request all necessary storage permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 30) {
        // Android 11+: Manage External Storage
        final status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          final result = await Permission.manageExternalStorage.request();
          return result.isGranted;
        }
        return status.isGranted;
      } else if (androidInfo >= 29) {
        // Android 10
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return status.isGranted;
      } else {
        // Android 9 and below
        final status = await [
          Permission.storage,
          Permission.readExternalStorage,
        ].request();
        return status[Permission.storage]?.isGranted ?? false;
      }
    }
    return true;
  }

  Future<int> _getAndroidVersion() async {
    try {
      // Read Android SDK version from system properties
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30;
    }
  }

  /// Get or create root directory for question scanner
  Future<Directory> getRootDirectory() async {
    Directory? baseDir;

    try {
      // Try external storage first (visible in file manager)
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories();
        if (dirs != null && dirs.isNotEmpty) {
          // Get actual external storage root
          String path = dirs.first.path;
          // Navigate up to the root of external storage
          while (!path.endsWith('Android') && path.length > 1) {
            path = path.substring(0, path.lastIndexOf('/'));
          }
          // Go up one more to get storage root
          if (path.endsWith('Android')) {
            path = path.substring(0, path.lastIndexOf('/'));
          }
          baseDir = Directory('$path/$_rootFolderName');
        }
      }
    } catch (_) {}

    // Fall back to app documents directory
    baseDir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/$_rootFolderName');

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    return baseDir;
  }

  /// Get the directory for a specific subject and chapter
  Future<Directory> getChapterDirectory({
    required String subject,
    required String chapter,
  }) async {
    final root = await getRootDirectory();
    final sanitizedSubject = _sanitizeFolderName(subject);
    final sanitizedChapter = _sanitizeFolderName(chapter);

    final dir = Directory('${root.path}/$sanitizedSubject/$sanitizedChapter');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save generated PDF bytes to organized storage
  Future<SaveResult> savePdf({
    required Uint8List pdfBytes,
    required String subject,
    required String chapter,
    required String fileName,
  }) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        return SaveResult(
          success: false,
          message: 'স্টোরেজ অনুমতি প্রয়োজন। Storage permission required.',
        );
      }

      final dir = await getChapterDirectory(subject: subject, chapter: chapter);
      final sanitizedName = _sanitizeFolderName(fileName);
      final filePath = '${dir.path}/$sanitizedName.pdf';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return SaveResult(
        success: true,
        filePath: filePath,
        message: 'PDF সংরক্ষিত হয়েছে!\n$filePath',
      );
    } catch (e) {
      return SaveResult(
        success: false,
        message: 'সংরক্ষণ ব্যর্থ হয়েছে: $e',
      );
    }
  }

  /// Open a PDF file with the device's default PDF viewer
  Future<bool> openPdf(String filePath) async {
    try {
      final result = await OpenFile.open(filePath, type: 'application/pdf');
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  /// List all saved PDFs organized by subject/chapter
  Future<Map<String, Map<String, List<SavedPdf>>>> listAllPdfs() async {
    final root = await getRootDirectory();
    final result = <String, Map<String, List<SavedPdf>>>{};

    if (!await root.exists()) return result;

    await for (final subjectDir in root.list()) {
      if (subjectDir is! Directory) continue;
      final subject = subjectDir.path.split('/').last;
      result[subject] = {};

      await for (final chapterDir in subjectDir.list()) {
        if (chapterDir is! Directory) continue;
        final chapter = chapterDir.path.split('/').last;
        final pdfs = <SavedPdf>[];

        await for (final file in chapterDir.list()) {
          if (file is File && file.path.endsWith('.pdf')) {
            final stat = await file.stat();
            pdfs.add(SavedPdf(
              path: file.path,
              name: file.path.split('/').last.replaceAll('.pdf', ''),
              subject: subject,
              chapter: chapter,
              size: stat.size,
              modified: stat.modified,
            ));
          }
        }

        if (pdfs.isNotEmpty) {
          pdfs.sort((a, b) => b.modified.compareTo(a.modified));
          result[subject]![chapter] = pdfs;
        }
      }
    }

    return result;
  }

  /// Delete a saved PDF
  Future<bool> deletePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get total storage used by the app
  Future<int> getTotalStorageUsed() async {
    try {
      final root = await getRootDirectory();
      int total = 0;
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) {
          total += (await entity.stat()).size;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class SaveResult {
  final bool success;
  final String? filePath;
  final String message;

  SaveResult({required this.success, this.filePath, required this.message});
}

class SavedPdf {
  final String path;
  final String name;
  final String subject;
  final String chapter;
  final int size;
  final DateTime modified;

  SavedPdf({
    required this.path,
    required this.name,
    required this.subject,
    required this.chapter,
    required this.size,
    required this.modified,
  });
}
