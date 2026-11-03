import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Distraction-free reader with font size and reading themes.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.title,
    required this.byline,
    required this.text,
    required this.url,
  });

  final String title;
  final String byline;
  final String text;
  final String url;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _fontSize = 17;
  String _readingTheme = 'light';

  (Color, Color) get _colors {
    switch (_readingTheme) {
      case 'dark':
        return (const Color(0xFF15161A), const Color(0xFFE6E6E6));
      case 'sepia':
        return (const Color(0xFFF6ECD9), const Color(0xFF3B3222));
      default:
        return (Colors.white, const Color(0xFF1A1A1A));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: foreground,
        title: const Text('Reader mode'),
        actions: [
          IconButton(
            tooltip: 'Smaller text',
            icon: const Icon(Icons.text_decrease_rounded),
            onPressed: () => setState(
                () => _fontSize = (_fontSize - 1).clamp(13, 28)),
          ),
          IconButton(
            tooltip: 'Larger text',
            icon: const Icon(Icons.text_increase_rounded),
            onPressed: () => setState(
                () => _fontSize = (_fontSize + 1).clamp(13, 28)),
          ),
          PopupMenuButton<String>(
            tooltip: 'Reading theme',
            icon: Icon(Icons.palette_outlined, color: foreground),
            onSelected: (value) => setState(() => _readingTheme = value),
            itemBuilder: (menuContext) => const [
              PopupMenuItem(value: 'light', child: Text('Light')),
              PopupMenuItem(value: 'sepia', child: Text('Sepia')),
              PopupMenuItem(value: 'dark', child: Text('Dark')),
            ],
          ),
          IconButton(
            tooltip: 'Share article',
            icon: Icon(Icons.share_rounded, color: foreground),
            onPressed: () => Share.share(
              '${widget.title}\n${widget.url}',
              subject: widget.title,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 48),
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: foreground,
              fontSize: _fontSize + 8,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (widget.byline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.byline,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.7),
                fontSize: _fontSize - 2,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            widget.text,
            style: TextStyle(
              color: foreground,
              fontSize: _fontSize,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
