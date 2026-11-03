/// A recently closed tab, restorable from the tab overview.
class ClosedTab {
  const ClosedTab({
    this.id,
    required this.title,
    required this.url,
    required this.closedAt,
  });

  final int? id;
  final String title;
  final String url;
  final int closedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'closedAt': closedAt,
      };

  factory ClosedTab.fromMap(Map<String, Object?> map) => ClosedTab(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        url: map['url'] as String? ?? '',
        closedAt: map['closedAt'] as int? ?? 0,
      );
}
