import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final allSets = appProv.questionSets;

    final filtered = _searchQuery.isEmpty
        ? allSets
        : allSets
            .where((qs) =>
                qs.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                qs.chapter.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                qs.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Group by subject
    final grouped = <String, List<QuestionSet>>{};
    for (final qs in filtered) {
      grouped.putIfAbsent(qs.subject, () => []).add(qs);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('লাইব্রেরি / Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => appProv.refreshLibrary(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'বিষয় বা অধ্যায় খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Stats summary
          if (allSets.isNotEmpty)
            _buildSummaryBar(allSets),

          // Content
          Expanded(
            child: appProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: grouped.keys.length,
                        itemBuilder: (_, i) {
                          final subject = grouped.keys.elementAt(i);
                          final sets = grouped[subject]!;
                          return _buildSubjectGroup(context, subject, sets, appProv);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<QuestionSet> sets) {
    final totalPdfs = sets.length;
    final totalMcq = sets.fold<int>(0, (sum, s) => sum + s.mcqCount);
    final totalSq = sets.fold<int>(0, (sum, s) => sum + s.sqCount);
    final totalCq = sets.fold<int>(0, (sum, s) => sum + s.cqCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.secondaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('PDFs', '$totalPdfs', Icons.picture_as_pdf),
          _summaryItem('MCQ', '$totalMcq', Icons.radio_button_checked),
          _summaryItem('SQ', '$totalSq', Icons.short_text),
          _summaryItem('CQ', '$totalCq', Icons.article),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildSubjectGroup(
    BuildContext context,
    String subject,
    List<QuestionSet> sets,
    AppProvider appProv,
  ) {
    // Find subject icon
    final subjectData = appProv.subjects.firstWhere(
      (s) => s.name == subject,
      orElse: () => Subject(name: subject, nameBangla: subject, icon: '📚'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(subjectData.icon, style: const TextStyle(fontSize: 24)),
          title: Text(
            subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            '${sets.length} টি প্রশ্নপত্র',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          initiallyExpanded: true,
          children: sets.map((qs) => _buildPdfTile(context, qs, appProv)).toList(),
        ),
      ),
    );
  }

  Widget _buildPdfTile(
    BuildContext context,
    QuestionSet qs,
    AppProvider appProv,
  ) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(qs.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
        ),
        title: Text(
          qs.chapter,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Row(
              children: [
                _miniChip('MCQ ${qs.mcqCount}', Colors.blue),
                const SizedBox(width: 4),
                _miniChip('SQ ${qs.sqCount}', Colors.green),
                const SizedBox(width: 4),
                _miniChip('CQ ${qs.cqCount}', Colors.orange),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'open') {
              await _storage.openPdf(qs.pdfPath);
            } else if (v == 'delete') {
              _showDeleteDialog(context, qs, appProv);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(children: [
                Icon(Icons.open_in_new, size: 18),
                SizedBox(width: 8),
                Text('খুলুন'),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('মুছুন', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
        onTap: () => _storage.openPdf(qs.pdfPath),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'কোনো PDF নেই',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'প্রশ্নপত্র স্ক্যান করুন এবং PDF তৈরি করুন',
            style: TextStyle(color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, QuestionSet qs, AppProvider appProv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('মুছে ফেলবেন?'),
        content: Text('"${qs.chapter}" প্রশ্নপত্রটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await appProv.deleteQuestionSet(qs);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('মুছে ফেলা হয়েছে')),
                );
              }
            },
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
  }
}
