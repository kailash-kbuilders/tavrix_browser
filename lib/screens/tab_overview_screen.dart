import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tab_model.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/url_utils.dart';
import '../widgets/tab_card.dart';

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
    final theme = Theme.of(context);
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
            onPressed: () =>
                settings.setTabLayout(isGrid ? 'list' : 'grid'),
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
            onSelected: (value) async {
              if (value == 'closeAll') {
                await browser.closeAllTabs();
              } else if (value == 'closePrivate') {
                await browser.closeAllPrivateTabs();
              } else if (value == 'clearClosed') {
                await context.read<BrowserProvider>().refreshRecentlyClosed();
              }
            },
            itemBuilder: (menuContext) => const [
              PopupMenuItem(value: 'closeAll', child: Text('Close all tabs')),
              PopupMenuItem(
                  value: 'closePrivate', child: Text('Close private tabs')),
            ],
          ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Search tabs',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (privateTabs.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.shield_moon_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Private tabs',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Text('Open tabs',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${regular.length}',
                  style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          if (regular.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No open tabs',
                    style: theme.textTheme.bodyMedium),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Recently closed',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () => browser.refreshRecentlyClosed(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            for (final closed in browser.recentlyClosed)
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
                onTap: () {
                  browser.restoreClosedTab(closed);
                  Navigator.of(context).pop();
                },
              ),
          ],
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
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tabs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return Dismissible(
            key: ValueKey(tab.id),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => onClose(tab),
            background: const _DismissBackground(alignment: Alignment.centerLeft),
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
      );
    }

    return Column(
      children: [
        for (final tab in tabs)
          Dismissible(
            key: ValueKey('list-${tab.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onClose(tab),
            background: const _DismissBackground(
                alignment: Alignment.centerRight),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => onTap(tab),
                onLongPress: () => onLongPress(tab),
                leading: Icon(tab.isPrivate
                    ? Icons.shield_moon_outlined
                    : Icons.public_rounded),
                title: Text(
                  tab.title.isEmpty ? 'New tab' : tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  UrlUtils.displayUrl(tab.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onClose(tab),
                ),
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
    final theme = Theme.of(context);
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.close_rounded, color: theme.colorScheme.onErrorContainer),
    );
  }
}
