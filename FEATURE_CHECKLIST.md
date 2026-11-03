# Feature implementation checklist

Status legend (from the release QA audit, see RELEASE_QA_REPORT.md):

- **Verified** - implementation reviewed *and* covered by an automated test.
- **Device test needed** - implemented, code-reviewed, but cannot be exercised without a phone/emulator.
- **Partial** - works, with a documented limit.
- **Not implemented** - missing.
- **Engine limit** - the Android System WebView cannot do it; no fake UI is shown.

| # | PRD module | Status | Notes |
| --- | --- | --- | --- |
| 1 | Home and speed dial | Device test needed | Add/edit/delete/reorder shortcuts, top sites, recently closed, recent downloads. Shortcut ordering is menu-driven, not drag. |
| 2 | Address and search | Verified (logic) / Device test needed (UI) | URL detection, https normalisation and search fallback unit-tested; address bar submit covered by a widget test. Swipe-to-switch respects its setting. |
| 3 | Browser engine | Device test needed | Android System WebView behind `BrowserEngine`; live settings now pushed to open tabs. |
| 4 | Web navigation | Device test needed | Back/forward/reload/stop/home, error overlay with retry. |
| 5 | Tab management | Partial | Live tabs, grid/list overview, search, pin, groups, close all, recently closed (capped at 50, tested), session restore. No drag-to-reorder and no duplicate-tab detection. |
| 6 | Gestures | Partial | Address-bar swipe (setting-gated), edge-swipe back/forward, swipe-to-close tabs, pinch zoom. Pull-to-refresh is **not** implemented. |
| 7 | Bookmarks | Verified (storage) / Device test needed (UI) | CRUD, folders, favourites, search, duplicate check - real SQLite tests. Export/import is JSON text (paste/share), no file picker. |
| 8 | History | Verified (storage) / Device test needed (UI) | Day grouping, search, single delete, range delete ("last hour / 24 hours / 7 days / all"), domain list (SQL bug fixed). Private tabs excluded. |
| 9 | Downloads | Partial | Streaming with real progress, pause (keeps partial file), resume via HTTP Range, cancel, retry, duplicate-safe filenames, open/share; records in SQLite (tested). Interrupted records are restored as paused. No concurrency limit. |
| 10 | Notifications | Partial | Channels, progress/complete/failure notifications, contextual permission request on the first download. Action buttons (pause/resume) live in the app, not in the notification. |
| 11 | Private browsing | Device test needed | Incognito WebView sessions, separate tab list, no history writes, wipe on background when enabled. Isolation itself needs a device to confirm. |
| 12 | Password manager | Partial | Keystore-backed vault, generator, per-site logins, copy/edit/delete. No biometric lock. |
| 13 | Autofill | Partial | Username/password only, triggered from the menu. No addresses or phone numbers. |
| 14 | Privacy and security | Verified (settings) / Device test needed (engine) | HTTPS status, cookie clearing, local-storage clearing, history clearing, DNT signal, JavaScript and cookie switches (now live). HTTP cache is cleared by the OS with app data. |
| 15 | Website permissions | Partial | Per-host allow/block/ask stored in SQLite (tested) and enforced for camera/microphone/location. The first request from a site is granted automatically after the OS grant - no in-app prompt yet. |
| 16 | Media playback | Device test needed | HTML5 audio/video, inline playback, full screen, zoom. No picture-in-picture or lock-screen media session. |
| 17 | Reader mode | Device test needed | Heuristic article extraction, font size, light/sepia/dark, share. Canvas-heavy pages yield "no readable article". |
| 18 | Translation | Partial | Opens the page through Google Translate's web translator - a real provider, not an in-app overlay. |
| 19 | Find in page | Device test needed | Highlighting via injected JS, match count, next/previous, no-result state. |
| 20 | Sharing | Device test needed | System share sheet for URL, title and downloaded files. |
| 21 | Desktop mode | Verified (wiring) / Device test needed | Per-tab desktop user agent with reload, plus a "desktop by default" preference that now actually applies to new tabs. |
| 22 | PWA support | Engine limit | The system WebView exposes no install prompt. |
| 23 | Offline reading | Device test needed | Saves page HTML, lists saved pages, opens them from local files. |
| 24 | Browser customisation | Verified (settings) / Device test needed (visuals) | Theme, accent colour, toolbar position, compact layout, tab layout, font scaling, animations toggle (now wired). |
| 25 | Settings | Verified | 26 preferences persist (JSON round trip tested). Every switch either works or was removed - `blockPopups` and `notifyWebsite` were removed because the engine cannot honour them. |
| 26 | Backup and restore | Partial | Bookmarks export/import as JSON, settings export. No encrypted password backup. |
| 27 | Android system integration | Device test needed | Contextual runtime permissions, intent queries, external-scheme allowlist, notification channels, `roundIcon`. |
| 28 | Accessibility | Partial | Semantic labels on icon buttons, scalable typography, large touch targets. No screen-reader audit performed. |
| 29 | Error handling | Device test needed | Offline, DNS, HTTP error, download failure, invalid URL and permission-denied states with recovery actions. |
| 30 | Performance and diagnostics | Partial | Tabs are kept alive and disposed with their widget; no profiling on real hardware, no crash reporting. |

## Not implemented

- Print / save as PDF (no print API in this plugin).
- Chrome extensions, web push from sites, PWA installation (engine limits).
- Notification action buttons that control downloads.
- Pull-to-refresh.
- Biometric app lock.
- Encrypted password export/import.
- Drag-to-reorder tabs and duplicate-tab detection.
- Crash reporting and performance profiling.

## Device test matrix to run before release

1. Fresh install -> home screen renders, no permission dialogs at launch.
2. Load 3 sites in 3 tabs, switch between them: no reloads, address bar and progress correct.
3. Kill the app from recents, reopen: regular tabs restored, private tabs gone.
4. Download a 50 MB file: live notification progress, pause, resume, complete, open, share; then repeat with notifications denied (must still download).
5. Force-stop during a download, reopen: record shows "Interrupted", Resume completes it.
6. Camera/microphone/location on a real site: OS dialog, then per-site decision in the Permissions dashboard, then revoke and confirm access is refused.
7. Private tab: browse, check History is empty, background the app, confirm the private tab is gone.
8. Settings: toggle JavaScript off and reload a script-heavy page (must break), toggle back on (must work without closing the tab).
9. Rotate, use split screen, and lock the screen during video playback.
10. Android 10 and Android 14 both, plus one low-RAM device.
