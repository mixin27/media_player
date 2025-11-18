import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

import '../../services/download_service.dart';

class DownloadsTab extends StatefulWidget {
  const DownloadsTab({super.key});

  @override
  State<DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<DownloadsTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'All Downloads',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearCompleted,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear Completed'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DownloadProgress>>(
            future: DownloadService.instance.getAllDownloads(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final downloads = snapshot.data ?? [];

              if (downloads.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No downloads yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Downloaded media will appear here',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final download = downloads[index];
                    return _DownloadItem(
                      download: download,
                      onPause: () async {
                        await DownloadService.instance.pauseDownload(
                          download.downloadId,
                        );
                        setState(() {});
                      },
                      onResume: () async {
                        await DownloadService.instance.resumeDownload(
                          download.downloadId,
                        );
                        setState(() {});
                      },
                      onCancel: () async {
                        await DownloadService.instance.cancelDownload(
                          download.downloadId,
                        );
                        setState(() {});
                      },
                      onDelete: () => _confirmDelete(download),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _clearCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed'),
        content: const Text('Remove all completed downloads from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DownloadService.instance.clearCompletedDownloads();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completed downloads cleared')),
        );
      }
    }
  }

  Future<void> _confirmDelete(DownloadProgress download) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text('This will delete the downloaded file. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DownloadService.instance.deleteDownload(download.downloadId);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download deleted')));
      }
    }
  }
}

class _DownloadItem extends StatelessWidget {
  final DownloadProgress download;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const _DownloadItem({
    required this.download,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media ${download.mediaId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context),
              ],
            ),
            if (download.isDownloading ||
                download.status == DownloadStatus.paused) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: download.progress,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(download.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '${_formatBytes(download.downloaded)} / ${_formatBytes(download.total)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (download.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${download.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (download.status) {
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 40);
      case DownloadStatus.downloading:
        return SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: download.progress,
            strokeWidth: 3,
          ),
        );
      case DownloadStatus.paused:
        return Icon(Icons.pause_circle, color: Colors.orange[700], size: 40);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 40);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey, size: 40);
      default:
        return const Icon(
          Icons.download_outlined,
          color: Colors.grey,
          size: 40,
        );
    }
  }

  Widget _buildActionButton(BuildContext context) {
    switch (download.status) {
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: onPause,
              tooltip: 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCancel,
              tooltip: 'Cancel',
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onResume,
              tooltip: 'Resume',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCancel,
              tooltip: 'Cancel',
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
          tooltip: 'Delete',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStatusText() {
    switch (download.status) {
      case DownloadStatus.completed:
        return 'Completed • ${_formatBytes(download.downloaded)}';
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
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
