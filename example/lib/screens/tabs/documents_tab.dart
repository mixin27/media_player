import 'package:flutter/material.dart';

import '../../models/sample_media.dart';
import '../../widgets/document_list_item.dart';
import '../player/document_viewer_screen.dart';

class DocumentsTab extends StatelessWidget {
  const DocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: SampleMedia.documents.length,
      itemBuilder: (context, index) {
        final doc = SampleMedia.documents[index];

        return DocumentListItem(
          metadata: doc,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentViewerScreen(metadata: doc),
              ),
            );
          },
        );
      },
    );
  }
}
