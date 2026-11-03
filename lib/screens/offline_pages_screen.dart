import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/offline_page.dart';
import '../services/database_service.dart';
import '../utils/navigation_helper.dart';

/// Saved pages for offline reading.
class OfflinePagesScreen extends StatefulWidget {
  const OfflinePagesScreen({super.key});

  @override
  State<OfflinePagesScreen> createState() => _OfflinePagesScreenState();
}

class _OfflinePagesScreenState extends State<OfflinePagesScreen> {
  List<OfflinePage> _pages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pages = await context.read<DatabaseService>().offlinePages();
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline pages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pages.isEmpty
              ? const Center(
                  child: Text('No saved pages. Use the menu to save one.'))
              : ListView.separated(
                  itemCount: _pages.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(
                        page.title.isEmpty ? page.url : page.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('d MMM, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(
                            page.savedAt)),
                      ),
                      onTap: () =>
                          openUrlInBrowser(context, 'file://${page.filePath}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          if (page.id == null) return;
                          await context
                              .read<DatabaseService>()
                              .deleteOfflinePage(page.id!);
                          await _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
