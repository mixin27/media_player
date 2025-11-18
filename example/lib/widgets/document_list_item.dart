import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

class DocumentListItem extends StatelessWidget {
  final MediaMetadata metadata;
  final VoidCallback onTap;
  final bool isCompleted;

  const DocumentListItem({
    super.key,
    required this.metadata,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final documentType = _getDocumentType(metadata.source.uri);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _getDocumentColor(documentType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDocumentIcon(documentType),
            color: _getDocumentColor(documentType),
            size: 32,
          ),
        ),
        title: Text(
          metadata.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (metadata.description != null) ...[
              const SizedBox(height: 4),
              Text(
                metadata.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getDocumentColor(documentType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getDocumentTypeText(documentType),
                style: TextStyle(
                  fontSize: 11,
                  color: _getDocumentColor(documentType),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  DocumentType _getDocumentType(String uri) {
    final lowerUri = uri.toLowerCase();
    if (lowerUri.contains('.pdf')) return DocumentType.pdf;
    if (lowerUri.contains('.docx') || lowerUri.contains('.doc')) {
      return DocumentType.docx;
    }
    if (lowerUri.contains('.pptx') || lowerUri.contains('.ppt')) {
      return DocumentType.pptx;
    }
    if (lowerUri.contains('.xlsx') || lowerUri.contains('.xls')) {
      return DocumentType.xlsx;
    }
    if (lowerUri.contains('.txt')) return DocumentType.txt;
    return DocumentType.other;
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.docx:
        return Icons.description;
      case DocumentType.pptx:
        return Icons.slideshow;
      case DocumentType.xlsx:
        return Icons.table_chart;
      case DocumentType.txt:
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Colors.red;
      case DocumentType.docx:
        return Colors.blue;
      case DocumentType.pptx:
        return Colors.orange;
      case DocumentType.xlsx:
        return Colors.green;
      case DocumentType.txt:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _getDocumentTypeText(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.docx:
        return 'WORD';
      case DocumentType.pptx:
        return 'PPT';
      case DocumentType.xlsx:
        return 'EXCEL';
      case DocumentType.txt:
        return 'TEXT';
      default:
        return 'FILE';
    }
  }
}
