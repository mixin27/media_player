import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/media_source.dart';

/// PDF Viewer Widget (for in-app viewing)
class LMSPdfViewerWidget extends StatefulWidget {
  final MediaSource source;
  final Function(int page, int totalPages)? onPageChanged;
  final VoidCallback? onDocumentLoaded;

  const LMSPdfViewerWidget({
    super.key,
    required this.source,
    this.onPageChanged,
    this.onDocumentLoaded,
  });

  @override
  State<LMSPdfViewerWidget> createState() => _LMSPdfViewerWidgetState();
}

class _LMSPdfViewerWidgetState extends State<LMSPdfViewerWidget> {
  final PdfViewerController _pdfController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _pdfController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    widget.onPageChanged?.call(
      _pdfController.pageNumber,
      _pdfController.pageCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.source.isLocal) {
      return SfPdfViewer.file(
        File(widget.source.uri),
        controller: _pdfController,
        onDocumentLoaded: (details) {
          widget.onDocumentLoaded?.call();
        },
      );
    } else {
      return SfPdfViewer.network(
        widget.source.uri,
        controller: _pdfController,
        headers: widget.source.headers ?? {},
        onDocumentLoaded: (details) {
          widget.onDocumentLoaded?.call();
        },
      );
    }
  }

  @override
  void dispose() {
    _pdfController.removeListener(_onPageChanged);
    _pdfController.dispose();
    super.dispose();
  }
}
