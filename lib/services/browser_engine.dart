import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/app_settings.dart';
import '../utils/constants.dart';

/// The browser engine abstraction.
///
/// Tavrix uses the Android System WebView (Chromium) through
/// flutter_inappwebview. Everything engine specific lives here so the engine
/// can be swapped later without touching the UI, and so engine limits are
/// documented in one place.
class BrowserEngine {
  BrowserEngine._();

  /// Settings for one tab. Private tabs use `incognito` so cookies and web
  /// storage are isolated from normal tabs.
  static InAppWebViewSettings settingsFor({
    required AppSettings appSettings,
    required bool isPrivate,
    bool desktopMode = false,
  }) {
    return InAppWebViewSettings(
      incognito: isPrivate,
      javaScriptEnabled: appSettings.javaScriptEnabled,
      useShouldOverrideUrlLoading: true,
      useOnDownloadStart: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      supportMultipleWindows: false,
      javaScriptCanOpenWindowsAutomatically: false,
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      useWideViewPort: true,
      loadWithOverviewMode: true,
      geolocationEnabled: true,
      allowFileAccess: true,
      allowContentAccess: true,
      thirdPartyCookiesEnabled: appSettings.cookiesEnabled,
      userAgent: desktopMode ? TavrixConstants.desktopUserAgent : null,
      transparentBackground: false,
      useHybridComposition: true,
      disableDefaultErrorPage: true,
      isInspectable: false,
    );
  }

  // ------------------------------------------------------------- page scripts

  /// Extracts the main article text for Reader Mode.
  static const String readerExtractionScript = r'''
(function () {
  try {
    var candidates = document.querySelectorAll(
      'article, main, [role="main"], .post, .article, .entry-content, .content, #content'
    );
    var best = null;
    var bestScore = 0;
    for (var i = 0; i < candidates.length; i++) {
      var text = candidates[i].innerText || '';
      if (text.length > bestScore) {
        bestScore = text.length;
        best = candidates[i];
      }
    }
    if (!best || bestScore < 400) {
      best = document.body;
    }
    var title = document.title || '';
    var byline = '';
    var meta = document.querySelector('meta[name="author"]');
    if (meta) { byline = meta.getAttribute('content') || ''; }
    var text = (best.innerText || '').replace(/\n{3,}/g, '\n\n').trim();
    return JSON.stringify({ title: title, byline: byline, text: text });
  } catch (e) {
    return JSON.stringify({ title: document.title || '', byline: '', text: '' });
  }
})()
''';

  /// Wraps every match of [query] in a <mark> and returns the match count.
  static String findInPageScript(String query) {
    final encoded = jsonEncode(query);
    return '''
(function (q) {
  try {
    var HIT = 'tavrix-find-hit';
    var marks = document.querySelectorAll('mark.' + HIT);
    for (var i = 0; i < marks.length; i++) {
      var mark = marks[i];
      var parent = mark.parentNode;
      if (parent) {
        parent.replaceChild(document.createTextNode(mark.textContent), mark);
        parent.normalize();
      }
    }
    if (!q) { return 0; }
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!node.nodeValue || !node.nodeValue.trim()) { return NodeFilter.FILTER_REJECT; }
        var p = node.parentNode;
        if (!p) { return NodeFilter.FILTER_REJECT; }
        var tag = p.nodeName ? p.nodeName.toLowerCase() : '';
        if (tag === 'script' || tag === 'style' || tag === 'noscript' ||
            tag === 'textarea' || tag === 'mark') {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    var nodes = [];
    while (walker.nextNode()) { nodes.push(walker.currentNode); }
    var needle = q.toLowerCase();
    var count = 0;
    for (var n = 0; n < nodes.length && count < 500; n++) {
      var node = nodes[n];
      var text = node.nodeValue || '';
      var lower = text.toLowerCase();
      var index = lower.indexOf(needle);
      if (index === -1) { continue; }
      var fragment = document.createDocumentFragment();
      var position = 0;
      while (index !== -1 && count < 500) {
        if (index > position) {
          fragment.appendChild(document.createTextNode(text.substring(position, index)));
        }
        var hit = document.createElement('mark');
        hit.className = HIT;
        hit.style.backgroundColor = '#FFD54F';
        hit.style.color = '#000000';
        hit.setAttribute('data-tavrix-index', String(count));
        hit.textContent = text.substring(index, index + q.length);
        fragment.appendChild(hit);
        count++;
        position = index + q.length;
        index = lower.indexOf(needle, position);
      }
      if (position < text.length) {
        fragment.appendChild(document.createTextNode(text.substring(position)));
      }
      if (node.parentNode) {
        node.parentNode.replaceChild(fragment, node);
      }
    }
    return count;
  } catch (e) {
    return 0;
  }
})($encoded)
''';
  }

  static String scrollToMatchScript(int index) => '''
(function (i) {
  try {
    var hits = document.querySelectorAll('mark.tavrix-find-hit');
    if (i < 0 || i >= hits.length) { return false; }
    for (var n = 0; n < hits.length; n++) {
      hits[n].style.backgroundColor = '#FFD54F';
    }
    hits[i].style.backgroundColor = '#FF8A65';
    hits[i].scrollIntoView({ block: 'center' });
    return true;
  } catch (e) {
    return false;
  }
})($index)
''';

  /// Reads the whole page markup so it can be stored for offline reading.
  static const String savePageScript = r'''
(function () {
  try {
    return document.documentElement.outerHTML || '';
  } catch (e) {
    return '';
  }
})()
''';

  /// Clears web storage for the current origin.
  static const String clearWebStorageScript = r'''
(function () {
  try {
    window.localStorage.clear();
    window.sessionStorage.clear();
    return true;
  } catch (e) {
    return false;
  }
})()
''';

  /// Fills a login form. Values are JSON encoded so quotes are safe.
  static String autofillScript(String username, String password) {
    final user = jsonEncode(username);
    final pass = jsonEncode(password);
    return '''
(function (u, p) {
  function fill(selector, value) {
    try {
      var fields = document.querySelectorAll(selector);
      for (var i = 0; i < fields.length; i++) {
        var field = fields[i];
        if (field.value) { continue; }
        field.focus();
        field.value = value;
        field.dispatchEvent(new Event('input', { bubbles: true }));
        field.dispatchEvent(new Event('change', { bubbles: true }));
        return true;
      }
    } catch (e) {}
    return false;
  }
  var a = fill('input[type="email"], input[autocomplete="username"], input[name*="user" i], input[id*="user" i], input[name*="email" i], input[id*="email" i]', u);
  var b = fill('input[type="password"]', p);
  return a || b;
})($user, $pass)
''';
  }

  /// Script injected into every page to report the Do Not Track preference.
  static const String doNotTrackScript = r'''
(function () {
  try {
    Object.defineProperty(navigator, 'doNotTrack', { get: function () { return '1'; } });
  } catch (e) {}
})()
''';
}
