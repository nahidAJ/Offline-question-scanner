import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DatabaseService _db = DatabaseService.instance;

  List<Subject> _subjects = [];
  List<QuestionSet> _questionSets = [];
  bool _isLoading = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<QuestionSet> get questionSets => List.unmodifiable(_questionSets);
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadSubjects(),
      _loadQuestionSets(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSubjects() async {
    _subjects = await _db.getAllSubjects();
  }

  Future<void> _loadQuestionSets() async {
    _questionSets = await _db.getAllQuestionSets();
  }

  Future<void> refreshLibrary() async {
    await _loadQuestionSets();
    notifyListeners();
  }

  Future<void> addSubject(String name, String nameBangla, String icon) async {
    final id = await _db.insertSubject(Subject(
      name: name,
      nameBangla: nameBangla,
      icon: icon,
    ));
    await _loadSubjects();
    notifyListeners();
  }

  Future<void> addChapter(int subjectId, String name, String nameBangla, int number) async {
    await _db.insertChapter(Chapter(
      subjectId: subjectId,
      name: name,
      nameBangla: nameBangla,
      number: number,
    ));
    await _loadSubjects();
    notifyListeners();
  }

  Future<void> deleteQuestionSet(QuestionSet qs) async {
    if (qs.id != null) {
      await _db.deleteQuestionSet(qs.id!);
      await _storage.deletePdf(qs.pdfPath);
      await _loadQuestionSets();
      notifyListeners();
    }
  }

  List<Subject> searchSubjects(String query) {
    if (query.isEmpty) return _subjects;
    final q = query.toLowerCase();
    return _subjects.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.nameBangla.contains(q)
    ).toList();
  }

  List<Chapter> getChaptersForSubject(String subjectName) {
    final subject = _subjects.firstWhere(
      (s) => s.name == subjectName,
      orElse: () => Subject(name: '', nameBangla: '', icon: ''),
    );
    return subject.chapters;
  }
}
