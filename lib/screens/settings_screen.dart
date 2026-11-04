import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../utils/constants.dart';
import '../widgets/ui/tv_widgets.dart';
import 'about_screen.dart';
import 'offline_pages_screen.dart';
import 'password_manager_screen.dart';
import 'permissions_screen.dart';
import 'privacy_screen.dart';
import 'search_engines_screen.dart';

/// Every setting here writes through SettingsProvider, so all of them persist.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final app = settings.settings;
    final theme = Theme.of(context);

    Widget header(String text) => TvSectionHeader(title: text);

    Widget switchTile(
      String title,
      String subtitle,
      bool value,
      Future<void> Function(bool) onChanged,
    ) {
      return SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (next) => onChanged(next),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header('General'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(app.themeMode.toUpperCase()),
            trailing: DropdownButton<String>(
              value: app.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
              onChanged: (value) {
                if (value != null) settings.setThemeMode(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Accent colour'),
            subtitle: const Text('Changes the whole app'),
            trailing: Wrap(
              spacing: 6,
              children: [
                for (final color in const [
                  0xFF3B6FF6,
                  0xFF12A594,
                  0xFFE05252,
                  0xFF8E5BF0,
                  0xFFEF8A17,
                ])
                  GestureDetector(
                    onTap: () => settings.setAccentColor(color),
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: app.accentColor == color
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vertical_align_bottom_rounded),
            title: const Text('Toolbar position'),
            trailing: DropdownButton<String>(
              value: app.toolbarPosition,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'bottom', child: Text('Bottom')),
                DropdownMenuItem(value: 'top', child: Text('Top')),
              ],
              onChanged: (value) {
                if (value != null) settings.setToolbarPosition(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: const Text('Font scaling'),
            subtitle: Text('${(app.fontScale * 100).round()}%'),
            trailing: SizedBox(
              width: 140,
              child: Slider(
                value: app.fontScale,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                onChanged: settings.setFontScale,
              ),
            ),
          ),
          switchTile('Compact layout', 'More shortcuts per row on home',
              app.compactLayout, settings.setCompactLayout),
          switchTile('Animations', 'Smooth transitions and motion',
              app.animations, settings.setAnimations),
          switchTile('Haptic feedback', 'Vibrate on gestures and actions',
              app.haptics, settings.setHaptics),

          header('Search'),
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text('Search engine'),
            subtitle: Text(app.searchEngine.name),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (context) => const SearchEnginesScreen())),
          ),
          switchTile('Search suggestions',
              'Autocomplete from your history, bookmarks and the search engine',
              app.searchSuggestions, settings.setSearchSuggestions),
          switchTile('Save search history',
              'Remember queries to suggest them again',
              app.savedSearchHistory, settings.setSavedSearchHistory),

          header('Homepage'),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Custom homepage URL'),
            subtitle: Text(
              app.homepageUrl.isEmpty
                  ? 'Tavrix home screen'
                  : app.homepageUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              final controller =
                  TextEditingController(text: app.homepageUrl);
              final result = await showDialog<String>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Homepage URL'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext)
                          .pop(controller.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (result != null) await settings.setHomepage(result);
            },
          ),

          header('Tabs'),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text('Tab overview layout'),
            trailing: DropdownButton<String>(
              value: app.tabLayout,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'grid', child: Text('Grid')),
                DropdownMenuItem(value: 'list', child: Text('List')),
              ],
              onChanged: (value) {
                if (value != null) settings.setTabLayout(value);
              },
            ),
          ),

          header('Gestures'),
          switchTile('Swipe address bar to switch tabs',
              'Left or right swipe on the address bar',
              app.swipeAddressBarSwitchesTabs,
              settings.setSwipeAddressBarSwitchesTabs),
          switchTile('Edge swipe navigation',
              'Swipe from screen edge to go back',
              app.edgeSwipeNavigation, settings.setEdgeSwipeNavigation),

          header('Downloads'),
          const ListTile(
            leading: Icon(Icons.folder_outlined),
            title: Text('Download location'),
            subtitle: Text('Android/data/<package>/files/Tavrix Downloads'),
          ),

          header('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Allow notifications'),
            subtitle: const Text('Required for download notifications'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final granted = await PermissionService.requestNotifications();
              if (!granted) {
                await PermissionService.openSystemSettings();
              }
            },
          ),
          switchTile('Download progress', 'Live progress notifications',
              app.notifyProgress, settings.setNotifyProgress),
          switchTile('Download complete', 'Shown when a file finishes',
              app.notifyComplete, settings.setNotifyComplete),
          switchTile('Download failed', 'Shown when a download fails',
              app.notifyFailed, settings.setNotifyFailed),
          const ListTile(
            leading: Icon(Icons.tune_rounded),
            title: Text('Notification channels'),
            subtitle: Text('Sound, vibration and importance'),
            onTap: PermissionService.openSystemSettings,
          ),

          header('Privacy and security'),
          switchTile('JavaScript', 'Turn off to block scripts on every site',
              app.javaScriptEnabled, settings.setJavaScriptEnabled),
          switchTile('Cookies', 'Allow sites to store cookies',
              app.cookiesEnabled, settings.setCookiesEnabled),
          switchTile('Do Not Track', 'Ask sites not to track you',
              app.doNotTrack, settings.setDoNotTrack),
          switchTile('Clear private tabs on exit',
              'Wipe private tabs when the app goes to background',
              app.automaticPrivateCleanup,
              settings.setAutomaticPrivateCleanup),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy dashboard'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (context) => const PrivacyScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Permissions'),
            subtitle: const Text('Camera, microphone, location and sites'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (context) => const PermissionsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: const Text('Password manager'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (context) => const PasswordManagerScreen())),
          ),
          switchTile('Desktop mode by default',
              'Load pages with a desktop user agent', app.desktopMode,
              settings.setDesktopMode),

          header('Media and language'),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: const Text('Translation language'),
            subtitle: Text(app.translationLanguage.toUpperCase()),
            trailing: DropdownButton<String>(
              value: app.translationLanguage,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                DropdownMenuItem(value: 'te', child: Text('Telugu')),
                DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                DropdownMenuItem(value: 'kn', child: Text('Kannada')),
                DropdownMenuItem(value: 'ml', child: Text('Malayalam')),
                DropdownMenuItem(value: 'pa', child: Text('Punjabi')),
                DropdownMenuItem(value: 'es', child: Text('Spanish')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
                DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              ],
              onChanged: (value) {
                if (value != null) settings.setTranslationLanguage(value);
              },
            ),
          ),
          switchTile('Translate pages automatically',
              'Offers translation when a page is in another language',
              app.automaticTranslation, settings.setAutomaticTranslation),

          header('Storage and backup'),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Offline pages'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (context) => const OfflinePagesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Export bookmarks'),
            subtitle: const Text('Shares a JSON file you can re-import'),
            onTap: () => context.read<BookmarkProvider>().exportBookmarks(),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_rounded),
            title: const Text('Export settings'),
            subtitle: const Text('Shares your preferences as JSON'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final raw = prefs.getString(TavrixConstants.settingsKey) ?? '{}';
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(raw)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Reset all settings'),
            subtitle: const Text('Restores every preference to its default'),
            onTap: settings.resetAll,
          ),

          header('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Tavrix'),
            subtitle: const Text(
                '${TavrixConstants.appName} ${TavrixConstants.version}'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (context) => const AboutScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification service status'),
            subtitle: Text(
              context.read<NotificationService>().isReady
                  ? 'Ready'
                  : 'Channels ready on Android',
            ),
          ),
        ],
      ),
    );
  }
}
