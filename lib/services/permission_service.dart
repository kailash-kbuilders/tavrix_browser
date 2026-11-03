import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper over permission_handler so screens do not import the plugin
/// directly and Android version differences stay in one place.
class PermissionService {
  PermissionService._();

  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> notificationsGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> cameraGranted() async {
    return (await Permission.camera.status).isGranted;
  }

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> microphoneGranted() async {
    return (await Permission.microphone.status).isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> locationGranted() async {
    return (await Permission.location.status).isGranted;
  }

  static Future<PermissionStatus> cameraStatus() => Permission.camera.status;

  static Future<PermissionStatus> microphoneStatus() =>
      Permission.microphone.status;

  static Future<PermissionStatus> locationStatus() => Permission.location.status;

  static Future<PermissionStatus> notificationStatus() =>
      Permission.notification.status;

  static Future<bool> openSystemSettings() => openAppSettings();
}
