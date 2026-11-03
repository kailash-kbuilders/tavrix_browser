/// A page saved for offline reading.
class OfflinePage {
  const OfflinePage({
    this.id,
    required this.title,
    required this.url,
    required this.filePath,
    required this.savedAt,
  });

  final int? id;
  final String title;
  final String url;
  final String filePath;
  final int savedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'filePath': filePath,
        'savedAt': savedAt,
      };

  factory OfflinePage.fromMap(Map<String, Object?> map) => OfflinePage(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        url: map['url'] as String? ?? '',
        filePath: map['filePath'] as String? ?? '',
        savedAt: map['savedAt'] as int? ?? 0,
      );
}
