import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bookmark.dart';
import '../providers/bookmark_provider.dart';
import '../theme/tokens.dart';
import '../utils/navigation_helper.dart';
import '../utils/url_utils.dart';
import '../widgets/ui/tv_widgets.dart';

/// Bookmark manager: folders, favourites, search and import/export.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _folder;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BookmarkProvider>();
    if (!provider.isLoaded) provider.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editBookmark({Bookmark? bookmark}) async {
    final provider = context.read<BookmarkProvider>();
    final titleController = TextEditingController(text: bookmark?.title ?? '');
    final urlController = TextEditingController(text: bookmark?.url ?? '');
    final folderController = TextEditingController(text: bookmark?.folder ?? '');
    final descriptionController =
        TextEditingController(text: bookmark?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(bookmark == null ? 'Add bookmark' : 'Edit bookmark'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: TvSpace.md),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: TvSpace.md),
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: 'Folder (optional)',
                  hintText: 'e.g. Work/Reading',
                ),
              ),
              const SizedBox(height: TvSpace.md),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final url = urlController.text.trim();
    if (url.isEmpty) return;
    final normalized =
        UrlUtils.looksLikeUrl(url) ? UrlUtils.normalizeUrl(url) : 'https://$url';
    final title = titleController.text.trim().isEmpty
        ? UrlUtils.suggestTitle(normalized)
        : titleController.text.trim();
    final folder = folderController.text.trim().isEmpty
        ? null
        : folderController.text.trim();
    final description = descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim();

    if (bookmark == null) {
      await provider.add(
        title: title,
        url: normalized,
        folder: folder,
        description: description,
      );
    } else {
      await provider.update(bookmark.copyWith(
        title: title,
        url: normalized,
        folder: folder,
        description: description,
      ));
    }
  }

  Future<void> _importDialog() async {
    final controller = TextEditingController();
    final provider = context.read<BookmarkProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import bookmarks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste bookmark JSON exported from Tavrix or Chrome.',
              style: TvText.caption,
            ),
            const SizedBox(height: TvSpace.md),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(hintText: '[{"title":..}]'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final added = await provider.importBookmarks(controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$added bookmarks imported')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookmarkProvider>();
    final folders = provider.folders;
    final visible = provider.visible
        .where((bookmark) => _folder == null || bookmark.folder == _folder)
        .toList();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            tooltip: 'Add bookmark',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _editBookmark(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'export') {
                await provider.exportBookmarks();
              } else if (value == 'import') {
                await _importDialog();
              } else if (value == 'clear') {
                await provider.removeAll();
              }
            },
            itemBuilder: (menuContext) => const [
              PopupMenuItem(value: 'export', child: Text('Export as JSON')),
              PopupMenuItem(value: 'import', child: Text('Import JSON')),
              PopupMenuItem(value: 'clear', child: Text('Delete all')),
            ],
          ),
          const SizedBox(width: TvSpace.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.sm,
              TvSpace.page,
              TvSpace.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search bookmarks',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: provider.setQuery,
            ),
          ),
          if (folders.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TvSpace.page),
                children: [
                  _FolderChip(
                    label: 'All',
                    selected: _folder == null,
                    onTap: () => setState(() => _folder = null),
                  ),
                  for (final folder in folders)
                    _FolderChip(
                      label: folder,
                      selected: _folder == folder,
                      onTap: () => setState(() => _folder = folder),
                    ),
                ],
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? TvEmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: provider.all.isEmpty
                        ? 'No bookmarks yet'
                        : 'Nothing matches that search',
                    message: provider.all.isEmpty
                        ? 'Tap the bookmark icon in the address bar to save a page.'
                        : 'Try a different word or pick another folder.',
                    actionLabel: provider.all.isEmpty ? 'Add bookmark' : null,
                    onAction: () => _editBookmark(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: TvSpace.sm,
                      bottom: TvSpace.xxl,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final bookmark = visible[index];
                      return TvRow(
                        icon: Icons.bookmark_border_rounded,
                        iconWidget: TvFavicon(
                          url: bookmark.url,
                          size: 38,
                          radius: TvRadius.sm,
                        ),
                        title: UrlUtils.cleanTitle(bookmark.title, bookmark.url),
                        subtitle: bookmark.folder == null
                            ? UrlUtils.hostOf(bookmark.url)
                            : '${bookmark.folder} · ${UrlUtils.hostOf(bookmark.url)}',
                        onTap: () => openUrlInBrowser(context, bookmark.url),
                        onLongPress: () => _editBookmark(bookmark: bookmark),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            bookmark.isFavorite
                                ? Icons.star_rounded
                                : Icons.more_horiz_rounded,
                            size: 20,
                            color: bookmark.isFavorite
                                ? TvColors.warning
                                : scheme.onSurfaceVariant,
                          ),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _editBookmark(bookmark: bookmark);
                            } else if (value == 'favorite') {
                              await provider.toggleFavorite(bookmark);
                            } else if (value == 'newTab') {
                              openUrlInBrowser(context, bookmark.url,
                                  newTab: true);
                            } else if (value == 'delete') {
                              await provider.remove(bookmark);
                            }
                          },
                          itemBuilder: (menuContext) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'favorite',
                              child: Text(bookmark.isFavorite
                                  ? 'Remove favourite'
                                  : 'Add favourite'),
                            ),
                            const PopupMenuItem(
                                value: 'newTab', child: Text('Open in new tab')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
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
