import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../theme/tokens.dart';
import '../utils/navigation_helper.dart';
import '../utils/url_utils.dart';
import '../widgets/ui/tv_widgets.dart';

/// Browsing history grouped by day, with search and range deletion.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final grouped = provider.grouped;
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'hour') {
                await provider.clearRange(range: const Duration(hours: 1));
              } else if (value == 'day') {
                await provider.clearRange(range: const Duration(days: 1));
              } else if (value == 'week') {
                await provider.clearRange(range: const Duration(days: 7));
              } else if (value == 'all') {
                await provider.clearAll();
              }
            },
            itemBuilder: (menuContext) => const [
              PopupMenuItem(value: 'hour', child: Text('Clear last hour')),
              PopupMenuItem(
                  value: 'day', child: Text('Clear last 24 hours')),
              PopupMenuItem(value: 'week', child: Text('Clear last 7 days')),
              PopupMenuItem(value: 'all', child: Text('Clear all history')),
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
                hintText: 'Search history',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: provider.search,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : keys.isEmpty
                    ? TvEmptyState(
                        icon: Icons.history_rounded,
                        title: provider.query.isEmpty
                            ? 'No history yet'
                            : 'No matching pages',
                        message: provider.query.isEmpty
                            ? 'Pages you visit will show up here. Private tabs are never recorded.'
                            : 'Try a different word.',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: TvSpace.xxl),
                        children: [
                          for (final key in keys) ...[
                            TvSectionHeader(
                              title: _label(key),
                              padding: const EdgeInsets.fromLTRB(
                                TvSpace.page,
                                TvSpace.lg,
                                TvSpace.page,
                                TvSpace.xs,
                              ),
                            ),
                            for (final entry in grouped[key]!)
                              TvRow(
                                icon: Icons.public_rounded,
                                iconWidget: TvFavicon(
                                  url: entry.url,
                                  size: 34,
                                  radius: TvRadius.sm,
                                ),
                                title:
                                    UrlUtils.cleanTitle(entry.title, entry.url),
                                subtitle:
                                    '${entry.domain} · ${DateFormat.Hm().format(entry.visitedDate)}',
                                dense: true,
                                onTap: () =>
                                    openUrlInBrowser(context, entry.url),
                                trailing: TvIconButton(
                                  icon: Icons.close_rounded,
                                  iconSize: 17,
                                  size: 30,
                                  tooltip: 'Remove',
                                  onTap: () => provider.removeEntry(entry),
                                ),
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  String _label(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.yMMMEd().format(date);
  }
}
