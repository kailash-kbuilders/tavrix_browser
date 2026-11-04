# Known limitations

Tavrix Browser renders pages with the Android System WebView (Chromium). The
WebView is a powerful engine but it is not Chrome: it does not expose Chrome
extensions, native printing, or web push. Everything below is a real limit of
the engine or of this build - none of it is simulated in the UI.

## Engine limits (not fixable in this project)

1. **Printing / save as PDF** - `flutter_inappwebview` exposes no print API.
   There is no Print menu item, so no dead button exists.
2. **Extensions** - the system WebView cannot load Chrome extensions.
3. **Web push from websites** - sites cannot deliver background push through the
   WebView. Website permission entries are still tracked per host, but a site
   cannot push notifications in the background.
4. **PWA installation** - no install prompt or install flow is exposed.
5. **Popup windows** - `supportMultipleWindows` is off, so `target="_blank"`
   links open in the current tab instead of a separate window. This is a
   deliberate trade-off: a half-wired popup flow loses pages, this one does not.

## Limits of this build

6. **Notification actions** - progress, completion and failure notifications are
   real. Pause/resume/cancel buttons inside the notification are not wired;
   those actions live in the in-app Downloads screen.
7. **Background downloads** - downloads continue while the app is running or
   backgrounded. After a force-stop, a device reboot or an OEM background kill,
   Android stops the transfer. Records and partial files are kept, so the
   download can be resumed from the Downloads screen.
8. **Pull-to-refresh** - not wired. The toolbar reload button is the refresh
   path. A WebView cannot be wrapped in a `RefreshIndicator`, and the
   JavaScript-based workaround conflicts with page scrolling.
9. **Edge-swipe back** - not wired. The back button and the system back gesture
   (handled by `PopScope`) navigate the page.
10. **Biometric lock** - `USE_BIOMETRIC` is declared, but no biometric prompt is
    implemented, so private tabs and the vault are protected by the device lock
    only.
11. **Autofill scope** - fills username/password fields for a saved login on the
    current site. It does not fill addresses or phone numbers.
12. **Encrypted password export** - not implemented. Passwords never leave the
    device in plaintext because they never leave the device at all.
13. **HTTP cache clearing** - cookies and web storage can be cleared from the
    Privacy dashboard. The WebView's HTTP cache is cleared by the OS when app
    data is cleared.
14. **Translation** - opens the current page through Google Translate's web
    translator. There is no in-app translation overlay.
15. **Desktop mode** - Tavrix sends a desktop user agent and reloads the page.
    Sites that detect the device by other means (screen width, touch support,
    `navigator.maxTouchPoints`) can still serve a mobile layout; no browser can
    force those.
16. **Tab previews** - captured with `takeScreenshot` when the tab overview
    opens, capped at 6 tabs per open. Tabs without a controller (blank tabs, or
    a WebView that refused the screenshot) show a tinted fallback card.
17. **Reader mode extraction** - heuristic (largest text container). Pages built
    entirely from canvas or heavy custom layouts may produce little text, in
    which case Tavrix says "no readable article found" instead of showing an
    empty reader.

## Verification status

- `flutter analyze` on Flutter 3.47.9 (Dart 3.13.7): **no issues found**.
- `flutter test`: **16 tests passed** (URL handling, search engines, download
  model, address bar widget).
- Every plugin API used here was checked against the published package source
  for the exact versions pinned in `pubspec.yaml`.

The APK itself is produced by the GitHub Actions workflow
(`.github/workflows/build-apk.yml`) - there is no Android SDK in the environment
this project was generated in, so no APK was compiled locally. The first
workflow run is the device-level build check; read its log before trusting a
release.
