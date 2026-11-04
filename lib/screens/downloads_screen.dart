import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/download_provider.dart';
import '../theme/tokens.dart';
import '../widgets/ui/tv_widgets.dart';

/// Download manager with real progress and pause/resume/cancel/retry.
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
            const SizedBox(width: TvSpace.sm),
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
              emptyIcon: Icons.download_done_rounded,
              emptyTitle: 'Nothing downloading',
              emptyMessage: 'Files you download will appear here.',
            ),
            _DownloadList(
              items: provider.items,
              emptyIcon: Icons.folder_open_rounded,
              emptyTitle: 'No downloads yet',
              emptyMessage: 'Tap a download link in any page to start.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadList extends StatelessWidget {
  const _DownloadList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<DownloadItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return TvEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    final provider = context.read<DownloadProvider>();
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        TvSpace.page,
        TvSpace.md,
        TvSpace.page,
        TvSpace.xxl,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final running = item.status == DownloadStatus.running ||
            item.status == DownloadStatus.queued;
        final failed = item.status == DownloadStatus.failed;

        return Container(
          margin: const EdgeInsets.only(bottom: TvSpace.md),
          padding: const EdgeInsets.fromLTRB(
            TvSpace.md,
            TvSpace.md,
            TvSpace.sm,
            TvSpace.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(TvRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(TvRadius.sm),
                    ),
                    child: Icon(
                      _iconFor(item),
                      size: 19,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: TvSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TvText.body.copyWith(fontSize: 14.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TvText.caption,
                        ),
                      ],
                    ),
                  ),
                  _actions(context, provider, item),
                ],
              ),
              if (running) ...[
                const SizedBox(height: TvSpace.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TvRadius.pill),
                  child: LinearProgressIndicator(
                    value: item.totalBytes > 0 ? item.progress : null,
                    minHeight: 3,
                  ),
                ),
              ],
              if (failed && (item.error ?? '').isNotEmpty) ...[
                const SizedBox(height: TvSpace.sm),
                Text(
                  item.error!,
                  style: TvText.caption.copyWith(color: scheme.error),
                ),
              ],
            ],
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
            TvIconButton(
              icon: Icons.pause_rounded,
              iconSize: 19,
              size: 32,
              tooltip: 'Pause',
              onTap: () => provider.pause(item),
            ),
            TvIconButton(
              icon: Icons.close_rounded,
              iconSize: 18,
              size: 32,
              tooltip: 'Cancel',
              onTap: () => provider.cancel(item),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TvIconButton(
              icon: Icons.play_arrow_rounded,
              iconSize: 20,
              size: 32,
              tooltip: 'Resume',
              onTap: () => provider.resume(item),
            ),
            TvIconButton(
              icon: Icons.close_rounded,
              iconSize: 18,
              size: 32,
              tooltip: 'Cancel',
              onTap: () => provider.cancel(item),
            ),
          ],
        );
      case DownloadStatus.completed:
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded, size: 20),
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
            TvIconButton(
              icon: Icons.refresh_rounded,
              iconSize: 19,
              size: 32,
              tooltip: 'Retry',
              onTap: () => provider.retry(item),
            ),
            TvIconButton(
              icon: Icons.delete_outline_rounded,
              iconSize: 19,
              size: 32,
              tooltip: 'Remove',
              onTap: () => provider.remove(item, deleteFile: true),
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
    return '${item.statusLabel} · $size · $date';
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
