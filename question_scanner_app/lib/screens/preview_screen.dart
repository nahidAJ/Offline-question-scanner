import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/question_preview_card.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';

  final tabs = [
    ('সব', 'all', Icons.list_alt),
    ('MCQ', 'mcq', Icons.radio_button_checked),
    ('SQ', 'sq', Icons.short_text),
    ('CQ', 'cq', Icons.article),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _filter = tabs[_tabController.index].$2;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Question> _filterQuestions(List<Question> all) {
    switch (_filter) {
      case 'mcq':
        return all.where((q) => q.type == QuestionType.mcq).toList();
      case 'sq':
        return all.where((q) => q.type == QuestionType.shortQuestion).toList();
      case 'cq':
        return all.where((q) => q.type == QuestionType.creativeQuestion).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ScanProvider>();
    final filtered = _filterQuestions(prov.questions);
    final selected = prov.selectedQuestions.length;
    final total = prov.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('প্রশ্ন প্রিভিউ ($selected/$total নির্বাচিত)'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'all') prov.selectAll();
              if (v == 'none') prov.deselectAll();
              if (v == 'mcq') prov.selectByType(QuestionType.mcq);
              if (v == 'sq') prov.selectByType(QuestionType.shortQuestion);
              if (v == 'cq') prov.selectByType(QuestionType.creativeQuestion);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('সব নির্বাচন করুন')),
              const PopupMenuItem(value: 'none', child: Text('বাতিল করুন')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'mcq', child: Text('শুধু MCQ')),
              const PopupMenuItem(value: 'sq', child: Text('শুধু SQ')),
              const PopupMenuItem(value: 'cq', child: Text('শুধু CQ')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: tabs
              .map((t) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$3, size: 16),
                        const SizedBox(width: 4),
                        Text(t.$1),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final q = filtered[i];
                      return QuestionPreviewCard(
                        question: q,
                        isSelected: prov.isQuestionSelected(q),
                        onToggle: () => prov.toggleQuestion(q),
                        expanded: true,
                      );
                    },
                  ),
          ),
          _buildBottomBar(context, prov),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'এই ধরনের কোনো প্রশ্ন নেই',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ScanProvider prov) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${prov.selectedQuestions.length} নির্বাচিত',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'MCQ: ${prov.mcqCount} | SQ: ${prov.sqCount} | CQ: ${prov.cqCount}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: prov.selectedQuestions.isEmpty
                ? null
                : () {
                    Navigator.pop(context);
                    prov.generatePdf();
                  },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF তৈরি করুন'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }
}
