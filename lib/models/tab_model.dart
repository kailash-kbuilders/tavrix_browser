import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// One browser tab. The live [controller] is never persisted.
class TabModel {
  TabModel({
    required this.id,
    this.url = '',
    this.title = 'New tab',
    this.isPrivate = false,
    this.isPinned = false,
    this.groupName,
    this.isDesktopMode = false,
  });

  final String id;
  String url;
  String title;
  final bool isPrivate;
  bool isPinned;
  String? groupName;
  String? faviconUrl;
  bool isLoading = false;
  double progress = 0;
  bool canGoBack = false;
  bool canGoForward = false;
  bool isSecure = true;
  bool isDesktopMode;
  String? errorMessage;

  /// Set by the WebView widget once the platform view is ready.
  InAppWebViewController? controller;

  bool get isBlank => url.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'isPinned': isPinned,
        'groupName': groupName,
      };

  factory TabModel.fromJson(Map<String, dynamic> json) => TabModel(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        url: json['url'] as String? ?? '',
        title: json['title'] as String? ?? 'New tab',
        isPinned: json['isPinned'] as bool? ?? false,
        groupName: json['groupName'] as String?,
      );
}
