import 'package:flutter/material.dart';

import '../../models/media_metadata.dart';
import '../document_viewer_controller.dart';

/// List tile for displaying documents in a list
class DocumentListTile extends StatelessWidget {
  final MediaMetadata metadata;
  final VoidCallback onTap;
  final bool isCompleted;
  final Widget? trailing;

  const DocumentListTile({
    super.key,
    required this.metadata,
    required this.onTap,
    this.isCompleted = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final documentType = _getDocumentType(metadata.source.uri);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getDocumentColor(documentType).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getDocumentIcon(documentType),
          color: _getDocumentColor(documentType),
        ),
      ),
      title: Text(metadata.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: metadata.description != null
          ? Text(
              metadata.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing:
          trailing ??
          (isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }

  DocumentType _getDocumentType(String uri) {
    final lowerUri = uri.toLowerCase();
    if (lowerUri.endsWith('.pdf')) return DocumentType.pdf;
    if (lowerUri.endsWith('.docx') || lowerUri.endsWith('.doc')) {
      return DocumentType.docx;
    }
    if (lowerUri.endsWith('.pptx') || lowerUri.endsWith('.ppt')) {
      return DocumentType.pptx;
    }
    if (lowerUri.endsWith('.xlsx') || lowerUri.endsWith('.xls')) {
      return DocumentType.xlsx;
    }
    if (lowerUri.endsWith('.txt')) return DocumentType.txt;
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
}
