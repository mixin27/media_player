import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../document_viewer_controller.dart';

/// Full-page document viewer with toolbar
class LMSDocumentViewerPage extends StatefulWidget {
  final LMSDocumentViewerController controller;
  final bool showToolbar;
  final bool markAsViewedOnLoad;

  const LMSDocumentViewerPage({
    super.key,
    required this.controller,
    this.showToolbar = true,
    this.markAsViewedOnLoad = true,
  });

  @override
  State<LMSDocumentViewerPage> createState() => _LMSDocumentViewerPageState();
}

class _LMSDocumentViewerPageState extends State<LMSDocumentViewerPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (_pdfController.pageNumber != _currentPage) {
      setState(() {
        _currentPage = _pdfController.pageNumber;
      });
    }
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });

    if (widget.markAsViewedOnLoad) {
      widget.controller.markAsViewed();
    }
  }

  @override
  void dispose() {
    _pdfController.removeListener(_onPageChanged);
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.documentType != DocumentType.pdf) {
      return _NonPdfDocumentViewer(controller: widget.controller);
    }

    return Scaffold(
      appBar: widget.showToolbar
          ? _DocumentAppBar(
              title: widget.controller.metadata.title,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onSearch: () => _pdfController.searchText(''),
              onJumpToPage: _showJumpToPageDialog,
            )
          : null,
      body: Stack(
        children: [
          if (widget.controller.metadata.source.isLocal)
            SfPdfViewer.file(
              File(widget.controller.metadata.source.uri),
              controller: _pdfController,
              onDocumentLoaded: _onDocumentLoaded,
            )
          else
            SfPdfViewer.network(
              widget.controller.metadata.source.uri,
              controller: _pdfController,
              headers: widget.controller.metadata.source.headers ?? {},
              onDocumentLoaded: _onDocumentLoaded,
            ),

          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: widget.showToolbar
          ? _DocumentBottomBar(
              controller: _pdfController,
              currentPage: _currentPage,
              totalPages: _totalPages,
            )
          : null,
    );
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page Number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(textController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}

class _DocumentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int currentPage;
  final int totalPages;
  final VoidCallback onSearch;
  final VoidCallback onJumpToPage;

  const _DocumentAppBar({
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.onSearch,
    required this.onJumpToPage,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (totalPages > 0)
            Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearch,
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onJumpToPage,
          tooltip: 'Jump to Page',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 8),
                  Text('Print'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            // Handle menu actions
          },
        ),
      ],
    );
  }
}

class _DocumentBottomBar extends StatelessWidget {
  final PdfViewerController controller;
  final int currentPage;
  final int totalPages;

  const _DocumentBottomBar({
    required this.controller,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: currentPage > 1 ? () => controller.jumpToPage(1) : null,
            tooltip: 'First Page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => controller.previousPage() : null,
            tooltip: 'Previous Page',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () => controller.nextPage()
                : null,
            tooltip: 'Next Page',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: currentPage < totalPages
                ? () => controller.jumpToPage(totalPages)
                : null,
            tooltip: 'Last Page',
          ),
        ],
      ),
    );
  }
}

class _NonPdfDocumentViewer extends StatelessWidget {
  final LMSDocumentViewerController controller;

  const _NonPdfDocumentViewer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.metadata.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getDocumentIcon(), size: 120, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              controller.metadata.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getDocumentTypeText(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await controller.openWithSystemApp();
                await controller.markAsViewed();
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with Default App'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    switch (controller.documentType) {
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

  String _getDocumentTypeText() {
    switch (controller.documentType) {
      case DocumentType.docx:
        return 'Word Document';
      case DocumentType.pptx:
        return 'PowerPoint Presentation';
      case DocumentType.xlsx:
        return 'Excel Spreadsheet';
      case DocumentType.txt:
        return 'Text Document';
      default:
        return 'Document';
    }
  }
}
