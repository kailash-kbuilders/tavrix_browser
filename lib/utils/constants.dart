/// App-wide constants for Tavrix Browser.
class TavrixConstants {
  TavrixConstants._();

  static const String appName = 'Tavrix Browser';
  static const String tagline = 'Browse Beyond Limits.';
  static const String version = '1.0.0';

  /// Used when the user switches a page to desktop mode.
  /// Windows Chrome is what "Request desktop site" sends in every major
  /// browser, and it is the profile websites are most likely to answer with a
  /// desktop layout.
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  static const String sessionKey = 'tavrix.session.v1';
  static const String settingsKey = 'tavrix.settings.v1';
  static const String searchEnginesKey = 'tavrix.searchengines.v1';
  static const String vaultKey = 'tavrix.vault.v1';

  /// Download notification ids start here so they never collide with other ids.
  static const int downloadNotificationBase = 1000;
}
