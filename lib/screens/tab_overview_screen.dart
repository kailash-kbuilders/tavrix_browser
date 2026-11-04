import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../models/tab_model.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/tokens.dart';
import '../utils/url_utils.dart';
import '../widgets/tab_card.dart';
import '../widgets/ui/tv_widgets.dart';

/// Tab overview: grid or list, search, groups, private separation and
/// recently closed tabs.
class TabOverviewScreen extends StatefulWidget {
  const TabOverviewScreen({super.key});

  @override
  State<TabOverviewScreen> createState() => _TabOverviewScreenState();
}

class _TabOverviewScreenState extends State<TabOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureThumbnails());
  }

  /// Real page previews: each live WebView is asked for a screenshot when the
  /// overview opens. Tabs without a controller (blank tabs) simply keep the
  /// clean fallback card.
  Future<void> _captureThumbnails() async {
    if (_capturing) return;
    _capturing = true;
    final browser = context.read<BrowserProvider>();
    var captured = 0;
    for (final tab in browser.tabs) {
      if (captured >= 6) break;
      final controller = tab.controller;
      if (controller == null || tab.isBlank) continue;
      try {
        final bytes = await controller.takeScreenshot(
          screenshotConfiguration: ScreenshotConfiguration(
            compressFormat: CompressFormat.JPEG,
            quality: 50,
          ),
        );
        if (bytes == null || bytes.isEmpty) continue;
        tab.thumbnail = bytes;
        captured++;
        if (mounted) setState(() {});
      } catch (_) {}
    }
    _capturing = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TabModel> _filter(List<TabModel> tabs) {
    if (_query.trim().isEmpty) return tabs;
    final needle = _query.trim().toLowerCase();
    return tabs
        .where((tab) =>
            tab.title.toLowerCase().contains(needle) ||
            tab.url.toLowerCase().contains(needle))
        .toList();
  }

  Future<void> _tabMenu(TabModel tab) async {
    final browser = context.read<BrowserProvider>();
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
                  TvFavicon(url: tab.url, size: 34, radius: TvRadius.sm),
                  const SizedBox(width: TvSpace.md),
                  Expanded(
                    child: Text(
                      UrlUtils.cleanTitle(tab.title, tab.url),
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
              title: const Text('Open tab'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                browser.activateTab(tab.id);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                browser.duplicateTab(tab.id);
              },
            ),
            ListTile(
              leading: Icon(tab.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined),
              title: Text(tab.isPinned ? 'Unpin tab' : 'Pin tab'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                browser.togglePin(tab.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(tab.groupName == null
                  ? 'Add to group'
                  : 'Group: ${tab.groupName}'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _editGroup(tab);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded),
              title: const Text('Move left'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                final index = browser.tabs.indexWhere((t) => t.id == tab.id);
                if (index > 0) browser.reorderTabs(index, index - 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_forward_rounded),
              title: const Text('Move right'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                final index = browser.tabs.indexWhere((t) => t.id == tab.id);
                if (index >= 0 && index < browser.tabs.length - 1) {
                  browser.reorderTabs(index, index + 2);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Close tab'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                browser.closeTab(tab.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGroup(TabModel tab) async {
    final controller = TextEditingController(text: tab.groupName ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tab group name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Work'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    await context.read<BrowserProvider>().setTabGroup(tab.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isGrid = settings.settings.tabLayout != 'list';
    final regular = _filter(browser.regularTabs);
    final privateTabs = _filter(browser.privateTabs);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tabs (${browser.tabs.length})'),
        actions: [
          IconButton(
            tooltip: isGrid ? 'List view' : 'Grid view',
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => settings.setTabLayout(isGrid ? 'list' : 'grid'),
          ),
          IconButton(
            tooltip: 'New private tab',
            icon: const Icon(Icons.shield_moon_outlined),
            onPressed: () {
              browser.openTab(isPrivate: true);
              Navigator.of(context).pop();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'closeAll') {
                await browser.closeAllTabs();
              } else if (value == 'closePrivate') {
                await browser.closeAllPrivateTabs();
              }
            },
            itemBuilder: (menuContext) => const [
              PopupMenuItem(value: 'closeAll', child: Text('Close all tabs')),
              PopupMenuItem(
                  value: 'closePrivate', child: Text('Close private tabs')),
            ],
          ),
          const SizedBox(width: TvSpace.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New tab',
        onPressed: () {
          browser.openTab();
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: TvSpace.xxxl * 2),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.sm,
              TvSpace.page,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search tabs',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (privateTabs.isNotEmpty) ...[
            const TvSectionHeader(title: 'Private tabs'),
            _TabCollection(
              tabs: privateTabs,
              isGrid: isGrid,
              onTap: (tab) {
                browser.activateTab(tab.id);
                Navigator.of(context).pop();
              },
              onLongPress: _tabMenu,
              onClose: (tab) => browser.closeTab(tab.id),
            ),
          ],
          TvSectionHeader(
            title: 'Open tabs',
            action: '${regular.length}',
          ),
          if (regular.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: TvSpace.xl),
              child: Center(
                child: Text(
                  'No open tabs',
                  style: TvText.bodyMuted,
                ),
              ),
            )
          else
            _TabCollection(
              tabs: regular,
              isGrid: isGrid,
              onTap: (tab) {
                browser.activateTab(tab.id);
                Navigator.of(context).pop();
              },
              onLongPress: _tabMenu,
              onClose: (tab) => browser.closeTab(tab.id),
            ),
          if (browser.recentlyClosed.isNotEmpty) ...[
            TvSectionHeader(
              title: 'Recently closed',
              action: 'Refresh',
              onAction: browser.refreshRecentlyClosed,
            ),
            for (final closed in browser.recentlyClosed)
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
                  onTap: () {
                    browser.restoreClosedTab(closed);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  browser.restoreClosedTab(closed);
                  Navigator.of(context).pop();
                },
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: TvSpace.xl),
            child: Center(
              child: Text(
                isGrid ? 'Swipe a card to close it' : 'Swipe a row to close it',
                style: TvText.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabCollection extends StatelessWidget {
  const _TabCollection({
    required this.tabs,
    required this.isGrid,
    required this.onTap,
    required this.onLongPress,
    required this.onClose,
  });

  final List<TabModel> tabs;
  final bool isGrid;
  final ValueChanged<TabModel> onTap;
  final ValueChanged<TabModel> onLongPress;
  final ValueChanged<TabModel> onClose;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: TvSpace.page),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tabs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: TvSpace.md,
            crossAxisSpacing: TvSpace.md,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final tab = tabs[index];
            return Dismissible(
              key: ValueKey(tab.id),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => onClose(tab),
              background:
                  const _DismissBackground(alignment: Alignment.centerLeft),
              secondaryBackground:
                  const _DismissBackground(alignment: Alignment.centerRight),
              child: TabCard(
                tab: tab,
                onTap: () => onTap(tab),
                onLongPress: () => onLongPress(tab),
                onClose: () => onClose(tab),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        for (final tab in tabs)
          Dismissible(
            key: ValueKey('list-${tab.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onClose(tab),
            background:
                const _DismissBackground(alignment: Alignment.centerRight),
            child: TvRow(
              icon: Icons.public_rounded,
              iconWidget: TvFavicon(url: tab.url, size: 34, radius: TvRadius.sm),
              title: UrlUtils.cleanTitle(tab.title, tab.url),
              subtitle: UrlUtils.hostOf(tab.url).replaceFirst('www.', ''),
              dense: true,
              onTap: () => onTap(tab),
              onLongPress: () => onLongPress(tab),
              trailing: TvIconButton(
                icon: Icons.close_rounded,
                iconSize: 17,
                size: 30,
                tooltip: 'Close',
                onTap: () => onClose(tab),
              ),
            ),
          ),
      ],
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: TvSpace.xl),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(TvRadius.md),
      ),
      child: Icon(Icons.close_rounded, color: scheme.onErrorContainer),
    );
  }
}
