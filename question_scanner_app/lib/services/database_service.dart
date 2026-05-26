import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';

/// SQLite database service for persisting app data locally.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'question_scanner.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nameBangla TEXT,
        icon TEXT DEFAULT '📚',
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Chapters table
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subjectId INTEGER NOT NULL,
        name TEXT NOT NULL,
        nameBangla TEXT,
        number INTEGER DEFAULT 1,
        FOREIGN KEY (subjectId) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    // Question sets (generated PDFs) table
    await db.execute('''
      CREATE TABLE question_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        chapter TEXT NOT NULL,
        title TEXT NOT NULL,
        pdfPath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        totalQuestions INTEGER DEFAULT 0,
        mcqCount INTEGER DEFAULT 0,
        sqCount INTEGER DEFAULT 0,
        cqCount INTEGER DEFAULT 0
      )
    ''');

    // Seed default subjects
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    for (final subject in DefaultData.subjects) {
      final subjectId = await db.insert('subjects', {
        'name': subject.name,
        'nameBangla': subject.nameBangla,
        'icon': subject.icon,
      });

      for (final chapter in subject.chapters) {
        await db.insert('chapters', {
          'subjectId': subjectId,
          'name': chapter.name,
          'nameBangla': chapter.nameBangla,
          'number': chapter.number,
        });
      }
    }
  }

  // ── Subject CRUD ──────────────────────────────────────────────

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final subjects = await db.query('subjects', orderBy: 'name ASC');
    final result = <Subject>[];

    for (final s in subjects) {
      final chapters = await getChaptersForSubject(s['id'] as int);
      result.add(Subject.fromMap(s).copyWith(chapters: chapters));
    }
    return result;
  }

  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return db.insert('subjects', subject.toMap());
  }

  Future<void> deleteSubject(int id) async {
    final db = await database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
    await db.delete('chapters', where: 'subjectId = ?', whereArgs: [id]);
  }

  // ── Chapter CRUD ──────────────────────────────────────────────

  Future<List<Chapter>> getChaptersForSubject(int subjectId) async {
    final db = await database;
    final rows = await db.query(
      'chapters',
      where: 'subjectId = ?',
      whereArgs: [subjectId],
      orderBy: 'number ASC',
    );
    return rows.map(Chapter.fromMap).toList();
  }

  Future<int> insertChapter(Chapter chapter) async {
    final db = await database;
    return db.insert('chapters', chapter.toMap());
  }

  Future<void> deleteChapter(int id) async {
    final db = await database;
    await db.delete('chapters', where: 'id = ?', whereArgs: [id]);
  }

  // ── Question Set CRUD ─────────────────────────────────────────

  Future<int> insertQuestionSet(QuestionSet qs) async {
    final db = await database;
    return db.insert('question_sets', qs.toMap());
  }

  Future<List<QuestionSet>> getAllQuestionSets() async {
    final db = await database;
    final rows = await db.query('question_sets', orderBy: 'createdAt DESC');
    return rows.map(QuestionSet.fromMap).toList();
  }

  Future<List<QuestionSet>> getQuestionSetsBySubject(String subject) async {
    final db = await database;
    final rows = await db.query(
      'question_sets',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'createdAt DESC',
    );
    return rows.map(QuestionSet.fromMap).toList();
  }

  Future<void> deleteQuestionSet(int id) async {
    final db = await database;
    await db.delete('question_sets', where: 'id = ?', whereArgs: [id]);
  }
}
