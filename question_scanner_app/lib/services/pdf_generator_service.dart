import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/question.dart';

/// Generates clean, printable A4 PDFs from extracted questions.
/// Supports Bangla and English text with proper formatting.
class PdfGeneratorService {
  pw.Font? _banglaFont;
  pw.Font? _banglaBoldFont;
  pw.Font? _latinFont;
  pw.Font? _latinBoldFont;

  bool _fontsLoaded = false;

  Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    try {
      final banglaData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      final banglaBoldData = await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
      final latinData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final latinBoldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

      _banglaFont = pw.Font.ttf(banglaData);
      _banglaBoldFont = pw.Font.ttf(banglaBoldData);
      _latinFont = pw.Font.ttf(latinData);
      _latinBoldFont = pw.Font.ttf(latinBoldData);
      _fontsLoaded = true;
    } catch (e) {
      // Fall back to built-in fonts if assets not found
      _banglaFont = pw.Font.helvetica();
      _banglaBoldFont = pw.Font.helveticaBold();
      _latinFont = pw.Font.helvetica();
      _latinBoldFont = pw.Font.helveticaBold();
      _fontsLoaded = true;
    }
  }

  pw.TextStyle get _bodyStyle => pw.TextStyle(
    font: _banglaFont,
    fontSize: 11,
    lineSpacing: 4,
  );

  pw.TextStyle get _boldStyle => pw.TextStyle(
    font: _banglaBoldFont,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );

  pw.TextStyle get _headerStyle => pw.TextStyle(
    font: _banglaBoldFont,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue900,
  );

  pw.TextStyle get _subHeaderStyle => pw.TextStyle(
    font: _banglaBoldFont,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey800,
  );

  pw.TextStyle get _sectionStyle => pw.TextStyle(
    font: _banglaBoldFont,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  );

  pw.TextStyle get _numberStyle => pw.TextStyle(
    font: _banglaBoldFont,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );

  pw.TextStyle get _optionStyle => pw.TextStyle(
    font: _banglaFont,
    fontSize: 10.5,
    lineSpacing: 3,
  );

  pw.TextStyle get _smallStyle => pw.TextStyle(
    font: _banglaFont,
    fontSize: 9,
    color: PdfColors.grey600,
  );

  /// Generate the complete printable PDF
  Future<Uint8List> generatePdf({
    required List<Question> questions,
    required String subject,
    required String chapter,
    required String title,
    String? examDuration,
    String? totalMarks,
    String? instituteName,
    bool includeMcqAnswerSheet = true,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final pageFormat = PdfPageFormat.a4;
    const margin = 30.0; // ~1.06 cm margins

    final mcqs = questions.where((q) => q.type == QuestionType.mcq).toList();
    final sqs = questions.where((q) => q.type == QuestionType.shortQuestion).toList();
    final cqs = questions.where((q) => q.type == QuestionType.creativeQuestion).toList();
    final others = questions.where((q) => q.type == QuestionType.unknown).toList();

    // ── PAGE 1: Title / Header ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        header: (context) => _buildPageHeader(subject, chapter, context),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          _buildTitleSection(
            title: title,
            subject: subject,
            chapter: chapter,
            instituteName: instituteName,
            examDuration: examDuration,
            totalMarks: totalMarks,
            mcqCount: mcqs.length,
            sqCount: sqs.length,
            cqCount: cqs.length,
          ),
          pw.SizedBox(height: 16),

          // MCQ Section
          if (mcqs.isNotEmpty) ...[
            _buildSectionHeader('বহু নির্বাচনি প্রশ্ন (MCQ)', mcqs.length),
            pw.SizedBox(height: 8),
            ...mcqs.map((q) => _buildMcqQuestion(q, mcqs.indexOf(q) + 1)),
            pw.SizedBox(height: 16),
          ],

          // SQ Section
          if (sqs.isNotEmpty) ...[
            _buildSectionHeader('সংক্ষিপ্ত প্রশ্ন (Short Questions)', sqs.length),
            pw.SizedBox(height: 8),
            ...sqs.map((q) => _buildSqQuestion(q, sqs.indexOf(q) + 1)),
            pw.SizedBox(height: 16),
          ],

          // CQ Section
          if (cqs.isNotEmpty) ...[
            _buildSectionHeader('সৃজনশীল প্রশ্ন (Creative Questions)', cqs.length),
            pw.SizedBox(height: 8),
            ...cqs.map((q) => _buildCqQuestion(q, cqs.indexOf(q) + 1)),
            pw.SizedBox(height: 16),
          ],

          // Other / General Questions
          if (others.isNotEmpty) ...[
            _buildSectionHeader('অন্যান্য প্রশ্ন', others.length),
            pw.SizedBox(height: 8),
            ...others.map((q) => _buildGenericQuestion(q, others.indexOf(q) + 1)),
          ],

          // MCQ Answer Sheet
          if (includeMcqAnswerSheet && mcqs.isNotEmpty) ...[
            pw.NewPage(),
            _buildMcqAnswerSheet(mcqs.length),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPageHeader(String subject, String chapter, pw.Context context) {
    if (context.pageNumber == 1) return pw.SizedBox();
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$subject — $chapter', style: _smallStyle),
          pw.Text('পৃষ্ঠা ${context.pageNumber}', style: _smallStyle),
        ],
      ),
      pw.Divider(color: PdfColors.grey400, height: 4),
      pw.SizedBox(height: 4),
    ]);
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey400, height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by Question Scanner App', style: _smallStyle),
          pw.Text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}', style: _smallStyle),
        ],
      ),
    ]);
  }

  pw.Widget _buildTitleSection({
    required String title,
    required String subject,
    required String chapter,
    String? instituteName,
    String? examDuration,
    String? totalMarks,
    required int mcqCount,
    required int sqCount,
    required int cqCount,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue900, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(children: [
        // Top colored bar
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(3),
              topRight: pw.Radius.circular(3),
            ),
          ),
          child: pw.Center(
            child: pw.Text(
              instituteName ?? 'প্রশ্নপত্র — Question Paper',
              style: pw.TextStyle(
                font: _banglaBoldFont,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(subject, style: _headerStyle),
              pw.SizedBox(height: 4),
              pw.Text('অধ্যায়: $chapter', style: _subHeaderStyle),
              if (title.isNotEmpty && title != subject) ...[
                pw.SizedBox(height: 4),
                pw.Text(title, style: _bodyStyle),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  if (examDuration != null)
                    _infoChip('সময়', examDuration),
                  if (totalMarks != null)
                    _infoChip('মোট নম্বর', totalMarks),
                  _infoChip('MCQ', '$mcqCount টি'),
                  _infoChip('SQ', '$sqCount টি'),
                  _infoChip('CQ', '$cqCount টি'),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }

  pw.Widget _infoChip(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: _banglaFont, fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(font: _banglaBoldFont, fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildSectionHeader(String title, int count) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: _sectionStyle),
          pw.Text('[$count টি প্রশ্ন]',
              style: pw.TextStyle(font: _banglaFont, fontSize: 10, color: PdfColors.white70)),
        ],
      ),
    );
  }

  pw.Widget _buildMcqQuestion(Question q, int index) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Question text
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: '$index. ', style: _numberStyle),
                pw.TextSpan(text: q.text, style: _bodyStyle),
              ],
            ),
          ),
          // Options
          if (q.mcqOptions.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, top: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: _buildMcqOptionsRow(q.mcqOptions),
              ),
            ),
          pw.SizedBox(height: 2),
        ],
      ),
    );
  }

  List<pw.Widget> _buildMcqOptionsRow(List<McqOption> options) {
    // Display 2 options per row for 4 options, 1 per row otherwise
    if (options.length == 4) {
      return [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _optionWidget(options[0]),
              _optionWidget(options[2]),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _optionWidget(options[1]),
              _optionWidget(options[3]),
            ],
          ),
        ),
      ];
    }
    return options.map(_optionWidget).toList();
  }

  pw.Widget _optionWidget(McqOption opt) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '${opt.label}. ',
            style: pw.TextStyle(font: _banglaBoldFont, fontSize: 10.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: opt.text, style: _optionStyle),
        ],
      ),
    );
  }

  pw.Widget _buildSqQuestion(Question q, int index) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: PdfColors.teal700, width: 3)),
        ),
        padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$index. ', style: _numberStyle),
              pw.TextSpan(text: q.text, style: _bodyStyle),
            ],
          ),
        ),
      ),
    );
  }

  pw.Widget _buildCqQuestion(Question q, int index) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.orange900, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // CQ number header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const pw.BoxDecoration(
                color: PdfColors.orange900,
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(2),
                  topRight: pw.Radius.circular(2),
                ),
              ),
              child: pw.Text(
                'সৃজনশীল প্রশ্ন $index',
                style: pw.TextStyle(font: _banglaBoldFont, fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Stem / Uddipaak
                  if (q.stem != null && q.stem!.isNotEmpty) ...[
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        border: pw.Border.all(color: PdfColors.orange200),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                      child: pw.Text(q.stem!, style: _bodyStyle),
                    ),
                    pw.SizedBox(height: 6),
                  ] else if (q.text.isNotEmpty) ...[
                    pw.Text(q.text, style: _bodyStyle),
                    pw.SizedBox(height: 6),
                  ],

                  // CQ parts ক, খ, গ, ঘ
                  if (q.cqParts.isNotEmpty)
                    ...q.cqParts.map((part) => _buildCqPart(part))
                  else ...[
                    // Default CQ parts if none detected
                    _buildCqPartEmpty('ক', '১'),
                    _buildCqPartEmpty('খ', '২'),
                    _buildCqPartEmpty('গ', '৩'),
                    _buildCqPartEmpty('ঘ', '৪'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCqPart(CqPart part) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '${part.label}) ',
              style: pw.TextStyle(font: _banglaBoldFont, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
            ),
            pw.TextSpan(text: part.text, style: _bodyStyle),
            if (part.marks.isNotEmpty)
              pw.TextSpan(
                text: '  [${part.marks} নম্বর]',
                style: pw.TextStyle(font: _banglaFont, fontSize: 9, color: PdfColors.grey600),
              ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCqPartEmpty(String label, String marks) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label) ',
              style: pw.TextStyle(font: _banglaBoldFont, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
            ),
            pw.TextSpan(text: '......................................................................', style: _bodyStyle),
            pw.TextSpan(
              text: '  [$marks নম্বর]',
              style: pw.TextStyle(font: _banglaFont, fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildGenericQuestion(Question q, int index) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$index. ', style: _numberStyle),
            pw.TextSpan(text: q.text, style: _bodyStyle),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildMcqAnswerSheet(int count) {
    final cols = 5;
    final rows = (count / cols).ceil();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          child: pw.Text(
            'MCQ উত্তরপত্র — Answer Sheet',
            style: pw.TextStyle(font: _banglaBoldFont, fontSize: 13, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('নাম: _________________________________ রোল: ____________ তারিখ: ____________',
            style: _bodyStyle),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(),
            2: const pw.FlexColumnWidth(),
            3: const pw.FlexColumnWidth(),
            4: const pw.FlexColumnWidth(),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: ['প্রশ্ন', 'ক', 'খ', 'গ', 'ঘ'].map((h) =>
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(h, style: _boldStyle),
                ),
              ).toList(),
            ),
            // Answer rows
            ...List.generate(count, (i) => pw.TableRow(
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${i + 1}', style: _boldStyle),
                ),
                ...['ক', 'খ', 'গ', 'ঘ'].map((opt) =>
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(4),
                    height: 22,
                    child: pw.SizedBox(),
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }
}
