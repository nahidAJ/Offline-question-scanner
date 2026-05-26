class Subject {
  final int? id;
  final String name;
  final String nameBangla;
  final String icon;
  final List<Chapter> chapters;

  Subject({
    this.id,
    required this.name,
    required this.nameBangla,
    required this.icon,
    this.chapters = const [],
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'nameBangla': nameBangla,
    'icon': icon,
  };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id: map['id'],
    name: map['name'],
    nameBangla: map['nameBangla'] ?? '',
    icon: map['icon'] ?? '📚',
  );

  Subject copyWith({int? id, String? name, String? nameBangla, String? icon, List<Chapter>? chapters}) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      nameBangla: nameBangla ?? this.nameBangla,
      icon: icon ?? this.icon,
      chapters: chapters ?? this.chapters,
    );
  }
}

class Chapter {
  final int? id;
  final int? subjectId;
  final String name;
  final String nameBangla;
  final int number;

  Chapter({
    this.id,
    this.subjectId,
    required this.name,
    required this.nameBangla,
    required this.number,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'subjectId': subjectId,
    'name': name,
    'nameBangla': nameBangla,
    'number': number,
  };

  factory Chapter.fromMap(Map<String, dynamic> map) => Chapter(
    id: map['id'],
    subjectId: map['subjectId'],
    name: map['name'],
    nameBangla: map['nameBangla'] ?? '',
    number: map['number'] ?? 1,
  );
}

class QuestionSet {
  final int? id;
  final String subject;
  final String chapter;
  final String title;
  final String pdfPath;
  final DateTime createdAt;
  final int totalQuestions;
  final int mcqCount;
  final int sqCount;
  final int cqCount;

  QuestionSet({
    this.id,
    required this.subject,
    required this.chapter,
    required this.title,
    required this.pdfPath,
    required this.createdAt,
    required this.totalQuestions,
    required this.mcqCount,
    required this.sqCount,
    required this.cqCount,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'subject': subject,
    'chapter': chapter,
    'title': title,
    'pdfPath': pdfPath,
    'createdAt': createdAt.toIso8601String(),
    'totalQuestions': totalQuestions,
    'mcqCount': mcqCount,
    'sqCount': sqCount,
    'cqCount': cqCount,
  };

  factory QuestionSet.fromMap(Map<String, dynamic> map) => QuestionSet(
    id: map['id'],
    subject: map['subject'],
    chapter: map['chapter'],
    title: map['title'],
    pdfPath: map['pdfPath'],
    createdAt: DateTime.parse(map['createdAt']),
    totalQuestions: map['totalQuestions'] ?? 0,
    mcqCount: map['mcqCount'] ?? 0,
    sqCount: map['sqCount'] ?? 0,
    cqCount: map['cqCount'] ?? 0,
  );
}

// Default subjects for Bangladesh education system
class DefaultData {
  static final List<Subject> subjects = [
    Subject(name: 'Higher Mathematics', nameBangla: 'উচ্চতর গণিত', icon: '📐', chapters: [
      Chapter(name: 'Differentiation', nameBangla: 'অন্তরীকলন', number: 1),
      Chapter(name: 'Integration', nameBangla: 'যোগজীকরণ', number: 2),
      Chapter(name: 'Complex Numbers', nameBangla: 'জটিল সংখ্যা', number: 3),
      Chapter(name: 'Vectors', nameBangla: 'ভেক্টর', number: 4),
      Chapter(name: 'Probability', nameBangla: 'সম্ভাবনা', number: 5),
    ]),
    Subject(name: 'Physics', nameBangla: 'পদার্থবিজ্ঞান', icon: '⚛️', chapters: [
      Chapter(name: 'Motion', nameBangla: 'গতিবিদ্যা', number: 1),
      Chapter(name: 'Forces', nameBangla: 'বল ও গতির সূত্র', number: 2),
      Chapter(name: 'Waves', nameBangla: 'তরঙ্গ ও শব্দ', number: 3),
      Chapter(name: 'Electricity', nameBangla: 'তড়িৎ', number: 4),
      Chapter(name: 'Optics', nameBangla: 'আলোকবিজ্ঞান', number: 5),
    ]),
    Subject(name: 'Chemistry', nameBangla: 'রসায়ন', icon: '🧪', chapters: [
      Chapter(name: 'Periodic Table', nameBangla: 'পর্যায় সারণি', number: 1),
      Chapter(name: 'Chemical Bonding', nameBangla: 'রাসায়নিক বন্ধন', number: 2),
      Chapter(name: 'Organic Chemistry', nameBangla: 'জৈব রসায়ন', number: 3),
      Chapter(name: 'Acids & Bases', nameBangla: 'এসিড ও ক্ষার', number: 4),
    ]),
    Subject(name: 'Biology', nameBangla: 'জীববিজ্ঞান', icon: '🧬', chapters: [
      Chapter(name: 'Cell Biology', nameBangla: 'কোষ জীববিজ্ঞান', number: 1),
      Chapter(name: 'Genetics', nameBangla: 'জিনতত্ত্ব', number: 2),
      Chapter(name: 'Ecology', nameBangla: 'বাস্তুবিদ্যা', number: 3),
      Chapter(name: 'Human Body', nameBangla: 'মানবদেহ', number: 4),
    ]),
    Subject(name: 'Bangla', nameBangla: 'বাংলা', icon: '📖', chapters: [
      Chapter(name: 'Poetry', nameBangla: 'কবিতা', number: 1),
      Chapter(name: 'Prose', nameBangla: 'গদ্য', number: 2),
      Chapter(name: 'Grammar', nameBangla: 'ব্যাকরণ', number: 3),
    ]),
    Subject(name: 'English', nameBangla: 'ইংরেজি', icon: '🔤', chapters: [
      Chapter(name: 'Reading', nameBangla: 'পঠন', number: 1),
      Chapter(name: 'Grammar', nameBangla: 'ব্যাকরণ', number: 2),
      Chapter(name: 'Writing', nameBangla: 'রচনা', number: 3),
    ]),
    Subject(name: 'ICT', nameBangla: 'তথ্য ও যোগাযোগ প্রযুক্তি', icon: '💻', chapters: [
      Chapter(name: 'Number System', nameBangla: 'সংখ্যা পদ্ধতি', number: 1),
      Chapter(name: 'Programming', nameBangla: 'প্রোগ্রামিং', number: 2),
      Chapter(name: 'Database', nameBangla: 'ডেটাবেজ', number: 3),
      Chapter(name: 'Web Development', nameBangla: 'ওয়েব ডিজাইন', number: 4),
    ]),
    Subject(name: 'Economics', nameBangla: 'অর্থনীতি', icon: '📊', chapters: [
      Chapter(name: 'Microeconomics', nameBangla: 'ব্যষ্টিক অর্থনীতি', number: 1),
      Chapter(name: 'Macroeconomics', nameBangla: 'সামষ্টিক অর্থনীতি', number: 2),
    ]),
  ];
}
