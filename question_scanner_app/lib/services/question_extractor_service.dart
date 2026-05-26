import 'dart:math';
import '../models/question.dart';

/// Service responsible for parsing raw OCR/extracted text into structured questions.
/// Supports both Bangla and English question formats including MCQ, SQ, and CQ.
class QuestionExtractorService {
  // Bangla/English MCQ option patterns
  static final _mcqOptionPattern = RegExp(
    r'^([ক-ঘ]|[Aa]|[Bb]|[Cc]|[Dd]|[abcd])\s*[.)।]\s*(.+)',
    multiLine: true,
  );

  // CQ part patterns (ক, খ, গ, ঘ with marks)
  static final _cqPartPattern = RegExp(
    r'^([ক-ঘ])\s*[.)।]\s*(.+?)(?:\s*[\[(](\d+)\s*(?:নম্বর|marks?|মার্কস?)?[\])])?$',
    multiLine: true,
    caseSensitive: false,
  );

  // Question number patterns (Bangla & English numerals)
  static final _questionNumberPattern = RegExp(
    r'^(?:প্রশ্ন\s*)?(\d+|[০-৯]+)\s*[.)।।\s]',
    multiLine: true,
  );

  // MCQ section headers
  static final _mcqSectionPattern = RegExp(
    r'(?:বহু\s*নির্বাচনি|MCQ|Multiple\s*Choice|এমসিকিউ|বহুনির্বাচনি)',
    caseSensitive: false,
  );

  // SQ section headers
  static final _sqSectionPattern = RegExp(
    r'(?:সংক্ষিপ্ত\s*প্রশ্ন|Short\s*Question|SQ|অতি\s*সংক্ষিপ্ত|সাধারণ\s*প্রশ্ন)',
    caseSensitive: false,
  );

  // CQ section headers
  static final _cqSectionPattern = RegExp(
    r'(?:সৃজনশীল\s*প্রশ্ন|Creative\s*Question|CQ|রচনামূলক|দীর্ঘ\s*উত্তর)',
    caseSensitive: false,
  );

  // Math detection
  static final _mathPattern = RegExp(
    r'(?:[∫∑∏√±×÷≤≥≠∞∂∇∆α-ωΑ-Ω]|sin|cos|tan|log|lim|dx|dy|d\/dx|[a-z]\^[0-9]|\d+\/\d+|[\(\)\[\]\{\}]{2,})',
    caseSensitive: false,
  );

  // Bangla numeral mapping
  static const _banglaToEnglish = {
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
  };

  static String normalizeBanglaNumber(String s) {
    return s.split('').map((c) => _banglaToEnglish[c] ?? c).join();
  }

  /// Main entry point: parse a block of text into structured questions
  List<Question> extractQuestions(String rawText, {required String sourceFile}) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final questions = <Question>[];

    // Try to detect sections
    QuestionType? currentSection;
    List<String> currentBlock = [];
    String currentNumber = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Detect section headers
      if (_mcqSectionPattern.hasMatch(line)) {
        if (currentBlock.isNotEmpty) {
          _flushBlock(currentBlock, currentNumber, currentSection, sourceFile, questions);
          currentBlock = [];
        }
        currentSection = QuestionType.mcq;
        continue;
      }
      if (_sqSectionPattern.hasMatch(line)) {
        if (currentBlock.isNotEmpty) {
          _flushBlock(currentBlock, currentNumber, currentSection, sourceFile, questions);
          currentBlock = [];
        }
        currentSection = QuestionType.shortQuestion;
        continue;
      }
      if (_cqSectionPattern.hasMatch(line)) {
        if (currentBlock.isNotEmpty) {
          _flushBlock(currentBlock, currentNumber, currentSection, sourceFile, questions);
          currentBlock = [];
        }
        currentSection = QuestionType.creativeQuestion;
        continue;
      }

      // Detect question number start
      final qMatch = _questionNumberPattern.firstMatch(line);
      if (qMatch != null) {
        if (currentBlock.isNotEmpty) {
          _flushBlock(currentBlock, currentNumber, currentSection, sourceFile, questions);
        }
        currentNumber = qMatch.group(1) ?? '?';
        currentBlock = [line.substring(qMatch.end).trim()];
      } else {
        currentBlock.add(line);
      }
    }

    // Flush last block
    if (currentBlock.isNotEmpty) {
      _flushBlock(currentBlock, currentNumber, currentSection, sourceFile, questions);
    }

    // If no structured sections detected, try heuristic parsing
    if (questions.isEmpty) {
      return _heuristicParse(rawText, sourceFile);
    }

    return questions;
  }

  void _flushBlock(
    List<String> block,
    String number,
    QuestionType? section,
    String sourceFile,
    List<Question> out,
  ) {
    if (block.isEmpty) return;

    final text = block.join(' ').trim();
    if (text.length < 5) return;

    // Detect type from content if section not set
    final type = section ?? _detectType(block);
    final id = _generateId();

    switch (type) {
      case QuestionType.mcq:
        final q = _parseMcq(text, number, id, sourceFile);
        if (q != null) out.add(q);
        break;
      case QuestionType.creativeQuestion:
        final q = _parseCq(block, number, id, sourceFile);
        if (q != null) out.add(q);
        break;
      default:
        out.add(Question(
          id: id,
          type: type,
          number: number.isEmpty ? '?' : number,
          text: text,
          sourceFile: sourceFile,
          hasMath: _mathPattern.hasMatch(text),
        ));
    }
  }

  QuestionType _detectType(List<String> block) {
    final joined = block.join(' ');

    // MCQ: has option patterns like ক. / A. / (a)
    final optionCount = _mcqOptionPattern.allMatches(joined).length;
    if (optionCount >= 2) return QuestionType.mcq;

    // CQ: has ক. খ. গ. ঘ. structure
    final cqCount = _cqPartPattern.allMatches(joined).length;
    if (cqCount >= 2) return QuestionType.creativeQuestion;

    // SQ: short question
    if (joined.length < 200) return QuestionType.shortQuestion;

    return QuestionType.unknown;
  }

  Question? _parseMcq(String text, String number, String id, String sourceFile) {
    final options = <McqOption>[];
    final optionMatches = _mcqOptionPattern.allMatches(text);

    String questionText = text;
    int firstOptionIndex = text.length;

    for (final match in optionMatches) {
      if (match.start < firstOptionIndex) {
        firstOptionIndex = match.start;
      }
      options.add(McqOption(
        label: match.group(1)!,
        text: match.group(2)!.trim(),
      ));
    }

    if (options.isNotEmpty) {
      questionText = text.substring(0, firstOptionIndex).trim();
    }

    if (questionText.length < 3 && options.isEmpty) return null;

    return Question(
      id: id,
      type: QuestionType.mcq,
      number: number.isEmpty ? '?' : number,
      text: questionText,
      mcqOptions: options,
      sourceFile: sourceFile,
      hasMath: _mathPattern.hasMatch(text),
    );
  }

  Question? _parseCq(List<String> block, String number, String id, String sourceFile) {
    final parts = <CqPart>[];
    String? stem;
    List<String> stemLines = [];
    bool inParts = false;

    for (final line in block) {
      final partMatch = _cqPartPattern.firstMatch(line);
      if (partMatch != null) {
        if (!inParts && stemLines.isNotEmpty) {
          stem = stemLines.join(' ').trim();
        }
        inParts = true;
        parts.add(CqPart(
          label: partMatch.group(1)!,
          marks: partMatch.group(3) ?? '',
          text: partMatch.group(2)!.trim(),
        ));
      } else if (!inParts) {
        stemLines.add(line);
      } else {
        // Append to last part
        if (parts.isNotEmpty) {
          final last = parts.last;
          parts[parts.length - 1] = CqPart(
            label: last.label,
            marks: last.marks,
            text: '${last.text} $line',
          );
        }
      }
    }

    if (stemLines.isNotEmpty && stem == null) {
      stem = stemLines.join(' ').trim();
    }

    final mainText = stem ?? block.first;

    return Question(
      id: id,
      type: QuestionType.creativeQuestion,
      number: number.isEmpty ? '?' : number,
      text: mainText,
      stem: stem,
      cqParts: parts,
      sourceFile: sourceFile,
      hasMath: _mathPattern.hasMatch(block.join(' ')),
    );
  }

  List<Question> _heuristicParse(String rawText, String sourceFile) {
    final questions = <Question>[];
    final paragraphs = rawText.split(RegExp(r'\n{2,}'));

    for (int i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i].trim();
      if (para.length < 10) continue;

      final type = _detectType(para.split('\n'));
      final id = _generateId();

      if (type == QuestionType.mcq) {
        final q = _parseMcq(para, '${i + 1}', id, sourceFile);
        if (q != null) questions.add(q);
      } else if (type == QuestionType.creativeQuestion) {
        final q = _parseCq(para.split('\n'), '${i + 1}', id, sourceFile);
        if (q != null) questions.add(q);
      } else {
        questions.add(Question(
          id: id,
          type: type,
          number: '${i + 1}',
          text: para,
          sourceFile: sourceFile,
          hasMath: _mathPattern.hasMatch(para),
        ));
      }
    }

    return questions;
  }

  static String _generateId() {
    final rand = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        rand.nextInt(9999).toString().padLeft(4, '0');
  }

  /// Merge questions from multiple sources, renumbering them
  List<Question> mergeAndRenumber(List<Question> allQuestions) {
    final mcqs = allQuestions.where((q) => q.type == QuestionType.mcq).toList();
    final sqs = allQuestions.where((q) => q.type == QuestionType.shortQuestion).toList();
    final cqs = allQuestions.where((q) => q.type == QuestionType.creativeQuestion).toList();
    final others = allQuestions.where((q) => q.type == QuestionType.unknown).toList();

    final merged = <Question>[];
    int counter = 1;

    for (final q in mcqs) {
      merged.add(q.copyWith(number: counter.toString()));
      counter++;
    }
    counter = 1;
    for (final q in sqs) {
      merged.add(q.copyWith(number: counter.toString()));
      counter++;
    }
    counter = 1;
    for (final q in cqs) {
      merged.add(q.copyWith(number: counter.toString()));
      counter++;
    }
    merged.addAll(others);

    return merged;
  }
}
