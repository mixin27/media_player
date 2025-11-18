import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

class DocumentViewerScreen extends StatefulWidget {
  final MediaMetadata metadata;

  const DocumentViewerScreen({super.key, required this.metadata});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late LMSDocumentViewerController _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = LMSDocumentViewerController(
      metadata: widget.metadata,
      storage: LMSMediaManager.instance.storage,
      onCompletion: (mediaId) {
        debugPrint('✅ Document viewed: $mediaId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document marked as viewed'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onError: (mediaId, error) {
        debugPrint('❌ Error opening document: $error');

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // For PDF documents, use the built-in viewer
    if (_controller.documentType == DocumentType.pdf) {
      return LMSDocumentViewerPage(
        controller: _controller,
        showToolbar: true,
        markAsViewedOnLoad: true,
      );
    }

    // For other documents, show info and option to open
    return Scaffold(
      appBar: AppBar(title: Text(widget.metadata.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getDocumentIcon(),
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                widget.metadata.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.metadata.description ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await _controller.openWithSystemApp();
                  await _controller.markAsViewed();
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    switch (_controller.documentType) {
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
