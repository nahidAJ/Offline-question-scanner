import 'package:flutter/material.dart';
import '../models/question.dart';

class QuestionPreviewCard extends StatefulWidget {
  final Question question;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool expanded;

  const QuestionPreviewCard({
    super.key,
    required this.question,
    required this.isSelected,
    required this.onToggle,
    this.expanded = false,
  });

  @override
  State<QuestionPreviewCard> createState() => _QuestionPreviewCardState();
}

class _QuestionPreviewCardState extends State<QuestionPreviewCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded;
  }

  Color get _typeColor {
    switch (widget.question.type) {
      case QuestionType.mcq:
        return const Color(0xFF1565C0);
      case QuestionType.shortQuestion:
        return const Color(0xFF2E7D32);
      case QuestionType.creativeQuestion:
        return const Color(0xFFE65100);
      case QuestionType.unknown:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData get _typeIcon {
    switch (widget.question.type) {
      case QuestionType.mcq:
        return Icons.radio_button_checked;
      case QuestionType.shortQuestion:
        return Icons.short_text;
      case QuestionType.creativeQuestion:
        return Icons.article;
      case QuestionType.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isSelected ? _typeColor : Colors.grey.shade200,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isSelected
                  ? _typeColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                children: [
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected ? _typeColor : Colors.transparent,
                      border: Border.all(
                        color: widget.isSelected ? _typeColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon, size: 12, color: _typeColor),
                        const SizedBox(width: 4),
                        Text(
                          q.typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Question number
                  Text(
                    '#${q.number}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),

                  // Math indicator
                  if (q.hasMath)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: 'গাণিতিক সূত্র',
                        child: Icon(Icons.functions, size: 16, color: Colors.purple.shade400),
                      ),
                    ),

                  // Source file
                  Flexible(
                    child: Text(
                      q.sourceFile,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Expand toggle
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Question text
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 0, 12, 10),
              child: Text(
                q.text,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontFamily: 'NotoSansBengali',
                ),
                maxLines: _isExpanded ? null : 2,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              // MCQ options
              if (q.type == QuestionType.mcq && q.mcqOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 0, 12, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: q.mcqOptions.map((opt) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${opt.label}) ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _typeColor,
                                fontSize: 12,
                                fontFamily: 'NotoSansBengali',
                              ),
                            ),
                            TextSpan(
                              text: opt.text,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontFamily: 'NotoSansBengali',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),

              // CQ stem + parts
              if (q.type == QuestionType.creativeQuestion) ...[
                if (q.stem != null && q.stem!.isNotEmpty && q.stem != q.text)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(44, 0, 12, 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        q.stem!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansBengali',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                if (q.cqParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(44, 0, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: q.cqParts.map((part) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${part.label}) ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                  fontSize: 13,
                                  fontFamily: 'NotoSansBengali',
                                ),
                              ),
                              TextSpan(
                                text: part.text,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                  fontFamily: 'NotoSansBengali',
                                ),
                              ),
                              if (part.marks.isNotEmpty)
                                TextSpan(
                                  text: '  [${part.marks}]',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
              ],

              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}
