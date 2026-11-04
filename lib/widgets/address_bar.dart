import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tab_model.dart';
import '../theme/tokens.dart';
import '../utils/url_utils.dart';

/// The address bar: the primary control of the browser. Compact pill, security
/// indicator, inline bookmark action and swipe gestures.
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
    this.onQueryChanged,
    this.onFocusChanged,
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

  /// Fired on every keystroke so the shell can show suggestions.
  final ValueChanged<String>? onQueryChanged;

  /// Fired when the field gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<AddressBar> createState() => AddressBarState();
}

class AddressBarState extends State<AddressBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText);
    _controller.addListener(() => widget.onQueryChanged?.call(_controller.text));
    _focusNode.addListener(() {
      setState(() => _editing = _focusNode.hasFocus);
      widget.onFocusChanged?.call(_focusNode.hasFocus);
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

  /// Used by the shell when the user taps a suggestion.
  void applySuggestion(String text) {
    _controller.text = text;
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
                  : Icons.bookmark_add_outlined),
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
    final scheme = Theme.of(context).colorScheme;
    final tab = widget.tab;
    final isSecure = tab?.isSecure ?? true;
    final isLoading = tab?.isLoading ?? false;
    final hasUrl = (tab?.url ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TvSpace.lg,
        TvSpace.sm,
        TvSpace.lg,
        TvSpace.xs,
      ),
      child: Column(
        children: [
          GestureDetector(
            onLongPress: _showContextMenu,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -200) {
                widget.onSwipeNext();
              } else if (velocity > 200) {
                widget.onSwipePrevious();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 46,
              decoration: BoxDecoration(
                color: _editing ? scheme.surfaceContainerHigh : scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(TvRadius.pill),
                border: Border.all(
                  color: _editing
                      ? scheme.primary.withValues(alpha: 0.55)
                      : scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: TvSpace.md),
                  GestureDetector(
                    onTap: widget.onShowPageInfo,
                    child: Icon(
                      hasUrl
                          ? (isSecure
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded)
                          : Icons.search_rounded,
                      size: 16,
                      color: hasUrl && !isSecure
                          ? TvColors.warning
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: TvSpace.sm),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      cursorColor: scheme.primary,
                      cursorWidth: 1.6,
                      style: TvText.body.copyWith(fontSize: 14.5),
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        hintText: 'Search or type URL',
                        hintStyle: TvText.body.copyWith(
                          fontSize: 14.5,
                          color: scheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: _editing && _controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _controller.clear(),
                                child: Icon(
                                  Icons.cancel_rounded,
                                  size: 17,
                                  color: scheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onToggleBookmark,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TvSpace.sm,
                        vertical: TvSpace.sm,
                      ),
                      child: Icon(
                        widget.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 19,
                        color: widget.isBookmarked
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: TvSpace.xs),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 2,
            child: isLoading
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(TvRadius.pill),
                    child: LinearProgressIndicator(
                      value: (tab?.progress ?? 0) > 0 ? tab!.progress : null,
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
