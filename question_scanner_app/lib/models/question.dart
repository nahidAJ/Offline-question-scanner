import 'package:flutter/material.dart';

enum QuestionType { mcq, shortQuestion, creativeQuestion, unknown }

class McqOption {
  final String label;
  final String text;

  McqOption({required this.label, required this.text});

  Map<String, dynamic> toMap() => {'label': label, 'text': text};

  factory McqOption.fromMap(Map<String, dynamic> map) =>
      McqOption(label: map['label'], text: map['text']);
}

class CqPart {
  final String label;
  final String marks;
  final String text;

  CqPart({required this.label, required this.marks, required this.text});

  Map<String, dynamic> toMap() =>
      {'label': label, 'marks': marks, 'text': text};

  factory CqPart.fromMap(Map<String, dynamic> map) =>
      CqPart(label: map['label'], marks: map['marks'], text: map['text']);
}

class Question {
  final String id;
  final QuestionType type;
  final String number;
  final String text;
  final List<McqOption> mcqOptions;
  final List<CqPart> cqParts;
  final String? stem;
  final bool hasMath;
  final String sourceFile;

  Question({
    required this.id,
    required this.type,
    required this.number,
    required this.text,
    this.mcqOptions = const [],
    this.cqParts = const [],
    this.stem,
    this.hasMath = false,
    required this.sourceFile,
  });

  String get typeLabel {
    switch (type) {
      case QuestionType.mcq:            return 'MCQ';
      case QuestionType.shortQuestion:  return 'SQ';
      case QuestionType.creativeQuestion: return 'CQ';
      case QuestionType.unknown:        return 'General';
    }
  }

  Color get typeColor {
    switch (type) {
      case QuestionType.mcq:            return const Color(0xFF1565C0);
      case QuestionType.shortQuestion:  return const Color(0xFF2E7D32);
      case QuestionType.creativeQuestion: return const Color(0xFFE65100);
      case QuestionType.unknown:        return const Color(0xFF6A1B9A);
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'number': number,
    'text': text,
    'stem': stem,
    'hasMath': hasMath ? 1 : 0,
    'sourceFile': sourceFile,
  };

  Question copyWith({
    QuestionType? type,
    String? number,
    String? text,
    List<McqOption>? mcqOptions,
    List<CqPart>? cqParts,
    String? stem,
    bool? hasMath,
  }) {
    return Question(
      id: id,
      type: type ?? this.type,
      number: number ?? this.number,
      text: text ?? this.text,
      mcqOptions: mcqOptions ?? this.mcqOptions,
      cqParts: cqParts ?? this.cqParts,
      stem: stem ?? this.stem,
      hasMath: hasMath ?? this.hasMath,
      sourceFile: sourceFile,
    );
  }
}
