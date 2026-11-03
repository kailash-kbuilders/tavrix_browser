import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../utils/navigation_helper.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<String>(
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
              PopupMenuItem(value: 'day', child: Text('Clear last 24 hours')),
              PopupMenuItem(value: 'week', child: Text('Clear last 7 days')),
              PopupMenuItem(value: 'all', child: Text('Clear all history')),
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
                hintText: 'Search history',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: provider.search,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : keys.isEmpty
                    ? Center(
                        child: Text(
                          provider.query.isEmpty
                              ? 'No history yet'
                              : 'No matching pages',
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          for (final key in keys) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 6),
                              child: Text(
                                _label(key),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            for (final entry in grouped[key]!)
                              ListTile(
                                leading: const Icon(Icons.public_rounded),
                                title: Text(
                                  entry.title.isEmpty
                                      ? entry.url
                                      : entry.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${entry.domain} - ${DateFormat.Hm().format(entry.visitedDate)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () =>
                                    openUrlInBrowser(context, entry.url),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => provider.removeEntry(entry),
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
    final parts = key.split('-');
    if (parts.length != 3) return key;
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
