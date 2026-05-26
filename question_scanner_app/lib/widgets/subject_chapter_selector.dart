import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class SubjectChapterSelector extends StatefulWidget {
  final List<Subject> subjects;
  final void Function(String subject, String chapter) onSelected;

  const SubjectChapterSelector({
    super.key,
    required this.subjects,
    required this.onSelected,
  });

  @override
  State<SubjectChapterSelector> createState() => _SubjectChapterSelectorState();
}

class _SubjectChapterSelectorState extends State<SubjectChapterSelector>
    with SingleTickerProviderStateMixin {
  Subject? _selectedSubject;
  Chapter? _selectedChapter;
  String _searchQuery = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _customSubjectController = TextEditingController();
  final _customChapterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _customSubjectController.dispose();
    _customChapterController.dispose();
    super.dispose();
  }

  List<Subject> get _filteredSubjects {
    if (_searchQuery.isEmpty) return widget.subjects;
    final q = _searchQuery.toLowerCase();
    return widget.subjects.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.nameBangla.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            if (_selectedSubject == null)
              ..._buildSubjectSelection()
            else
              ..._buildChapterSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'প্রশ্নপত্র স্ক্যানার',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansBengali',
                  ),
                ),
                Text(
                  _selectedSubject == null
                      ? 'বিষয় নির্বাচন করুন'
                      : 'অধ্যায় নির্বাচন করুন',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),

        // Breadcrumb
        if (_selectedSubject != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedSubject = null;
                    _selectedChapter = null;
                  }),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 4),
                      Text('বিষয়', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text(
                  '${_selectedSubject!.icon} ${_selectedSubject!.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSubjectSelection() {
    return [
      // Search
      TextField(
        decoration: InputDecoration(
          hintText: 'বিষয় খুঁজুন...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
      const SizedBox(height: 16),

      // Subject grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: _filteredSubjects.length + 1, // +1 for custom
        itemBuilder: (_, i) {
          if (i == _filteredSubjects.length) {
            return _buildCustomSubjectCard();
          }
          return _buildSubjectCard(_filteredSubjects[i]);
        },
      ),
    ];
  }

  Widget _buildSubjectCard(Subject subject) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
          _selectedChapter = null;
        });
        _animController.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                subject.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subject.nameBangla.isNotEmpty)
                Text(
                  subject.nameBangla,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontFamily: 'NotoSansBengali',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSubjectCard() {
    return GestureDetector(
      onTap: () => _showCustomSubjectDialog(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 30),
            SizedBox(height: 6),
            Text(
              'কাস্টম বিষয়',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChapterSelection() {
    final chapters = _selectedSubject!.chapters;
    return [
      const Text(
        'অধ্যায় নির্বাচন করুন',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),

      ...chapters.map((chapter) => _buildChapterTile(chapter)),

      const SizedBox(height: 8),
      // Custom chapter option
      ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add, color: AppTheme.primaryColor),
        ),
        title: const Text('কাস্টম অধ্যায়'),
        subtitle: const Text('নিজে লিখুন'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        onTap: _showCustomChapterDialog,
      ),
    ];
  }

  Widget _buildChapterTile(Chapter chapter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${chapter.number}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        title: Text(chapter.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          chapter.nameBangla,
          style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        tileColor: Colors.white,
        onTap: () {
          _selectedChapter = chapter;
          widget.onSelected(_selectedSubject!.name, chapter.name);
        },
      ),
    );
  }

  void _showCustomSubjectDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('নতুন বিষয়'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customSubjectController,
              decoration: const InputDecoration(labelText: 'বিষয়ের নাম (English)'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _customSubjectController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _selectedSubject = Subject(
                    name: name,
                    nameBangla: name,
                    icon: '📖',
                  );
                });
                _customSubjectController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  void _showCustomChapterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('নতুন অধ্যায়'),
        content: TextField(
          controller: _customChapterController,
          decoration: const InputDecoration(labelText: 'অধ্যায়ের নাম'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _customChapterController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _customChapterController.clear();
                widget.onSelected(_selectedSubject!.name, name);
              }
            },
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }
}
