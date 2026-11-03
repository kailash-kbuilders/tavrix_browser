import 'package:flutter/material.dart';

/// Find-in-page toolbar with match counter and next/previous controls.
class FindInPageBar extends StatelessWidget {
  const FindInPageBar({
    super.key,
    required this.controller,
    required this.matches,
    required this.currentMatch,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  final TextEditingController controller;
  final int matches;
  final int currentMatch;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Find in page',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            matches == 0 ? 'No results' : '${currentMatch + 1}/$matches',
            style: theme.textTheme.labelMedium,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            onPressed: onPrevious,
            tooltip: 'Previous match',
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: onNext,
            tooltip: 'Next match',
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
