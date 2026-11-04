# Tavrix Browser - Release QA Audit

Date: 2026-11-03
Build audited: v1.1.0 (commit `main` before this report), Flutter 3.47.9 / Dart 3.13.7
Scope: full repository review against the PRD, FEATURE_CHECKLIST.md and KNOWN_LIMITATIONS.md. No new features were added.

## 1. What this audit could and could not do

| Activity | Done? | How |
| --- | --- | --- |
| Static analysis of every Dart file | Yes | `flutter analyze` - **no issues found** |
| Automated tests | Yes | `flutter test` - **30 tests pass** (see section 6) |
| Real SQLite schema and queries | Yes | `sqflite_common_ffi` runs the actual `DatabaseService` schema in-process |
| Release APK build | Yes | GitHub Actions `Build APK`, `flutter build apk --release --no-shrink` |
| Inspecting the built APK | Yes | resource table, adaptive-icon XMLs, signature block |
| Running the app on a phone or emulator | **No** | this environment has no Android SDK, no emulator and no physical device |
| Verifying gestures, notifications on screen, downloads over a real network, permission dialogs | **No** | needs a device; every such item is marked "needs device testing" |

Anything below marked *needs device testing* is code-verified only. It is not "tested" in the sense of having been run.

## 2. Confirmed bugs found and fixed

Each of these was reproduced from the code (two were reproduced by a failing test before the fix).

1. **History domain list was always empty (real SQL bug).**
   `DatabaseService.historyDomains()` used `domain != ""`. In SQLite a double-quoted token is an *identifier*, so the statement failed with `no such column: ""`. The error was swallowed by the History screen's try/catch, so the domain filter silently had no data.
   *Reproduced by* `test/database_service_test.dart` before the fix. Fixed to `domain != ''`.

2. **Interrupted downloads were stuck forever.**
   A download record left as `running`/`queued` after process death was restored as-is: the progress bar sat at 0% with a pause button whose cancel token no longer existed, so nothing could restart it.
   Fixed: `DownloadProvider.load()` converts stale `running`/`queued` rows to `paused` with the message "Interrupted - tap resume", so the existing Resume action works.

3. **Engine settings only applied to new tabs.**
   JavaScript, cookies, pop-up and Do-Not-Track switches changed `AppSettings`, but an open tab kept the settings it was created with, so the switches appeared broken until the tab was closed.
   Fixed: `TabWebView` now watches settings, compares a signature of the engine-relevant fields and pushes them to the live WebView with `InAppWebViewController.setSettings()`.

4. **A single wrong-typed preference could wipe all settings.**
   `AppSettings.fromJson` used hard casts (`as bool?`, `as num?`). One corrupted or older value (`"fontScale": "big"`) threw, `SettingsService` fell back to defaults and the user lost every preference.
   Fixed with tolerant `_string/_bool/_int/_double` helpers. Covered by tests, including numeric strings.

5. **"Reset all settings" reset 8 of 26 preferences.**
   Fixed: new `SettingsProvider.resetAll()` restores the complete default object.

6. **Non-functional controls (PRD rule: no visible control may be non-functional).**
   - `haptics` did nothing -> wired to `HapticFeedback.selectionClick()` on submit and tab swipe, still gated by the switch.
   - `animations` did nothing -> page transitions become instant when it is off.
   - `desktopMode` ("desktop mode by default") did nothing -> new tabs now start in desktop mode.
   - `swipeAddressBarSwitchesTabs` did nothing (the swipe always switched tabs) -> now gated by the switch.
   - `edgeSwipeNavigation` did nothing -> real left/right edge strips navigate back/forward.
   - `blockPopups` and `notifyWebsite` cannot work with this engine (multiple windows are disabled; web push is unsupported), so both switches were **removed** from Settings and Privacy instead of pretending.

7. **History "Clear today" deleted the last 24 hours**, not today. Label corrected to "Clear last 24 hours".

8. **Dead code in the tab overview menu** - a `clearClosed` branch that only refreshed the list. Removed.

9. **Microphone could stay open** if the home screen was closed while voice search was listening. `HomeScreen.dispose()` now stops and cancels the recogniser.

10. **Manifest declared permissions the app never uses**: `USE_BIOMETRIC`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `VIBRATE`. All removed; `HapticFeedback` needs no permission.

## 3. Security review

| # | Finding | Severity | Status |
| --- | --- | --- | --- |
| S1 | `shouldOverrideUrlLoading` launched **any** non-http scheme with `url_launcher`, including `intent:` URIs, which can start arbitrary app components from a web page | Medium | **Fixed** - allowlist (`mailto`, `tel`, `sms`, `smsto`, `whatsapp`, `geo`, `market`, `upi`, `tg`, `maps`); everything else is cancelled |
| S2 | Download requests accepted any URL scheme before touching the file system | Low | **Fixed** - only `http`, `https`, `blob`, `data` accepted |
| S3 | A site's first camera/microphone/location request is auto-allowed once the Android permission is granted; there is no in-app per-site prompt | Medium | **Open** - tracked as a gap (see section 5) |
| S4 | `allowFileAccess: true` is required to open pages saved for offline reading. `allowFileAccessFromFileURLs` and `allowUniversalAccessFromFileURLs` stay off, so a `file://` page cannot read other local files | Low | **Accepted, documented** |
| S5 | No TLS bypass anywhere: there is no `onReceivedServerTrustAuthRequest` handler and no certificate callback, so the WebView's own validation always applies | - | Verified clean |
| S6 | Passwords are never written to SQLite, logs or backups; the vault lives in Keystore-backed secure storage. Autofill writes the credential into the page's DOM, which is inherent to autofill, and is never logged | - | Verified clean |
| S7 | Session restore stores regular-tab URLs/titles in SharedPreferences in plain text. No secrets are stored there, and private tabs are excluded | Info | **Accepted, documented** |
| S8 | Release APK is signed with the **debug keystore** (Flutter template default: `signingConfig = signingConfigs.getByName("debug")`) | Medium | **Open** - blocks store release |
| S9 | `applicationId` is `com.example.tavrix_browser` | Medium | **Open** - must be a real, unique id before Play |

## 4. Manifest, Gradle and packaging

- Permissions declared by the build: `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `CAMERA`, `RECORD_AUDIO`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, plus `<uses-feature android:name="android.hardware.camera" android:required="false" />`. Nothing else.
- `compileSdk` is pinned to 37 (required by `permission_handler_android` 14.x); `minSdk`/`targetSdk` follow Flutter 3.47 defaults.
- Java desugaring is enabled for `flutter_local_notifications`; `flutter_inappwebview_android`'s ProGuard line is patched for current AGP; `--no-shrink` disables R8 minification by design.
- Adaptive launcher icon, round icon and notification glyph are installed from `assets/android_icons/res` and kept through resource shrinking by `res/raw/keep.xml`; verified inside the built APK (both `mipmap-anydpi-v26` XMLs and the `ic_stat_tavrix` / `ic_launcher_round` resource names are present).
- Release signing: APK Signature Scheme v2 block present, signed with the debug key (see S8). No `key.properties`, no keystore in the repository (correct), no AAB step yet.

## 5. Gaps and risks that remain

1. **No device testing.** Gestures, live download progress, notification rendering, permission dialogs, incognito isolation, media playback, reader mode and offline pages are code-verified only.
2. **Per-site permission prompt (S3).** The dashboard can allow/block/ask per host, but the *first* request from a site is granted automatically after the OS grant. A real prompt needs a `BuildContext` inside the WebView callback; the structure is ready but the UI was out of scope for this audit.
3. **Release signing and application id (S8, S9)** must be set before any store upload.
4. **Background downloads** stop on force-stop / OEM kill. Records survive and resume, which is the honest behaviour documented in KNOWN_LIMITATIONS.md.
5. **Pull-to-refresh** is still not implemented; the reload button is the refresh path.
6. **Autofill** covers username/password only, not addresses or phone numbers.
7. **Biometric lock** for private tabs and the vault is not implemented; `USE_BIOMETRIC` was removed rather than left declared and unused.
8. **No crash reporting / analytics** and no performance profiling on low-end hardware; the 60 FPS target is unmeasured.
9. **`javascript:` navigations from a page** are still allowed (they are how some sites implement links); typing one in the address bar will execute it. Consider blocking it at the address bar only.

## 6. Automated test coverage (30 tests)

| File | Tests | Covers |
| --- | --- | --- |
| `test/url_utils_test.dart` | 9 | URL detection, https normalisation, search fallback, display form, host extraction |
| `test/search_engine_test.dart` | 3 | default engines, query encoding, JSON round trip |
| `test/app_settings_test.dart` | 7 | defaults, full JSON round trip of 26 fields, wrong-type tolerance, numeric strings, unknown engine fallback, custom engines |
| `test/tab_model_test.dart` | 3 | blank tab, JSON round trip, private flag never serialised |
| `test/database_service_test.dart` | 5 | real SQLite: bookmark CRUD, history ordering/search/range delete, download upsert + record clearing, site-permission uniqueness, closed-tab cap |
| `test/widget_test.dart` | 1 | address bar renders and submits |

Commands run for this report:

```
flutter analyze     -> No issues found!
flutter test        -> All tests passed! (30)
flutter build apk --release --no-shrink   -> success (CI)
```

## 7. Release readiness verdict

**Not store-ready, but installable and internally consistent.** The code compiles cleanly, the automated suite passes against the real schema, and the APK builds and installs as a signed debug APK with a proper adaptive icon.

Before a Play Store release: configure a real release keystore and application id, run the device test matrix in section 5.1 of FEATURE_CHECKLIST.md on at least one Android 10 and one Android 14 device, and decide on the per-site permission prompt (S3).

## 8. Addendum - v1.2.0

After the audit, three features that had settings but no implementation were added
(no other feature work):

1. **Search suggestions** - `SuggestionService` fetches the active engine's
   autocomplete (`suggestTemplate`), merges it with recent searches, bookmarks and
   history (local first, case-insensitive de-duplication, 8 rows max) and shows it
   under the address bar with a 250 ms debounce. Covered by
   `test/suggestion_service_test.dart`.
2. **Search history** - new `search_history` table, schema version 2 with an
   `onUpgrade` migration that keeps existing data. One row per query (repeat moves
   it to the top), capped at 200 rows, used by suggestions and clearable from the
   Privacy dashboard. Covered by `test/database_service_test.dart`.
3. **Automatic translation** - after a page loads, Tavrix reads the document
   language and offers translation in a snackbar when it differs from the target.
   It never navigates by itself, so no redirect loops.

Also changed: `applicationId` is now `com.tavrix_browser.kn` (namespace left at the
template value so `MainActivity` keeps resolving). Automated suite is now 38 tests,
`flutter analyze` clean.
