import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/browser_provider.dart';

/// Closes any pushed screen and loads [url] in the browser.
void openUrlInBrowser(BuildContext context, String url, {bool newTab = false}) {
  final browser = context.read<BrowserProvider>();
  Navigator.of(context).popUntil((route) => route.isFirst);
  if (url.trim().isEmpty) return;
  if (newTab) {
    browser.openTab(url: url);
    return;
  }
  final tab = browser.activeTab;
  if (tab == null) {
    browser.openTab(url: url);
    return;
  }
  browser.navigate(tab.id, url);
}
