import 'package:flutter/material.dart';
import '../providers/scan_provider.dart';
import '../theme/app_theme.dart';

class FileUploadCard extends StatelessWidget {
  final List<ScannedFile> files;
  final VoidCallback onPickFiles;
  final void Function(int index) onRemoveFile;

  const FileUploadCard({
    super.key,
    required this.files,
    required this.onPickFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ফাইল আপলোড',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Upload area
        GestureDetector(
          onTap: onPickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.4),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: AppTheme.primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ফাইল বেছে নিন',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PDF • JPG • PNG • DOCX',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'একসাথে একাধিক ফাইল নির্বাচন করতে পারবেন',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // File type icons legend
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _fileTypeBadge('PDF', Colors.red),
            const SizedBox(width: 8),
            _fileTypeBadge('JPG', Colors.orange),
            const SizedBox(width: 8),
            _fileTypeBadge('PNG', Colors.blue),
            const SizedBox(width: 8),
            _fileTypeBadge('DOCX', Colors.indigo),
          ],
        ),

        // File list
        if (files.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${files.length} টি ফাইল নির্বাচিত',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              TextButton.icon(
                onPressed: onPickFiles,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('আরো যোগ করুন'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(files.length, (i) => _buildFileTile(files[i], i)),
        ],
      ],
    );
  }

  Widget _fileTypeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFileTile(ScannedFile file, int index) {
    final ext = file.extension.toLowerCase();
    final (icon, color) = _getFileIconAndColor(ext);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(width: 12),

          // File name + type badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.displayExtension,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
            onPressed: () => onRemoveFile(index),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getFileIconAndColor(String ext) {
    switch (ext) {
      case 'pdf':
        return (Icons.picture_as_pdf, Colors.red);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'bmp':
      case 'webp':
        return (Icons.image, Colors.orange);
      case 'docx':
      case 'doc':
        return (Icons.description, Colors.indigo);
      default:
        return (Icons.insert_drive_file, Colors.grey);
    }
  }
}
