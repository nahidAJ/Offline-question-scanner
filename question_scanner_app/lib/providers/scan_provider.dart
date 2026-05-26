import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/ocr_service.dart';
import '../services/docx_service.dart';
import '../services/pdf_reader_service.dart';
import '../services/question_extractor_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../models/subject.dart';

enum ScanStep { selectSubject, uploadFiles, scanning, preview, generating, done }
enum FileStatus { pending, scanning, done, error }

class ScannedFile {
  final String path;
  final String name;
  final String extension;
  FileStatus status;
  String rawText;
  String? errorMessage;
  int extractedCount;

  ScannedFile({
    required this.path,
    required this.name,
    required this.extension,
    this.status = FileStatus.pending,
    this.rawText = '',
    this.errorMessage,
    this.extractedCount = 0,
  });

  String get displayExtension => extension.toUpperCase();

  bool get isImage => ['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(extension.toLowerCase());
  bool get isPdf => extension.toLowerCase() == 'pdf';
  bool get isDocx => extension.toLowerCase() == 'docx';
}

class ScanProvider extends ChangeNotifier {
  // Services
  final OcrService _ocrService = OcrService();
  final DocxService _docxService = DocxService();
  final QuestionExtractorService _extractor = QuestionExtractorService();
  final PdfGeneratorService _pdfGenerator = PdfGeneratorService();
  final StorageService _storage = StorageService();

  // Workflow state
  ScanStep _step = ScanStep.selectSubject;
  String _selectedSubject = '';
  String _selectedChapter = '';
  String _pdfTitle = '';
  String _examDuration = '';
  String _totalMarks = '';
  String _instituteName = '';

  // Files
  final List<ScannedFile> _files = [];

  // Extracted questions
  List<Question> _questions = [];
  List<Question> _selectedQuestions = [];

  // Progress
  String _progressMessage = '';
  double _progressValue = 0;
  bool _isProcessing = false;

  // Generated PDF
  String? _generatedPdfPath;
  String? _lastError;

  // Getters
  ScanStep get step => _step;
  String get selectedSubject => _selectedSubject;
  String get selectedChapter => _selectedChapter;
  String get pdfTitle => _pdfTitle;
  String get examDuration => _examDuration;
  String get totalMarks => _totalMarks;
  String get instituteName => _instituteName;
  List<ScannedFile> get files => List.unmodifiable(_files);
  List<Question> get questions => List.unmodifiable(_questions);
  List<Question> get selectedQuestions => List.unmodifiable(_selectedQuestions);
  String get progressMessage => _progressMessage;
  double get progressValue => _progressValue;
  bool get isProcessing => _isProcessing;
  String? get generatedPdfPath => _generatedPdfPath;
  String? get lastError => _lastError;

  int get mcqCount => _selectedQuestions.where((q) => q.type == QuestionType.mcq).length;
  int get sqCount => _selectedQuestions.where((q) => q.type == QuestionType.shortQuestion).length;
  int get cqCount => _selectedQuestions.where((q) => q.type == QuestionType.creativeQuestion).length;

  // ── Workflow Navigation ───────────────────────────────────────

  void setSubjectAndChapter(String subject, String chapter) {
    _selectedSubject = subject;
    _selectedChapter = chapter;
    _pdfTitle = '$subject - $chapter';
    _step = ScanStep.uploadFiles;
    notifyListeners();
  }

  void setPdfMetadata({String? title, String? duration, String? marks, String? institute}) {
    if (title != null) _pdfTitle = title;
    if (duration != null) _examDuration = duration;
    if (marks != null) _totalMarks = marks;
    if (institute != null) _instituteName = institute;
    notifyListeners();
  }

  void goBack() {
    switch (_step) {
      case ScanStep.uploadFiles:
        _step = ScanStep.selectSubject;
        _clearFiles();
        break;
      case ScanStep.scanning:
        _step = ScanStep.uploadFiles;
        _isProcessing = false;
        break;
      case ScanStep.preview:
        _step = ScanStep.uploadFiles;
        _questions = [];
        _selectedQuestions = [];
        break;
      case ScanStep.generating:
        break;
      case ScanStep.done:
        _step = ScanStep.preview;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void resetAll() {
    _step = ScanStep.selectSubject;
    _selectedSubject = '';
    _selectedChapter = '';
    _pdfTitle = '';
    _examDuration = '';
    _totalMarks = '';
    _instituteName = '';
    _questions = [];
    _selectedQuestions = [];
    _generatedPdfPath = null;
    _lastError = null;
    _isProcessing = false;
    _progressValue = 0;
    _progressMessage = '';
    _clearFiles();
    notifyListeners();
  }

  // ── File Management ───────────────────────────────────────────

  void addFiles(List<String> paths) {
    for (final path in paths) {
      final name = path.split('/').last;
      final ext = name.contains('.') ? name.split('.').last : 'unknown';

      // Avoid duplicates
      if (_files.any((f) => f.path == path)) continue;

      _files.add(ScannedFile(
        path: path,
        name: name,
        extension: ext,
      ));
    }
    notifyListeners();
  }

  void removeFile(int index) {
    if (index < _files.length) {
      _files.removeAt(index);
      notifyListeners();
    }
  }

  void _clearFiles() {
    _files.clear();
  }

  // ── Scanning ─────────────────────────────────────────────────

  Future<void> startScanning() async {
    if (_files.isEmpty) return;
    _step = ScanStep.scanning;
    _isProcessing = true;
    _questions = [];
    _selectedQuestions = [];
    _lastError = null;
    notifyListeners();

    final allQuestions = <Question>[];
    final total = _files.length;

    try {
      for (int i = 0; i < _files.length; i++) {
        final file = _files[i];
        _setProgress(
          'স্ক্যান করা হচ্ছে: ${file.name}',
          (i / total),
        );
        file.status = FileStatus.scanning;
        notifyListeners();

        try {
          String rawText = '';

          if (file.isImage) {
            rawText = await _ocrService.preprocessAndRecognize(file.path);
          } else if (file.isPdf) {
            final readerService = PdfReaderService(ocrService: _ocrService);
            final result = await readerService.extractText(
              file.path,
              onProgress: (page, total) {
                _setProgress(
                  '${file.name}: পৃষ্ঠা $page/$total',
                  (i + page / total) / total,
                );
              },
            );
            rawText = result.text;
          } else if (file.isDocx) {
            rawText = await _docxService.extractText(file.path);
          }

          file.rawText = rawText;

          // Extract questions from raw text
          final fileQuestions = _extractor.extractQuestions(
            rawText,
            sourceFile: file.name,
          );

          file.extractedCount = fileQuestions.length;
          file.status = FileStatus.done;
          allQuestions.addAll(fileQuestions);
        } catch (e) {
          file.status = FileStatus.error;
          file.errorMessage = e.toString();
        }

        notifyListeners();
      }

      // Merge and renumber
      _questions = _extractor.mergeAndRenumber(allQuestions);
      _selectedQuestions = List.from(_questions); // Select all by default

      _setProgress('স্ক্যান সম্পন্ন! ${_questions.length} টি প্রশ্ন পাওয়া গেছে।', 1.0);
      _step = ScanStep.preview;
    } catch (e) {
      _lastError = 'স্ক্যান ব্যর্থ হয়েছে: $e';
      _step = ScanStep.uploadFiles;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ── Question Selection ────────────────────────────────────────

  void toggleQuestion(Question q) {
    final idx = _selectedQuestions.indexWhere((s) => s.id == q.id);
    if (idx >= 0) {
      _selectedQuestions.removeAt(idx);
    } else {
      _selectedQuestions.add(q);
    }
    notifyListeners();
  }

  bool isQuestionSelected(Question q) {
    return _selectedQuestions.any((s) => s.id == q.id);
  }

  void selectAll() {
    _selectedQuestions = List.from(_questions);
    notifyListeners();
  }

  void deselectAll() {
    _selectedQuestions = [];
    notifyListeners();
  }

  void selectByType(QuestionType type) {
    final ofType = _questions.where((q) => q.type == type).toList();
    for (final q in ofType) {
      if (!isQuestionSelected(q)) _selectedQuestions.add(q);
    }
    notifyListeners();
  }

  // ── PDF Generation ────────────────────────────────────────────

  Future<void> generatePdf({bool includeMcqSheet = true}) async {
    if (_selectedQuestions.isEmpty) return;

    _step = ScanStep.generating;
    _isProcessing = true;
    _setProgress('PDF তৈরি হচ্ছে...', 0.3);
    notifyListeners();

    try {
      final pdfBytes = await _pdfGenerator.generatePdf(
        questions: _selectedQuestions,
        subject: _selectedSubject,
        chapter: _selectedChapter,
        title: _pdfTitle.isEmpty ? '$_selectedSubject - $_selectedChapter' : _pdfTitle,
        examDuration: _examDuration.isEmpty ? null : _examDuration,
        totalMarks: _totalMarks.isEmpty ? null : _totalMarks,
        instituteName: _instituteName.isEmpty ? null : _instituteName,
        includeMcqAnswerSheet: includeMcqSheet,
      );

      _setProgress('সংরক্ষণ করা হচ্ছে...', 0.8);

      final timestamp = DateTime.now();
      final fileName =
          '${_selectedSubject}_${_selectedChapter}_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}';

      final result = await _storage.savePdf(
        pdfBytes: pdfBytes,
        subject: _selectedSubject,
        chapter: _selectedChapter,
        fileName: fileName,
      );

      if (result.success) {
        _generatedPdfPath = result.filePath;

        // Save to database
        await DatabaseService.instance.insertQuestionSet(QuestionSet(
          subject: _selectedSubject,
          chapter: _selectedChapter,
          title: _pdfTitle,
          pdfPath: result.filePath!,
          createdAt: timestamp,
          totalQuestions: _selectedQuestions.length,
          mcqCount: mcqCount,
          sqCount: sqCount,
          cqCount: cqCount,
        ));

        _setProgress('PDF সফলভাবে তৈরি হয়েছে!', 1.0);
        _step = ScanStep.done;
      } else {
        _lastError = result.message;
        _step = ScanStep.preview;
      }
    } catch (e) {
      _lastError = 'PDF তৈরি ব্যর্থ: $e';
      _step = ScanStep.preview;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> openGeneratedPdf() async {
    if (_generatedPdfPath != null) {
      await _storage.openPdf(_generatedPdfPath!);
    }
  }

  void _setProgress(String message, double value) {
    _progressMessage = message;
    _progressValue = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
