import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/history_entry.dart';
import '../models/shortcut_item.dart';
import '../providers/browser_provider.dart';
import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import '../utils/constants.dart';
import '../utils/url_utils.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';
import 'history_screen.dart';
import 'qr_scan_screen.dart';
import 'search_engines_screen.dart';
import 'settings_screen.dart';

/// The Tavrix home screen: branding, search, speed dial and quick sections.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenTab,
  });

  final ValueChanged<String> onNavigate;
  final void Function(String url, {bool isPrivate}) onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  List<ShortcutItem> _shortcuts = [];
  List<HistoryEntry> _topSites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    try {
      final shortcuts = await db.shortcuts();
      final topSites = await db.mostVisited(limit: 6);
      if (!mounted) return;
      setState(() {
        _shortcuts = shortcuts;
        _topSites = topSites;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    final settings = context.read<SettingsProvider>();
    final url = UrlUtils.resolveInput(text, settings.searchEngine);
    _searchController.clear();
    widget.onNavigate(url);
  }

  Future<void> _voiceSearch() async {
    final granted = await PermissionService.requestMicrophone();
    if (!granted) {
      _snack('Microphone permission is needed for voice search');
      return;
    }
    final available = await _speech.initialize();
    if (!available) {
      _snack('Voice search is not available on this device');
      return;
    }
    _snack('Listening...');
    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isEmpty) return;
        if (result.finalResult) {
          _speech.stop();
          _submit(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _scanQr() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (context) => const QrScanScreen()),
    );
    if (value == null || value.isEmpty) return;
    final settings = context.read<SettingsProvider>();
    widget.onNavigate(UrlUtils.resolveInput(value, settings.searchEngine));
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _open(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  Future<void> _editShortcut({ShortcutItem? existing}) async {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add shortcut' : 'Edit shortcut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final url = urlController.text.trim();
    if (url.isEmpty) return;
    final db = context.read<DatabaseService>();
    final title = titleController.text.trim().isEmpty
        ? UrlUtils.suggestTitle(url)
        : titleController.text.trim();
    final normalized = UrlUtils.looksLikeUrl(url)
        ? UrlUtils.normalizeUrl(url)
        : UrlUtils.resolveInput(url, context.read<SettingsProvider>().searchEngine);
    try {
      if (existing == null) {
        await db.insertShortcut(ShortcutItem(
          title: title,
          url: normalized,
          position: _shortcuts.length,
        ));
      } else {
        await db.updateShortcut(ShortcutItem(
          id: existing.id,
          title: title,
          url: normalized,
          position: existing.position,
        ));
      }
      await _load();
    } catch (_) {
      _snack('Could not save the shortcut');
    }
  }

  Future<void> _shortcutMenu(ShortcutItem shortcut) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onNavigate(shortcut.url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _editShortcut(existing: shortcut);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded),
              title: const Text('Move left'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _moveShortcut(shortcut, -1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_forward_rounded),
              title: const Text('Move right'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _moveShortcut(shortcut, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                if (shortcut.id == null) return;
                await context
                    .read<DatabaseService>()
                    .deleteShortcut(shortcut.id!);
                await _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveShortcut(ShortcutItem shortcut, int delta) async {
    final index = _shortcuts.indexWhere((item) => item.id == shortcut.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= _shortcuts.length) return;
    final items = [..._shortcuts];
    final moved = items.removeAt(index);
    items.insert(target, moved);
    await context.read<DatabaseService>().reorderShortcuts(items);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final browser = context.watch<BrowserProvider>();
    final downloads = context.watch<DownloadProvider>();
    final recentDownloads = downloads.finished.take(3).toList();
    final recentlyClosed = browser.recentlyClosed.take(3).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TavrixConstants.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TavrixConstants.tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Private tab',
                icon: const Icon(Icons.shield_moon_outlined),
                onPressed: () => widget.onOpenTab('', isPrivate: true),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _open(const SettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.go,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Search with ${settings.searchEngine.name}',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Voice search',
                    icon: const Icon(Icons.mic_none_rounded),
                    onPressed: _voiceSearch,
                  ),
                  IconButton(
                    tooltip: 'Scan QR code',
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: _scanQr,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.travel_explore_rounded, size: 18),
                label: Text(settings.searchEngine.name),
                onPressed: () => _open(const SearchEnginesScreen()),
              ),
              ActionChip(
                avatar: const Icon(Icons.bookmark_border_rounded, size: 18),
                label: const Text('Bookmarks'),
                onPressed: () => _open(const BookmarksScreen()),
              ),
              ActionChip(
                avatar: const Icon(Icons.history_rounded, size: 18),
                label: const Text('History'),
                onPressed: () => _open(const HistoryScreen()),
              ),
              ActionChip(
                avatar: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Downloads'),
                onPressed: () => _open(const DownloadsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Shortcuts',
            action: 'Add',
            onAction: () => _editShortcut(),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            GridView.count(
              crossAxisCount: settings.settings.compactLayout ? 5 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: [
                for (final shortcut in _shortcuts)
                  _ShortcutTile(
                    title: shortcut.title,
                    url: shortcut.url,
                    onTap: () => widget.onNavigate(shortcut.url),
                    onLongPress: () => _shortcutMenu(shortcut),
                  ),
                _AddShortcutTile(onTap: () => _editShortcut()),
              ],
            ),
          if (recentlyClosed.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Recently closed'),
            const SizedBox(height: 8),
            for (final closed in recentlyClosed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_rounded),
                title: Text(
                  closed.title.isEmpty ? closed.url : closed.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  UrlUtils.displayUrl(closed.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => widget.onOpenTab(closed.url),
              ),
          ],
          if (recentDownloads.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Recent downloads',
              action: 'All',
              onAction: () => _open(const DownloadsScreen()),
            ),
            const SizedBox(height: 8),
            for (final download in recentDownloads)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  download.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(download.statusLabel),
                onTap: () => _open(const DownloadsScreen()),
              ),
          ],
          if (_topSites.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Top sites'),
            const SizedBox(height: 8),
            for (final site in _topSites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.public_rounded),
                title: Text(
                  site.title.isEmpty ? site.url : site.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  site.domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => widget.onNavigate(site.url),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.title,
    required this.url,
    required this.onTap,
    required this.onLongPress,
  });

  final String title;
  final String url;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = title.isEmpty ? '?' : title[0].toUpperCase();
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _AddShortcutTile extends StatelessWidget {
  const _AddShortcutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(height: 8),
          Text('Add', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
