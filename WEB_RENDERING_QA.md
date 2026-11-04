# Web rendering QA - mobile layout and desktop mode

Date: 2026-11-04
Reference: two screenshots of `https://clcbarmer.in` on the same phone,
10:31, 85% battery - one in Tavrix (v1.3.1), one in Google Chrome Android.

## 1. What the screenshots showed

| Observation | Tavrix (before) | Chrome | What it means |
| --- | --- | --- | --- |
| Hero heading | `सपने बड़े द` - one partial line, rest cut off | `सपने बड़े देखो, महेनत` / `उससे बड़` - two full lines | The heading was laid out for a **wider CSS viewport** than the phone: it did not need to wrap, so it overflowed and was clipped by the container |
| Glyph size | ~15-40% smaller than Chrome, same physical width | reference | The whole page was **scaled down**, not restyled |
| Header block height | ~40% taller than Chrome | reference | The page's `vw`/`%` based padding resolved against a wider layout width |
| Space above the page | ~36 dp of dead space between the address bar and the first painted pixel | page starts immediately under the toolbar | Tavrix reserved space under the address bar (bottom padding + progress line) |
| Buttons / images | Narrower, same page width | reference | Consistent with a zoomed-out page, not with different CSS |

Both screenshots have the same width, so this was not a device difference.

## 2. Root cause

The WebView was configured with:

```dart
useWideViewPort: true,
loadWithOverviewMode: true,
```

`loadWithOverviewMode` tells the Android WebView to **zoom out until the widest
content on the page fits the screen**. It does not care whether the page declares
`<meta name="viewport" content="width=device-width">`. A single element wider
than the viewport - on this site the scrolling marquee ticker
(`सैनिक स्कूल ... राष्ट्रीय मिलिट्री स्कूल`) is exactly that - is enough to make
the whole page render at, say, 80% scale:

- CSS viewport width becomes ~`412 / 0.8 = 515 px` instead of 412 px,
- text therefore looks smaller and stops wrapping where Chrome wraps it,
- `vw`-based padding grows, so the header block gets taller,
- anything with `overflow: hidden` clips (the hero heading).

Chrome on Android does **not** zoom out a viewport-aware page. That is the
rendering difference in the screenshots.

Secondary contributors, all fixed in the same pass:

- Mixed content was left at the WebView default (`NEVER_ALLOW`), which drops
  `http://` sub-resources (images, fonts) on an `https://` page. Chrome uses the
  compatibility upgrade path instead.
- Scrollbars were left visible (`verticalScrollBarEnabled` default `true`),
  which Chrome hides.
- The address bar reserved bottom padding plus a 2 dp progress line even when no
  page was loading, so the page never started flush under the bar.

## 3. The fix (mobile mode)

```dart
useWideViewPort: true,          // honour <meta viewport> - same as Chrome
loadWithOverviewMode: false,    // never shrink a viewport-aware page
initialScale: 0,                // let the page decide
textZoom: 100,                  // ignore system font scaling for pages
supportZoom: true,              // pinch to zoom still works
builtInZoomControls: false,     // no zoom buttons (Chrome has none)
displayZoomControls: false,
verticalScrollBarEnabled: false,
horizontalScrollBarEnabled: false,
domStorageEnabled: true,        // explicit, not default-dependent
databaseEnabled: true,
cacheEnabled: true,
mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
hardwareAcceleration: true,
```

And in the shell, the page now starts immediately under the address bar: the
progress line only occupies 2 dp while a page is actually loading.

## 4. Desktop mode

Before: the toggle recreated the whole WebView (losing scroll position and
history), and it sent a **Linux** Chrome user agent, which many sites treat as a
non-desktop client.

After:

| Item | Implementation |
| --- | --- |
| User agent | Windows Chrome 124 desktop string (what every browser sends for "Request desktop site") |
| Viewport | `useWideViewPort: true` + `loadWithOverviewMode: true` **in desktop mode only**, so a 980-1024 px desktop layout fits the phone screen |
| Application | Applied to the **live** WebView with `setSettings()` - the tab keeps its URL and back/forward history |
| Reload | One reload after the settings are applied, so the site serves its desktop layout |
| Isolation | Settings live on each `InAppWebView`, so desktop mode is **per tab**; other tabs are untouched. Verified by construction: `BrowserEngine.settingsFor()` is called per tab with `desktopMode: tab.isDesktopMode` |
| Persistence | `tab.isDesktopMode` stays set until the user turns it off; new tabs follow the global preference |
| Menu state | The menu row reads "Desktop site" or "Mobile site" from the tab's current state |

Sites that ignore the user agent (client-side width detection, `maxTouchPoints`,
`pointer: coarse` media queries) will still show a mobile layout. No browser can
force those; this is documented in KNOWN_LIMITATIONS.md.

## 5. Known remaining difference from Chrome

A browser with a bottom toolbar gives the page a **shorter viewport height** than
Chrome, which has no bottom toolbar. Sites that size sections with `vh` units
therefore compute slightly different heights in Tavrix. This is a layout
consequence of the toolbar position, not a rendering bug, and it is documented.

## 6. Verification status

Verified in this environment:

- `flutter analyze` - no issues.
- `flutter test` - all tests pass.
- Release APK builds and its manifest/dex/resources check out.

**NOT VERIFIED (no device or emulator available here):**

- Screenshot comparison of `clcbarmer.in` in Tavrix vs Chrome after this change.
- The other site classes the brief lists: responsive business site, news site,
  Google Search, YouTube, a desktop-only layout, sticky navigation plus floating
  WhatsApp widget.
- Desktop mode on real sites, and restoring mobile layout afterwards.
- Keyboard behaviour, redirects, full-screen video.

The site could not be fetched from the build sandbox either (outbound access is
restricted), so the analysis above is based on the two screenshots and on the
WebView configuration, not on the site's CSS.

## 7. Device checklist for this fix

1. Open `clcbarmer.in`: hero heading wraps over two lines like Chrome, no clipped
   text, no dead space above the page.
2. Same page: pinch to zoom in/out still works, no zoom buttons appear.
3. A news site with images: all images load (mixed-content compatibility).
4. `example.com` then `m.youtube.com`: layout and scrolling normal, no horizontal
   scrollbar.
5. Menu -> Desktop site on `clcbarmer.in`: desktop navigation appears, page
   reloads once, back/forward history is preserved.
6. Toggle back to Mobile site: mobile layout returns, still the same tab.
7. Open a second tab: it must stay in mobile mode (per-tab isolation).
