import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/site_permission.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';

/// Site permissions (per website) plus the current Android OS permission state.
class PermissionProvider extends ChangeNotifier {
  PermissionProvider(this._db);

  final DatabaseService _db;

  List<SitePermission> _sites = [];
  Map<String, PermissionStatus> _osStatus = {};
  bool _loaded = false;

  List<SitePermission> get sites => List.unmodifiable(_sites);
  bool get isLoaded => _loaded;

  PermissionStatus? osStatus(String key) => _osStatus[key];

  Future<void> load() async {
    try {
      _sites = await _db.sitePermissions();
    } catch (_) {
      _sites = [];
    }
    await refreshOsStatus();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refreshOsStatus() async {
    try {
      _osStatus = {
        'camera': await PermissionService.cameraStatus(),
        'microphone': await PermissionService.microphoneStatus(),
        'location': await PermissionService.locationStatus(),
        'notifications': await PermissionService.notificationStatus(),
      };
    } catch (_) {
      _osStatus = {};
    }
    notifyListeners();
  }

  Future<SiteDecision?> decisionFor(String host, String permission) async {
    if (host.isEmpty) return null;
    try {
      return await _db.siteDecision(host, permission);
    } catch (_) {
      return null;
    }
  }

  Future<void> setDecision(
      String host, String permission, SiteDecision decision) async {
    if (host.isEmpty) return;
    try {
      await _db.setSiteDecision(host, permission, decision);
      _sites = await _db.sitePermissions();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resetSite(String host) async {
    try {
      await _db.deleteSitePermissions(host);
      _sites = await _db.sitePermissions();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resetAll() async {
    try {
      await _db.clearSitePermissions();
      _sites = [];
      notifyListeners();
    } catch (_) {}
  }

  /// True only when the website decision and the Android permission both allow
  /// the feature. A website never inherits the OS permission on its own.
  Future<bool> allowSiteFeature({
    required String host,
    required String permission,
    required Future<bool> Function() requestOs,
    required Future<bool> Function() hasOs,
  }) async {
    final decision = await decisionFor(host, permission);
    if (decision == SiteDecision.block) return false;
    var granted = await hasOs();
    if (!granted) granted = await requestOs();
    if (!granted) return false;
    if (decision == null) {
      await setDecision(host, permission, SiteDecision.allow);
    }
    return true;
  }

  Future<void> openSystemSettings() => PermissionService.openSystemSettings();
}
