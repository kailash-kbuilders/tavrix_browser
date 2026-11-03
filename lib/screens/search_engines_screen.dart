import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/search_engine.dart';
import '../providers/settings_provider.dart';

/// Search engine picker: defaults plus user defined engines.
class SearchEnginesScreen extends StatelessWidget {
  const SearchEnginesScreen({super.key});

  Future<void> _edit(
      BuildContext context, SettingsProvider settings, {SearchEngine? engine}) async {
    final nameController = TextEditingController(text: engine?.name ?? '');
    final templateController =
        TextEditingController(text: engine?.searchTemplate ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(engine == null ? 'Add search engine' : 'Edit engine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: templateController,
              decoration: const InputDecoration(
                labelText: 'Search URL',
                hintText: 'https://example.com/search?q=%s',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use %s where the search words should go.',
              style: TextStyle(fontSize: 12),
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
    if (saved != true) return;
    final name = nameController.text.trim();
    final template = templateController.text.trim();
    if (name.isEmpty || !template.contains('%s')) return;
    if (engine == null) {
      await settings.addSearchEngine(SearchEngine(
        id: const Uuid().v4(),
        name: name,
        searchTemplate: template,
        isCustom: true,
      ));
    } else {
      await settings.updateSearchEngine(SearchEngine(
        id: engine.id,
        name: name,
        searchTemplate: template,
        suggestTemplate: engine.suggestTemplate,
        isCustom: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final engines = settings.searchEngines;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search engines'),
        actions: [
          IconButton(
            tooltip: 'Add engine',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _edit(context, settings),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final engine in engines)
            ListTile(
              leading: Icon(settings.settings.searchEngineId == engine.id
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded),
              title: Text(engine.name),
              subtitle: Text(
                engine.searchTemplate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => settings.setSearchEngine(engine.id),
              trailing: engine.isCustom
                  ? PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _edit(context, settings, engine: engine);
                        } else if (value == 'delete') {
                          await settings.removeSearchEngine(engine.id);
                        }
                      },
                      itemBuilder: (menuContext) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
