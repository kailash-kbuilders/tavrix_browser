import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/download_provider.dart';

/// Download manager with real progress, pause/resume/cancel/retry and file
/// actions.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloadProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          actions: [
            IconButton(
              tooltip: 'Clear finished records',
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: provider.clearFinishedRecords,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DownloadList(
              items: provider.active,
              emptyText: 'No active downloads',
            ),
            _DownloadList(
              items: provider.items,
              emptyText: 'No downloads yet',
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadList extends StatelessWidget {
  const _DownloadList({required this.items, required this.emptyText});

  final List<DownloadItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }
    final provider = context.read<DownloadProvider>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_iconFor(item), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _actions(context, provider, item),
                  ],
                ),
                if (item.status == DownloadStatus.running ||
                    item.status == DownloadStatus.queued) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: item.totalBytes > 0 ? item.progress : null,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                if ((item.error ?? '').isNotEmpty &&
                    item.status == DownloadStatus.failed) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actions(
      BuildContext context, DownloadProvider provider, DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.running:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_rounded),
              onPressed: () => provider.pause(item),
            ),
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => provider.cancel(item),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Resume',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => provider.resume(item),
            ),
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => provider.cancel(item),
            ),
          ],
        );
      case DownloadStatus.completed:
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'open') {
              final error = await provider.openFile(item);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            } else if (value == 'share') {
              await provider.shareFile(item);
            } else if (value == 'delete') {
              await provider.remove(item, deleteFile: true);
            }
          },
          itemBuilder: (menuContext) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'share', child: Text('Share')),
            PopupMenuItem(value: 'delete', child: Text('Delete file')),
          ],
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
      case DownloadStatus.queued:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Retry',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => provider.retry(item),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => provider.remove(item, deleteFile: true),
            ),
          ],
        );
    }
  }

  IconData _iconFor(DownloadItem item) {
    final mime = (item.mimeType ?? '').toLowerCase();
    final name = item.filename.toLowerCase();
    if (mime.contains('pdf') || name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('video/')) return Icons.movie_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (name.endsWith('.zip') || name.endsWith('.rar') || name.endsWith('.7z')) {
      return Icons.folder_zip_outlined;
    }
    if (name.endsWith('.apk')) return Icons.android_rounded;
    return Icons.insert_drive_file_outlined;
  }

  String _subtitle(DownloadItem item) {
    final date = DateFormat('d MMM, HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(item.createdAt));
    final size = item.totalBytes > 0
        ? '${_formatBytes(item.receivedBytes)} / ${_formatBytes(item.totalBytes)}'
        : _formatBytes(item.receivedBytes);
    return '${item.statusLabel} - $size - $date';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[index]}';
  }
}
