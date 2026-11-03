import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tab_model.dart';
import '../utils/url_utils.dart';

/// Chrome-style address bar: security icon, URL text, progress line, gestures.
class AddressBar extends StatefulWidget {
  const AddressBar({
    super.key,
    required this.tab,
    required this.onSubmit,
    required this.onShowPageInfo,
    required this.onSwipeNext,
    required this.onSwipePrevious,
    required this.onCopy,
    required this.onPasteAndGo,
    required this.onShare,
    required this.onToggleBookmark,
    required this.isBookmarked,
  });

  final TabModel? tab;
  final ValueChanged<String> onSubmit;
  final VoidCallback onShowPageInfo;
  final VoidCallback onSwipeNext;
  final VoidCallback onSwipePrevious;
  final VoidCallback onCopy;
  final ValueChanged<String> onPasteAndGo;
  final VoidCallback onShare;
  final VoidCallback onToggleBookmark;
  final bool isBookmarked;

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText);
    _focusNode.addListener(() {
      setState(() => _editing = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  String get _displayText {
    final tab = widget.tab;
    if (tab == null) return '';
    if (tab.url.isEmpty) return '';
    return UrlUtils.displayUrl(tab.url);
  }

  @override
  void didUpdateWidget(covariant AddressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _controller.text != _displayText) {
      _controller.text = _displayText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    widget.onSubmit(text);
  }

  void _showContextMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onCopy();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_go_rounded),
              title: const Text('Paste and go'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text?.trim() ?? '';
                if (text.isNotEmpty) widget.onPasteAndGo(text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.select_all_rounded),
              title: const Text('Select all'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _focusNode.requestFocus();
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
            ),
            ListTile(
              leading: Icon(widget.isBookmarked
                  ? Icons.bookmark_remove_rounded
                  : Icons.bookmark_add_rounded),
              title:
                  Text(widget.isBookmarked ? 'Remove bookmark' : 'Add bookmark'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onToggleBookmark();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Page information'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onShowPageInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tab = widget.tab;
    final isSecure = tab?.isSecure ?? true;
    final isLoading = tab?.isLoading ?? false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: GestureDetector(
            onLongPress: _showContextMenu,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -200) {
                widget.onSwipeNext();
              } else if (velocity > 200) {
                widget.onSwipePrevious();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Connection information',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isSecure ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 18,
                      color: isSecure
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
                    ),
                    onPressed: widget.onShowPageInfo,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        hintText: 'Search or type URL',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _editing
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => _controller.clear(),
                              )
                            : null,
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  IconButton(
                    tooltip:
                        widget.isBookmarked ? 'Remove bookmark' : 'Bookmark',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      widget.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                    ),
                    onPressed: widget.onToggleBookmark,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: (tab?.progress ?? 0) > 0 ? tab!.progress : null,
              minHeight: 2,
            ),
          )
        else
          const SizedBox(height: 2),
      ],
    );
  }
}
