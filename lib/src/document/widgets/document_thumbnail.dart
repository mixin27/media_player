import 'package:flutter/material.dart';

import '../document_viewer_controller.dart';

/// Thumbnail preview for documents
class DocumentThumbnail extends StatelessWidget {
  final String documentPath;
  final double width;
  final double height;
  final bool showBadge;

  const DocumentThumbnail({
    super.key,
    required this.documentPath,
    this.width = 120,
    this.height = 160,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final documentType = _getDocumentType(documentPath);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getDocumentIcon(documentType),
              size: width * 0.4,
              color: _getDocumentColor(documentType),
            ),
          ),
          if (showBadge)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDocumentColor(documentType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getDocumentExtension(documentPath).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DocumentType _getDocumentType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.pdf')) return DocumentType.pdf;
    if (lowerPath.endsWith('.docx') || lowerPath.endsWith('.doc')) {
      return DocumentType.docx;
    }
    if (lowerPath.endsWith('.pptx') || lowerPath.endsWith('.ppt')) {
      return DocumentType.pptx;
    }
    if (lowerPath.endsWith('.xlsx') || lowerPath.endsWith('.xls')) {
      return DocumentType.xlsx;
    }
    if (lowerPath.endsWith('.txt')) return DocumentType.txt;
    return DocumentType.other;
  }

  String _getDocumentExtension(String path) {
    final parts = path.split('.');
    return parts.isEmpty ? '' : parts.last;
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
