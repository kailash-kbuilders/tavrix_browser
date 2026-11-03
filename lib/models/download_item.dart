enum DownloadStatus { queued, running, paused, completed, failed, cancelled }

/// A real download record, kept in SQLite so it survives process death.
class DownloadItem {
  DownloadItem({
    required this.id,
    required this.url,
    required this.filename,
    this.path,
    this.mimeType,
    this.totalBytes = 0,
    this.receivedBytes = 0,
    this.status = DownloadStatus.queued,
    this.error,
    required this.createdAt,
    this.userAgent,
  });

  final String id;
  final String url;
  final String filename;
  String? path;
  final String? mimeType;
  final String? userAgent;
  int totalBytes;
  int receivedBytes;
  DownloadStatus status;
  String? error;
  final int createdAt;

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  String get statusLabel {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.running:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  DownloadItem copyWith({
    String? path,
    int? totalBytes,
    int? receivedBytes,
    DownloadStatus? status,
    String? error,
  }) =>
      DownloadItem(
        id: id,
        url: url,
        filename: filename,
        path: path ?? this.path,
        mimeType: mimeType,
        userAgent: userAgent,
        totalBytes: totalBytes ?? this.totalBytes,
        receivedBytes: receivedBytes ?? this.receivedBytes,
        status: status ?? this.status,
        error: error ?? this.error,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'url': url,
        'filename': filename,
        'path': path,
        'mimeType': mimeType,
        'userAgent': userAgent,
        'totalBytes': totalBytes,
        'receivedBytes': receivedBytes,
        'status': status.name,
        'error': error,
        'createdAt': createdAt,
      };

  factory DownloadItem.fromMap(Map<String, Object?> map) => DownloadItem(
        id: map['id'] as String? ?? '',
        url: map['url'] as String? ?? '',
        filename: map['filename'] as String? ?? 'download',
        path: map['path'] as String?,
        mimeType: map['mimeType'] as String?,
        userAgent: map['userAgent'] as String?,
        totalBytes: map['totalBytes'] as int? ?? 0,
        receivedBytes: map['receivedBytes'] as int? ?? 0,
        status: DownloadStatus.values.firstWhere(
          (value) => value.name == (map['status'] as String? ?? 'queued'),
          orElse: () => DownloadStatus.queued,
        ),
        error: map['error'] as String?,
        createdAt: map['createdAt'] as int? ?? 0,
      );
}
