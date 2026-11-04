/// Where a suggestion came from. The address bar shows a different icon per
/// kind so the list is honest about what it is offering.
enum SuggestionKind { search, history, bookmark, frequent, url }

/// One row in the address-bar suggestion panel.
class SuggestionItem {
  const SuggestionItem({
    required this.kind,
    required this.title,
    this.url,
    this.query,
  });

  final SuggestionKind kind;

  /// Page title for history/bookmarks, the query text for searches.
  final String title;

  /// Target URL when the suggestion points at a page.
  final String? url;

  /// Search text when the suggestion should be searched instead.
  final String? query;

  String get displayUrl => url ?? '';

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'title': title,
        'url': url,
        'query': query,
      };
}
