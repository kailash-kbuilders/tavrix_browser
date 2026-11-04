import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/models/download_item.dart';
import 'package:tavrix_browser/utils/download_classifier.dart';

DownloadItem item({String filename = 'file', String? mimeType}) => DownloadItem(
      id: 'x',
      url: 'https://example.com/$filename',
      filename: filename,
      mimeType: mimeType,
      createdAt: 0,
    );

void main() {
  group('classifyDownload', () {
    test('uses the MIME type when it is present', () {
      expect(classifyDownload(item(filename: 'a.bin', mimeType: 'video/mp4')),
          DownloadCategory.videos);
      expect(classifyDownload(item(filename: 'a.bin', mimeType: 'audio/mpeg')),
          DownloadCategory.audio);
      expect(classifyDownload(item(filename: 'a.bin', mimeType: 'image/png')),
          DownloadCategory.images);
      expect(
          classifyDownload(
              item(filename: 'a.bin', mimeType: 'application/pdf')),
          DownloadCategory.documents);
      expect(
          classifyDownload(
              item(filename: 'a.bin', mimeType: 'application/zip')),
          DownloadCategory.files);
    });

    test('falls back to the extension', () {
      expect(classifyDownload(item(filename: 'movie.mkv')),
          DownloadCategory.videos);
      expect(classifyDownload(item(filename: 'song.mp3')),
          DownloadCategory.audio);
      expect(classifyDownload(item(filename: 'photo.jpeg')),
          DownloadCategory.images);
      expect(classifyDownload(item(filename: 'report.docx')),
          DownloadCategory.documents);
      expect(classifyDownload(item(filename: 'app.apk')),
          DownloadCategory.files);
    });

    test('unknown files land in other', () {
      expect(classifyDownload(item(filename: 'mystery')), DownloadCategory.other);
      expect(classifyDownload(item(filename: 'data.xyz')), DownloadCategory.other);
    });

    test('every category has a label', () {
      for (final category in DownloadCategory.values) {
        expect(downloadCategoryLabel(category), isNotEmpty);
      }
    });
  });
}
