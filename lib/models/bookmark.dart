/// A saved bookmark. Folders are stored as a slash separated path so nested
/// folders work without a second table.
class Bookmark {
  const Bookmark({
    this.id,
    required this.title,
    required this.url,
    this.description,
    this.folder,
    this.position = 0,
    this.isFavorite = false,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String url;
  final String? description;
  final String? folder;
  final int position;
  final bool isFavorite;
  final int createdAt;

  Bookmark copyWith({
    int? id,
    String? title,
    String? url,
    String? description,
    String? folder,
    int? position,
    bool? isFavorite,
  }) =>
      Bookmark(
        id: id ?? this.id,
        title: title ?? this.title,
        url: url ?? this.url,
        description: description ?? this.description,
        folder: folder ?? this.folder,
        position: position ?? this.position,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'description': description,
        'folder': folder,
        'position': position,
        'isFavorite': isFavorite ? 1 : 0,
        'createdAt': createdAt,
      };

  factory Bookmark.fromMap(Map<String, Object?> map) => Bookmark(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        url: map['url'] as String? ?? '',
        description: map['description'] as String?,
        folder: map['folder'] as String?,
        position: map['position'] as int? ?? 0,
        isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
        createdAt: map['createdAt'] as int? ?? 0,
      );
}
