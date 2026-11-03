import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bookmark.dart';
import '../providers/bookmark_provider.dart';
import '../utils/navigation_helper.dart';
import '../utils/url_utils.dart';

/// Bookmark manager with folders, favorites, search and import/export.
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
    final folderController =
        TextEditingController(text: bookmark?.folder ?? '');
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
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: 'Folder (optional)',
                  hintText: 'e.g. Work/Reading',
                ),
              ),
              const SizedBox(height: 12),
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
    final normalized = UrlUtils.looksLikeUrl(url)
        ? UrlUtils.normalizeUrl(url)
        : 'https://$url';
    final title = titleController.text.trim().isEmpty
        ? UrlUtils.suggestTitle(normalized)
        : titleController.text.trim();
    final folder = folderController.text.trim().isEmpty
        ? null
        : folderController.text.trim();

    if (bookmark == null) {
      await provider.add(
        title: title,
        url: normalized,
        folder: folder,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );
    } else {
      await provider.update(bookmark.copyWith(
        title: title,
        url: normalized,
        folder: folder,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
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
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search bookmarks',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: provider.setQuery,
            ),
          ),
          if (folders.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _folder == null,
                    onSelected: (_) => setState(() => _folder = null),
                  ),
                  for (final folder in folders) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(folder),
                      selected: _folder == folder,
                      onSelected: (_) => setState(() => _folder = folder),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      provider.all.isEmpty
                          ? 'No bookmarks yet'
                          : 'No matching bookmarks',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final bookmark = visible[index];
                      return ListTile(
                        leading: Icon(bookmark.isFavorite
                            ? Icons.star_rounded
                            : Icons.bookmark_border_rounded),
                        title: Text(
                          bookmark.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          bookmark.folder == null
                              ? UrlUtils.displayUrl(bookmark.url)
                              : '${bookmark.folder} - ${UrlUtils.displayUrl(bookmark.url)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => openUrlInBrowser(context, bookmark.url),
                        onLongPress: () => _editBookmark(bookmark: bookmark),
                        trailing: PopupMenuButton<String>(
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
                                  ? 'Remove favorite'
                                  : 'Add favorite'),
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
