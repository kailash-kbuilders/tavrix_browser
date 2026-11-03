/// A home screen speed dial shortcut.
class ShortcutItem {
  const ShortcutItem({
    this.id,
    required this.title,
    required this.url,
    this.position = 0,
  });

  final int? id;
  final String title;
  final String url;
  final int position;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'position': position,
      };

  factory ShortcutItem.fromMap(Map<String, Object?> map) => ShortcutItem(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        url: map['url'] as String? ?? '',
        position: map['position'] as int? ?? 0,
      );
}
