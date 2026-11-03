import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/credential.dart';
import '../utils/constants.dart';

/// Password vault. Entries live in Android Keystore backed secure storage as
/// JSON, so no plaintext password ever reaches SQLite, logs or backups.
class VaultService {
  VaultService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<List<Credential>> all() async {
    try {
      final raw = await _storage.read(key: TavrixConstants.vaultKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Credential.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<Credential> credentials) async {
    await _storage.write(
      key: TavrixConstants.vaultKey,
      value: jsonEncode(credentials.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> save(Credential credential) async {
    final credentials = await all();
    final index = credentials.indexWhere((item) => item.id == credential.id);
    if (index >= 0) {
      credentials[index] = credential;
    } else {
      credentials.add(credential);
    }
    await _write(credentials);
  }

  Future<void> delete(String id) async {
    final credentials = await all();
    credentials.removeWhere((item) => item.id == id);
    await _write(credentials);
  }

  Future<List<Credential>> forHost(String host) async {
    if (host.isEmpty) return [];
    final credentials = await all();
    final normalized = host.toLowerCase().replaceFirst('www.', '');
    return credentials
        .where((item) =>
            item.host.toLowerCase().replaceFirst('www.', '') == normalized)
        .toList();
  }

  Future<void> clear() async {
    await _storage.delete(key: TavrixConstants.vaultKey);
  }

  /// Cryptographically random password generator.
  String generatePassword({int length = 18, bool symbols = true}) {
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const digits = '23456789';
    const specials = r'!@#$%^&*()-_=+[]{}';
    final alphabet = '$lower$upper$digits${symbols ? specials : ''}';
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}
