import 'package:flutter/material.dart';

import '../download_manager_interface.dart';

/// Download button with progress indicator
class MediaDownloadButton extends StatelessWidget {
  final DownloadStatus status;
  final double progress;
  final VoidCallback? onDownload;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const MediaDownloadButton({
    super.key,
    required this.status,
    this.progress = 0.0,
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DownloadStatus.pending:
      case DownloadStatus.cancelled:
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: onDownload,
          tooltip: 'Download',
        );

      case DownloadStatus.downloading:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(value: progress, strokeWidth: 2),
            ),
            IconButton(
              icon: const Icon(Icons.pause, size: 20),
              onPressed: onPause,
              tooltip: 'Pause',
            ),
          ],
        );

      case DownloadStatus.paused:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: Colors.grey,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              onPressed: onResume,
              tooltip: 'Resume',
            ),
          ],
        );

      case DownloadStatus.completed:
        return PopupMenuButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete Download'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              onDelete?.call();
            }
          },
        );
    }
  }
}
