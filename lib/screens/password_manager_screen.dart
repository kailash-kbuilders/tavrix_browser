import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/credential.dart';
import '../services/vault_service.dart';

/// Local password vault. Entries are stored in Keystore backed secure storage.
class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final VaultService _vault = VaultService();
  final Uuid _uuid = const Uuid();
  List<Credential> _credentials = [];
  bool _loading = true;
  bool _showPasswords = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final credentials = await _vault.all();
    if (!mounted) return;
    setState(() {
      _credentials = credentials;
      _loading = false;
    });
  }

  Future<void> _edit({Credential? credential}) async {
    final hostController = TextEditingController(text: credential?.host ?? '');
    final userController =
        TextEditingController(text: credential?.username ?? '');
    final passController =
        TextEditingController(text: credential?.password ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: Text(credential == null ? 'Add login' : 'Edit login'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    hintText: 'example.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('Generate strong password'),
                    onPressed: () {
                      passController.text = _vault.generatePassword();
                      setDialogState(() {});
                    },
                  ),
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
      ),
    );

    if (saved != true) return;
    final host = hostController.text.trim();
    final username = userController.text.trim();
    final password = passController.text;
    if (host.isEmpty || password.isEmpty) return;
    await _vault.save(Credential(
      id: credential?.id ?? _uuid.v4(),
      host: host,
      username: username,
      password: password,
      createdAt: credential?.createdAt ??
          DateTime.now().millisecondsSinceEpoch,
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password manager'),
        actions: [
          IconButton(
            tooltip: _showPasswords ? 'Hide passwords' : 'Show passwords',
            icon: Icon(_showPasswords
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: () => setState(() => _showPasswords = !_showPasswords),
          ),
          IconButton(
            tooltip: 'Add login',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _edit(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _credentials.isEmpty
              ? const Center(child: Text('No saved logins yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _credentials.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final credential = _credentials[index];
                    return ListTile(
                      leading: const Icon(Icons.key_rounded),
                      title: Text(credential.username.isEmpty
                          ? credential.host
                          : credential.username),
                      subtitle: Text(
                        _showPasswords
                            ? '${credential.host} - ${credential.password}'
                            : credential.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _edit(credential: credential),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'copy') {
                            await Clipboard.setData(
                                ClipboardData(text: credential.password));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Password copied')),
                            );
                          } else if (value == 'edit') {
                            await _edit(credential: credential);
                          } else if (value == 'delete') {
                            await _vault.delete(credential.id);
                            await _load();
                          }
                        },
                        itemBuilder: (menuContext) => const [
                          PopupMenuItem(
                              value: 'copy', child: Text('Copy password')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
