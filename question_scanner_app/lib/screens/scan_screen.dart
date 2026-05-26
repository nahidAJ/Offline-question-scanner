import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/scan_provider.dart';
import '../providers/app_provider.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/file_upload_card.dart';
import '../widgets/question_preview_card.dart';
import '../widgets/progress_overlay.dart';
import '../widgets/subject_chapter_selector.dart';
import 'preview_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  final _instituteController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    _instituteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanProv = context.watch<ScanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রশ্ন স্ক্যানার'),
        actions: [
          if (scanProv.step != ScanStep.selectSubject)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'নতুন শুরু করুন',
              onPressed: () => _showResetDialog(context),
            ),
        ],
        leading: scanProv.step != ScanStep.selectSubject
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: scanProv.isProcessing ? null : () => scanProv.goBack(),
              )
            : null,
      ),
      body: Stack(
        children: [
          _buildStepIndicator(scanProv),
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: _buildCurrentStep(context, scanProv),
          ),
          if (scanProv.isProcessing)
            ProgressOverlay(
              message: scanProv.progressMessage,
              progress: scanProv.progressValue,
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ScanProvider prov) {
    final steps = ['বিষয়', 'ফাইল', 'স্ক্যান', 'প্রিভিউ', 'PDF'];
    final stepIndex = prov.step.index.clamp(0, steps.length - 1);

    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < stepIndex ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            );
          }
          final idx = i ~/ 2;
          final isActive = idx == stepIndex;
          final isDone = idx < stepIndex;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppTheme.successColor
                      : isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, ScanProvider prov) {
    switch (prov.step) {
      case ScanStep.selectSubject:
        return _buildSelectSubjectStep(context, prov);
      case ScanStep.uploadFiles:
        return _buildUploadFilesStep(context, prov);
      case ScanStep.scanning:
        return _buildScanningStep(prov);
      case ScanStep.preview:
        return _buildPreviewStep(context, prov);
      case ScanStep.generating:
        return _buildGeneratingStep(prov);
      case ScanStep.done:
        return _buildDoneStep(context, prov);
    }
  }

  // ── STEP 1: Select Subject & Chapter ─────────────────────────

  Widget _buildSelectSubjectStep(BuildContext context, ScanProvider prov) {
    final appProv = context.watch<AppProvider>();

    return SubjectChapterSelector(
      subjects: appProv.subjects,
      onSelected: (subject, chapter) {
        prov.setSubjectAndChapter(subject, chapter);
      },
    );
  }

  // ── STEP 2: Upload Files ───────────────────────────────────────

  Widget _buildUploadFilesStep(BuildContext context, ScanProvider prov) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject/Chapter info chip
          _buildInfoChip(prov),
          const SizedBox(height: 16),

          // Metadata form
          _buildMetadataForm(prov),
          const SizedBox(height: 16),

          // File upload area
          FileUploadCard(
            files: prov.files,
            onPickFiles: () => _pickFiles(context, prov),
            onRemoveFile: (i) => prov.removeFile(i),
          ),
          const SizedBox(height: 24),

          // Start scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.files.isEmpty ? null : () => prov.startScanning(),
              icon: const Icon(Icons.scanner),
              label: Text(
                'স্ক্যান শুরু করুন (${prov.files.length} টি ফাইল)',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ScanProvider prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.book, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${prov.selectedSubject} › ${prov.selectedChapter}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansBengali',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataForm(ScanProvider prov) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'প্রশ্নপত্রের তথ্য (ঐচ্ছিক)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'শিরোনাম / Title',
                prefixIcon: Icon(Icons.title),
              ),
              onChanged: (v) => prov.setPdfMetadata(title: v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _instituteController,
                    decoration: const InputDecoration(
                      labelText: 'প্রতিষ্ঠানের নাম',
                      prefixIcon: Icon(Icons.school),
                    ),
                    onChanged: (v) => prov.setPdfMetadata(institute: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'সময় / Duration',
                      prefixIcon: Icon(Icons.timer),
                      hintText: 'e.g. ৩ ঘণ্টা',
                    ),
                    onChanged: (v) => prov.setPdfMetadata(duration: v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _marksController,
                    decoration: const InputDecoration(
                      labelText: 'মোট নম্বর / Marks',
                      prefixIcon: Icon(Icons.grade),
                      hintText: 'e.g. ১০০',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => prov.setPdfMetadata(marks: v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context, ScanProvider prov) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'doc'],
      );

      if (result != null && result.paths.isNotEmpty) {
        final paths = result.paths.whereType<String>().toList();
        prov.addFiles(paths);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ফাইল বাছাই ব্যর্থ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── STEP 3: Scanning Progress ─────────────────────────────────

  Widget _buildScanningStep(ScanProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
            const SizedBox(height: 24),
            Text(
              prov.progressMessage,
              style: const TextStyle(fontSize: 16, fontFamily: 'NotoSansBengali'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prov.progressValue,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(prov.progressValue * 100).toInt()}%',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            // File status list
            ...prov.files.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _fileStatusIcon(f.status),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f.name, overflow: TextOverflow.ellipsis)),
                  if (f.status == FileStatus.done)
                    Text(
                      '${f.extractedCount} প্রশ্ন',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _fileStatusIcon(FileStatus status) {
    switch (status) {
      case FileStatus.pending:
        return const Icon(Icons.schedule, color: Colors.grey, size: 18);
      case FileStatus.scanning:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case FileStatus.done:
        return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case FileStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 18);
    }
  }

  // ── STEP 4: Preview & Edit Questions ─────────────────────────

  Widget _buildPreviewStep(BuildContext context, ScanProvider prov) {
    return Column(
      children: [
        // Stats bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _statChip('মোট', prov.questions.length, Colors.blue),
              const SizedBox(width: 8),
              _statChip('MCQ', prov.questions.where((q) => q.type == QuestionType.mcq).length, Colors.indigo),
              const SizedBox(width: 8),
              _statChip('SQ', prov.questions.where((q) => q.type == QuestionType.shortQuestion).length, Colors.green),
              const SizedBox(width: 8),
              _statChip('CQ', prov.questions.where((q) => q.type == QuestionType.creativeQuestion).length, Colors.orange),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PreviewScreen()),
                ),
                child: const Text('বিস্তারিত'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Selection tools
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                '${prov.selectedQuestions.length}/${prov.questions.length} নির্বাচিত',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Spacer(),
              TextButton(onPressed: prov.selectAll, child: const Text('সব')),
              TextButton(onPressed: prov.deselectAll, child: const Text('বাতিল')),
            ],
          ),
        ),

        // Question list
        Expanded(
          child: prov.questions.isEmpty
              ? _buildEmptyQuestions()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: prov.questions.length,
                  itemBuilder: (_, i) {
                    final q = prov.questions[i];
                    return QuestionPreviewCard(
                      question: q,
                      isSelected: prov.isQuestionSelected(q),
                      onToggle: () => prov.toggleQuestion(q),
                    );
                  },
                ),
        ),

        // Generate button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.selectedQuestions.isEmpty
                  ? null
                  : () => prov.generatePdf(),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                'PDF তৈরি করুন (${prov.selectedQuestions.length} টি প্রশ্ন)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'কোনো প্রশ্ন পাওয়া যায়নি',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'ফাইলগুলো পরিষ্কার এবং পাঠযোগ্য কিনা নিশ্চিত করুন',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── STEP 5: Generating ────────────────────────────────────────

  Widget _buildGeneratingStep(ScanProvider prov) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 80, color: AppTheme.accentColor),
          const SizedBox(height: 24),
          Text(
            prov.progressMessage,
            style: const TextStyle(fontSize: 16, fontFamily: 'NotoSansBengali'),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  // ── STEP 6: Done ──────────────────────────────────────────────

  Widget _buildDoneStep(BuildContext context, ScanProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 60, color: AppTheme.successColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'PDF সফলভাবে তৈরি হয়েছে!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansBengali',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (prov.generatedPdfPath != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prov.generatedPdfPath!,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _doneStat('MCQ', prov.mcqCount),
                _doneStat('SQ', prov.sqCount),
                _doneStat('CQ', prov.cqCount),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: prov.openGeneratedPdf,
                icon: const Icon(Icons.open_in_new),
                label: const Text('PDF খুলুন / Open PDF'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: prov.resetAll,
                icon: const Icon(Icons.add),
                label: const Text('নতুন স্ক্যান / New Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneStat(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('নতুন শুরু করবেন?'),
        content: const Text('সকল কাজ মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScanProvider>().resetAll();
            },
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
  }
}
