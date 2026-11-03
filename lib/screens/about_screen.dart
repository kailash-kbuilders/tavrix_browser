import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// About Tavrix: identity, engine notes and legal framing.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About Tavrix')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              'T',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(TavrixConstants.appName,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(TavrixConstants.tagline,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          const Text('Version ${TavrixConstants.version}'),
          const SizedBox(height: 20),
          const Text(
            'Tavrix Browser renders pages with the Android System WebView '
            '(Chromium). Features that the system WebView does not expose - '
            'such as Chrome extensions, native printing, and web push from '
            'sites - are not available, and Tavrix does not pretend they are. '
            'See KNOWN_LIMITATIONS.md in the repository for the full list.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Private browsing keeps history and cookies out of Tavrix storage '
            'for that session. It does not hide your activity from websites, '
            'your internet provider or your network administrator.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Tavrix never bypasses TLS certificate validation, never stores '
            'passwords in plaintext, and never requests permissions it does '
            'not need at that moment.',
          ),
        ],
      ),
    );
  }
}
