import 'package:flutter/material.dart';

import '../../models/media_type.dart';
import '../download_aware_media_metadata.dart';
import 'download_button.dart';

/// List tile showing download progress for a media item
class DownloadListTile extends StatelessWidget {
  final DownloadAwareMediaMetadata metadata;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const DownloadListTile({
    super.key,
    required this.metadata,
    required this.onTap,
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = metadata.downloadProgress;

    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(metadata.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (metadata.description != null)
            Text(
              metadata.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (progress != null && progress.isDownloading) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress.progress),
            const SizedBox(height: 2),
            Text(
              '${(progress.progress * 100).toStringAsFixed(0)}% • '
              '${_formatBytes(progress.downloaded)} / ${_formatBytes(progress.total)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      trailing: progress != null
          ? MediaDownloadButton(
              status: progress.status,
              progress: progress.progress,
              onDownload: onDownload,
              onPause: onPause,
              onResume: onResume,
              onCancel: onCancel,
              onDelete: onDelete,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLeadingIcon() {
    IconData icon;
    Color? color;

    switch (metadata.mediaType) {
      case MediaType.video:
        icon = Icons.video_library;
        color = Colors.blue;
        break;
      case MediaType.audio:
        icon = Icons.audiotrack;
        color = Colors.orange;
        break;
      case MediaType.document:
        icon = Icons.description;
        color = Colors.red;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, color: color)),
          if (metadata.isDownloaded)
            const Positioned(
              right: 4,
              bottom: 4,
              child: Icon(Icons.offline_pin, size: 16, color: Colors.green),
            ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
