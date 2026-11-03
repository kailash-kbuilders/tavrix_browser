/// A single visited page.
class HistoryEntry {
  const HistoryEntry({
    this.id,
    required this.title,
    required this.url,
    required this.domain,
    required this.visitedAt,
  });

  final int? id;
  final String title;
  final String url;
  final String domain;
  final int visitedAt;

  DateTime get visitedDate => DateTime.fromMillisecondsSinceEpoch(visitedAt);

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'domain': domain,
        'visitedAt': visitedAt,
      };

  factory HistoryEntry.fromMap(Map<String, Object?> map) => HistoryEntry(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        url: map['url'] as String? ?? '',
        domain: map['domain'] as String? ?? '',
        visitedAt: map['visitedAt'] as int? ?? 0,
      );
}
