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
import '../theme/tokens.dart';
import '../utils/url_utils.dart';
import '../widgets/ui/tv_widgets.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';
import 'history_screen.dart';
import 'qr_scan_screen.dart';
import 'search_engines_screen.dart';
import 'settings_screen.dart';

/// Tavrix home: identity, one search field, quick actions, speed dial and the
/// few sections that are genuinely useful before you start browsing.
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
    // Releasing the recogniser stops the microphone when the screen closes.
    _speech.stop();
    _speech.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    try {
      final shortcuts = await db.shortcuts();
      final topSites = await db.mostVisited(limit: 4);
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
    final titleController = TextEditingController(text: existing?.title ?? '');
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
            const SizedBox(height: TvSpace.md),
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
        : UrlUtils.resolveInput(
            url, context.read<SettingsProvider>().searchEngine);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvSpace.page,
                0,
                TvSpace.page,
                TvSpace.sm,
              ),
              child: Row(
                children: [
                  TvFavicon(url: shortcut.url, size: 34, radius: TvRadius.sm),
                  const SizedBox(width: TvSpace.md),
                  Expanded(
                    child: Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.title,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onNavigate(shortcut.url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
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
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final browser = context.watch<BrowserProvider>();
    final downloads = context.watch<DownloadProvider>();
    final recentDownloads = downloads.finished.take(3).toList();
    final recentlyClosed = browser.recentlyClosed.take(3).toList();
    final compact = settings.settings.compactLayout;

    return RefreshIndicator(
      onRefresh: _load,
      color: scheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: TvSpace.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.lg,
              TvSpace.md,
              TvSpace.lg,
            ),
            child: Row(
              children: [
                const TvBrandMark(),
                const Spacer(),
                TvIconButton(
                  icon: Icons.shield_moon_outlined,
                  tooltip: 'Private tab',
                  onTap: () => widget.onOpenTab('', isPrivate: true),
                ),
                const SizedBox(width: TvSpace.xs),
                TvIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                  onTap: () => _open(const SettingsScreen()),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TvSpace.page),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(TvRadius.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              padding: const EdgeInsets.only(left: TvSpace.lg, right: TvSpace.xs),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: TvSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.go,
                      onSubmitted: _submit,
                      style: TvText.body.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: TvSpace.lg),
                        hintText: 'Search with ${settings.searchEngine.name}',
                        hintStyle: TvText.body.copyWith(
                          fontSize: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  TvIconButton(
                    icon: Icons.mic_none_rounded,
                    iconSize: 19,
                    size: 36,
                    tooltip: 'Voice search',
                    onTap: _voiceSearch,
                  ),
                  TvIconButton(
                    icon: Icons.qr_code_scanner_rounded,
                    iconSize: 19,
                    size: 36,
                    tooltip: 'Scan QR code',
                    onTap: _scanQr,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.md,
              TvSpace.page,
              0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _open(const SearchEnginesScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TvSpace.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(TvRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore_rounded,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(settings.searchEngine.name, style: TvText.label),
                        const SizedBox(width: 2),
                        Icon(Icons.expand_more_rounded,
                            size: 15, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (recentlyClosed.isNotEmpty)
                  Text(
                    '${browser.tabs.length} tab${browser.tabs.length == 1 ? '' : 's'}',
                    style: TvText.caption,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.xl,
              TvSpace.page,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TvActionTile(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Bookmarks',
                    onTap: () => _open(const BookmarksScreen()),
                  ),
                ),
                Expanded(
                  child: TvActionTile(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () => _open(const HistoryScreen()),
                  ),
                ),
                Expanded(
                  child: TvActionTile(
                    icon: Icons.download_outlined,
                    label: 'Downloads',
                    onTap: () => _open(const DownloadsScreen()),
                    badge: downloads.active.isEmpty
                        ? null
                        : '${downloads.active.length}',
                  ),
                ),
                Expanded(
                  child: TvActionTile(
                    icon: Icons.shield_moon_outlined,
                    label: 'Private',
                    onTap: () => widget.onOpenTab('', isPrivate: true),
                  ),
                ),
              ],
            ),
          ),
          TvSectionHeader(
            title: 'Shortcuts',
            action: 'Add',
            onAction: () => _editShortcut(),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: TvSpace.xl),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TvSpace.page),
              child: GridView.count(
                crossAxisCount: compact ? 5 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: TvSpace.lg,
                crossAxisSpacing: TvSpace.md,
                childAspectRatio: 0.78,
                children: [
                  for (final shortcut in _shortcuts)
                    _ShortcutTile(
                      shortcut: shortcut,
                      onTap: () => widget.onNavigate(shortcut.url),
                      onLongPress: () => _shortcutMenu(shortcut),
                    ),
                  _AddShortcutTile(onTap: () => _editShortcut()),
                ],
              ),
            ),
          if (recentlyClosed.isNotEmpty) ...[
            const TvSectionHeader(title: 'Recently closed'),
            for (final closed in recentlyClosed)
              TvRow(
                icon: Icons.history_rounded,
                iconWidget: TvFavicon(
                  url: closed.url,
                  size: 34,
                  radius: TvRadius.sm,
                ),
                title: UrlUtils.cleanTitle(closed.title, closed.url),
                subtitle: UrlUtils.hostOf(closed.url).replaceFirst('www.', ''),
                dense: true,
                trailing: TvIconButton(
                  icon: Icons.restore_rounded,
                  iconSize: 18,
                  size: 32,
                  tooltip: 'Reopen',
                  onTap: () => browser.restoreClosedTab(closed),
                ),
                onTap: () => widget.onOpenTab(closed.url),
              ),
          ],
          if (recentDownloads.isNotEmpty) ...[
            TvSectionHeader(
              title: 'Recent downloads',
              action: 'All',
              onAction: () => _open(const DownloadsScreen()),
            ),
            for (final download in recentDownloads)
              TvRow(
                icon: Icons.insert_drive_file_outlined,
                title: download.filename,
                subtitle: download.statusLabel,
                dense: true,
                onTap: () => _open(const DownloadsScreen()),
              ),
          ],
          if (_topSites.isNotEmpty) ...[
            const TvSectionHeader(title: 'Top sites'),
            for (final site in _topSites)
              TvRow(
                icon: Icons.public_rounded,
                iconWidget:
                    TvFavicon(url: site.url, size: 34, radius: TvRadius.sm),
                title: UrlUtils.cleanTitle(site.title, site.url),
                subtitle: site.domain,
                dense: true,
                onTap: () => widget.onNavigate(site.url),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.shortcut,
    required this.onTap,
    required this.onLongPress,
  });

  final ShortcutItem shortcut;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(TvRadius.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TvFavicon(url: shortcut.url, size: 52, radius: TvRadius.lg),
          const SizedBox(height: TvSpace.sm),
          Text(
            shortcut.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TvText.caption.copyWith(height: 1.25),
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TvRadius.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TvRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(Icons.add_rounded, size: 22, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TvSpace.sm),
          const Text('Add', style: TvText.caption),
        ],
      ),
    );
  }
}
