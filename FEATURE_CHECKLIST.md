# Feature implementation checklist

Status legend:
- **Done** - implemented and wired to real behaviour in this repository.
- **Partial** - implemented with a documented engine or platform limit.
- **Not available** - the Android System WebView does not expose it; the UI does
  not pretend otherwise.

| # | PRD module | Status | Notes |
| --- | --- | --- | --- |
| 1 | Home and speed dial | Done | Add/edit/delete/reorder shortcuts, top sites, recently closed, recent downloads |
| 2 | Address and search | Done | URL detection, search fallback, security icon, progress, swipe gestures, copy/paste-and-go, share |
| 3 | Browser engine | Done | Android System WebView via flutter_inappwebview, behind `BrowserEngine` |
| 4 | Web navigation | Done | Back/forward/reload/stop/home, error overlay with retry |
| 5 | Tab management | Done | Live tabs, overview grid/list, search, pin, groups, close all, recently closed, session restore |
| 6 | Gesture management | Partial | Address-bar swipe, swipe-to-close tabs, pinch zoom; pull-to-refresh and edge-swipe back are not wired (see limitations) |
| 7 | Bookmarks | Done | Folders, favourites, search, JSON export/import, duplicate detection |
| 8 | History | Done | Day grouping, search, range delete, clear all, private excluded |
| 9 | Downloads | Done | Streaming with real progress, pause/resume/cancel/retry, open/share, SQLite records |
| 10 | Notifications | Partial | Progress/complete/failed notifications with channels; notification action buttons (pause/resume) are in-app only |
| 11 | Private browsing | Done | Incognito WebView sessions, separate list, no history, optional wipe on background |
| 12 | Password manager | Done | Keystore-backed secure storage, generator, per-site logins, autofill by domain |
| 13 | Autofill | Partial | Fills username/password forms on the current site on request; general address/phone autofill is not implemented |
| 14 | Privacy and security | Done | HTTPS status, cookie/storage/history clearing, DNT, JS and cookie switches, pop-up blocking |
| 15 | Website permissions | Done | Per-host allow/block/ask, separate from the Android permission |
| 16 | Media playback | Partial | HTML5 audio/video, inline and full-screen, zoom; picture-in-picture and media-session lock-screen controls depend on the page |
| 17 | Reader mode | Done | Article extraction, font size, light/sepia/dark, share |
| 18 | Translation | Partial | Opens the page through Google Translate's web translator (a real provider, not a fake in-app switch) |
| 19 | Find in page | Done | Highlighting, match count, next/previous, no-result state |
| 20 | Sharing | Done | System share sheet for URL, title, files |
| 21 | Desktop mode | Done | Per-tab desktop user agent and reload |
| 22 | PWA support | Not available | Installation prompts are not exposed by the system WebView |
| 23 | Offline reading | Done | Saves page HTML, lists saved pages, opens them from local files |
| 24 | Browser customisation | Done | Theme, accent colour, toolbar position, compact layout, tab layout, font scaling |
| 25 | Settings | Done | All 23 sections present, every switch persists |
| 26 | Backup and restore | Partial | Bookmarks export/import as JSON, settings export; encrypted password backup is not implemented |
| 27 | Android system integration | Done | Contextual runtime permissions, intent queries, external intents, notification channels |
| 28 | Accessibility | Partial | Semantic labels on icon buttons, scalable typography, large touch targets; no dedicated screen-reader audit yet |
| 29 | Error handling | Done | Offline, DNS, HTTP error, download failure, invalid URL, permission denied states with recovery |
| 30 | Performance and diagnostics | Partial | Tab WebViews are kept alive and disposed with their widget; no on-device profiling has been run |

## Not implemented in this build

These are called out rather than faked:

- Print / save as PDF (no print API in the system WebView plugin used here).
- Chrome extensions.
- Web push from websites.
- PWA installation.
- Biometric app lock (the manifest declares `USE_BIOMETRIC`, but no biometric
  prompt is wired yet).
- Notification action buttons that control downloads directly (actions live in
  the in-app Downloads screen).
- Encrypted password export/import.
- Pull-to-refresh and edge-swipe back gestures.
