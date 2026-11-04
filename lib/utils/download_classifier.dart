import '../models/download_item.dart';

/// File category used by the download manager filters.
enum DownloadCategory { all, documents, videos, audio, images, files, other }

/// Classifies a download from its real MIME type first, then its extension.
/// No guessing from the URL and no fake categories.
DownloadCategory classifyDownload(DownloadItem item) {
  final mime = (item.mimeType ?? '').toLowerCase();
  final name = item.filename.toLowerCase();
  bool ends(List<String> extensions) =>
      extensions.any((extension) => name.endsWith(extension));

  if (mime.startsWith('video/') ||
      ends(const ['.mp4', '.mkv', '.webm', '.mov', '.avi', '.m4v'])) {
    return DownloadCategory.videos;
  }
  if (mime.startsWith('audio/') ||
      ends(const ['.mp3', '.m4a', '.wav', '.aac', '.ogg', '.flac'])) {
    return DownloadCategory.audio;
  }
  if (mime.startsWith('image/') ||
      ends(const ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'])) {
    return DownloadCategory.images;
  }
  if (mime.contains('pdf') ||
      mime.contains('word') ||
      mime.contains('excel') ||
      mime.contains('spreadsheet') ||
      mime.contains('powerpoint') ||
      mime.contains('presentation') ||
      mime.contains('text') ||
      mime.contains('csv') ||
      ends(const [
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.ppt',
        '.pptx',
        '.txt',
        '.csv',
        '.md',
      ])) {
    return DownloadCategory.documents;
  }
  if (mime.contains('zip') ||
      mime.contains('rar') ||
      mime.contains('7z') ||
      mime.contains('octet-stream') ||
      ends(const ['.zip', '.rar', '.7z', '.apk', '.tar', '.gz'])) {
    return DownloadCategory.files;
  }
  return DownloadCategory.other;
}

/// Short human label for a category chip.
String downloadCategoryLabel(DownloadCategory category) {
  switch (category) {
    case DownloadCategory.all:
      return 'All';
    case DownloadCategory.documents:
      return 'Documents';
    case DownloadCategory.videos:
      return 'Videos';
    case DownloadCategory.audio:
      return 'Audio';
    case DownloadCategory.images:
      return 'Images';
    case DownloadCategory.files:
      return 'Files';
    case DownloadCategory.other:
      return 'Other';
  }
}
