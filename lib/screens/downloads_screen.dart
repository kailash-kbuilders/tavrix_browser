import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/download_provider.dart';
import '../services/database_service.dart';
import '../theme/tokens.dart';
import '../utils/download_classifier.dart';
import '../widgets/ui/tv_widgets.dart';

enum DownloadSort { newest, oldest, largest, name }

/// One Download Manager for every file type: search, categories, sort, storage
/// usage and the full action set on each row.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DownloadCategory _category = DownloadCategory.all;
  DownloadSort _sort = DownloadSort.newest;
  String _query = '';
  int _storedBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureStorage());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _measureStorage() async {
    final downloads = context.read<DownloadProvider>();
    final db = context.read<DatabaseService>();
    final paths = downloads.items
        .map((item) => item.path)
        .whereType<String>()
        .toList(growable: false);
    try {
      final bytes = await db.existingBytes(paths);
      if (!mounted) return;
      setState(() => _storedBytes = bytes);
    } catch (_) {}
  }

  List<DownloadItem> _visible(List<DownloadItem> items) {
    final needle = _query.trim().toLowerCase();
    final filtered = items.where((item) {
      if (_category != DownloadCategory.all &&
          classifyDownload(item) != _category) {
        return false;
      }
      if (needle.isEmpty) return true;
      return item.filename.toLowerCase().contains(needle);
    }).toList();

    switch (_sort) {
      case DownloadSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DownloadSort.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DownloadSort.largest:
        filtered.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
        break;
      case DownloadSort.name:
        filtered.sort(
            (a, b) => a.filename.toLowerCase().compareTo(b.filename.toLowerCase()));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloadProvider>();
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible(provider.items);
    final activeCount = provider.active.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          PopupMenuButton<DownloadSort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (menuContext) => const [
              PopupMenuItem(value: DownloadSort.newest, child: Text('Newest first')),
              PopupMenuItem(value: DownloadSort.oldest, child: Text('Oldest first')),
              PopupMenuItem(value: DownloadSort.largest, child: Text('Largest first')),
              PopupMenuItem(value: DownloadSort.name, child: Text('Name (A-Z)')),
            ],
          ),
          IconButton(
            tooltip: 'Clear finished records',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () async {
              await provider.clearFinishedRecords();
              await _measureStorage();
            },
          ),
          const SizedBox(width: TvSpace.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.xs,
              TvSpace.page,
              TvSpace.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.sd_storage_outlined,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: TvSpace.sm),
                Text(
                  '${_formatBytes(_storedBytes)} stored in Tavrix Downloads',
                  style: TvText.caption,
                ),
                const Spacer(),
                if (activeCount > 0)
                  TvPill(
                    label: '$activeCount active',
                    icon: Icons.downloading_rounded,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TvSpace.page),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search downloads',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                TvSpace.page,
                TvSpace.sm,
                TvSpace.page,
                TvSpace.sm,
              ),
              children: [
                for (final category in DownloadCategory.values)
                  _CategoryChip(
                    label: _categoryLabel(category),
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? TvEmptyState(
                    icon: Icons.download_done_rounded,
                    title: provider.items.isEmpty
                        ? 'No downloads yet'
                        : 'Nothing in this category',
                    message: provider.items.isEmpty
                        ? 'Tap a download link in any page to start.'
                        : 'Try another category or clear the search.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      TvSpace.page,
                      0,
                      TvSpace.page,
                      TvSpace.xxl,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => _DownloadTile(
                      item: visible[index],
                      onChanged: _measureStorage,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(DownloadCategory category) =>
      downloadCategoryLabel(category);
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.item, required this.onChanged});

  final DownloadItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<DownloadProvider>();
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
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(TvRadius.sm),
                ),
                child: Icon(
                  _iconFor(item),
                  size: 20,
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
                    Row(
                      children: [
                        _statusPill(item),
                        const SizedBox(width: TvSpace.sm),
                        Expanded(
                          child: Text(
                            _subtitle(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TvText.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _actions(context, provider),
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
  }

  Widget _statusPill(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.completed:
        return const TvPill(
          label: 'Done',
          color: TvColors.success,
          icon: Icons.check_rounded,
        );
      case DownloadStatus.running:
      case DownloadStatus.queued:
        return const TvPill(label: 'Downloading');
      case DownloadStatus.paused:
        return const TvPill(
          label: 'Paused',
          color: TvColors.warning,
          icon: Icons.pause_rounded,
        );
      case DownloadStatus.failed:
        return const TvPill(
          label: 'Failed',
          color: TvColors.danger,
          icon: Icons.error_outline_rounded,
        );
      case DownloadStatus.cancelled:
        return const TvPill(
          label: 'Cancelled',
          color: TvColors.danger,
        );
    }
  }

  Widget _actions(BuildContext context, DownloadProvider provider) {
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TvIconButton(
              icon: Icons.open_in_new_rounded,
              iconSize: 18,
              size: 32,
              tooltip: 'Open',
              onTap: () async {
                final error = await provider.openFile(item);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              onSelected: (value) async {
                if (value == 'share') {
                  await provider.shareFile(item);
                } else if (value == 'delete') {
                  await provider.remove(item, deleteFile: true);
                  onChanged();
                }
              },
              itemBuilder: (menuContext) => const [
                PopupMenuItem(value: 'share', child: Text('Share')),
                PopupMenuItem(value: 'delete', child: Text('Delete file')),
              ],
            ),
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
              onTap: () async {
                await provider.remove(item, deleteFile: true);
                onChanged();
              },
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
    return '$size · $date';
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: TvSpace.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TvSpace.md,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.16)
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(TvRadius.pill),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TvText.label.copyWith(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
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
