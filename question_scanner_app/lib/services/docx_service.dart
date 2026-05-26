import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Extracts raw text from a .docx file by unzipping it and parsing the XML.
/// DOCX files are ZIP archives containing word/document.xml.
class DocxService {
  /// Extract all text content from a DOCX file
  Future<String> extractText(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find word/document.xml
      ArchiveFile? documentXml;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentXml = file;
          break;
        }
      }

      if (documentXml == null) {
        return 'Error: Could not find document.xml in DOCX file';
      }

      final xmlContent = String.fromCharCodes(documentXml.content as List<int>);
      return _parseDocumentXml(xmlContent);
    } catch (e) {
      return 'Error extracting DOCX: $e';
    }
  }

  String _parseDocumentXml(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final buffer = StringBuffer();

      // Get all paragraph elements
      final paragraphs = document.findAllElements('w:p');

      for (final para in paragraphs) {
        final paraText = StringBuffer();

        // Handle paragraph properties (numbering, etc.)
        final numPr = para.findElements('w:numPr');
        String prefix = '';
        if (numPr.isNotEmpty) {
          final ilvl = numPr.first.findElements('w:ilvl').firstOrNull;
          final numId = numPr.first.findElements('w:numId').firstOrNull;
          if (ilvl != null && numId != null) {
            prefix = _getListPrefix(ilvl, numId);
          }
        }

        // Get all text runs in this paragraph
        final runs = para.findAllElements('w:r');
        for (final run in runs) {
          // Check if text has specific formatting
          final rPr = run.findElements('w:rPr').firstOrNull;
          final isBold = rPr?.findElements('w:b').isNotEmpty ?? false;

          final textElements = run.findAllElements('w:t');
          for (final textEl in textElements) {
            final text = textEl.innerText;
            if (text.isNotEmpty) {
              paraText.write(text);
            }
          }

          // Handle tab characters
          final tabs = run.findElements('w:tab');
          if (tabs.isNotEmpty) {
            paraText.write('\t');
          }
        }

        // Handle line breaks within paragraph
        final brs = para.findAllElements('w:br');
        final hasLineBreak = brs.isNotEmpty;

        final text = paraText.toString();
        if (text.trim().isNotEmpty) {
          if (prefix.isNotEmpty) {
            buffer.writeln('$prefix $text');
          } else {
            buffer.writeln(text);
          }
        } else {
          // Empty paragraph = blank line
          buffer.writeln();
        }
      }

      return _cleanText(buffer.toString());
    } catch (e) {
      return 'Error parsing XML: $e';
    }
  }

  String _getListPrefix(XmlElement ilvl, XmlElement numId) {
    final level = int.tryParse(ilvl.getAttribute('w:val') ?? '0') ?? 0;
    // Simple numbering - actual numbering requires parsing numbering.xml
    // For our purposes, we'll use simple markers
    const banglaNumbers = ['১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '১০'];
    if (level == 0) return '';
    return '  ';
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Max 2 consecutive newlines
        .replaceAll(RegExp(r'[ \t]+'), ' ')      // Normalize spaces
        .trim();
  }

  /// Extract text from all tables in a DOCX
  Future<String> extractTables(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? documentXml;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentXml = file;
          break;
        }
      }

      if (documentXml == null) return '';

      final xmlContent = String.fromCharCodes(documentXml.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      final buffer = StringBuffer();

      final tables = document.findAllElements('w:tbl');
      for (final table in tables) {
        final rows = table.findAllElements('w:tr');
        for (final row in rows) {
          final cells = row.findAllElements('w:tc');
          final cellTexts = cells.map((cell) {
            return cell.findAllElements('w:t').map((t) => t.innerText).join('');
          }).toList();
          buffer.writeln(cellTexts.join(' | '));
        }
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      return '';
    }
  }
}
