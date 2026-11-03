import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/models/download_item.dart';

void main() {
  test('progress is computed from bytes', () {
    final item = DownloadItem(
      id: 'a',
      url: 'https://example.com/file.zip',
      filename: 'file.zip',
      totalBytes: 200,
      receivedBytes: 50,
      createdAt: 0,
    );
    expect(item.progress, closeTo(0.25, 0.0001));
  });

  test('map round trip keeps status', () {
    final item = DownloadItem(
      id: 'a',
      url: 'https://example.com/file.zip',
      filename: 'file.zip',
      status: DownloadStatus.paused,
      receivedBytes: 10,
      totalBytes: 100,
      createdAt: 123,
    );
    final restored = DownloadItem.fromMap(item.toMap());
    expect(restored.status, DownloadStatus.paused);
    expect(restored.filename, 'file.zip');
    expect(restored.createdAt, 123);
  });

  test('unknown status falls back to queued', () {
    final restored = DownloadItem.fromMap({
      'id': 'b',
      'url': 'u',
      'filename': 'f',
      'status': 'nonsense',
      'createdAt': 0,
    });
    expect(restored.status, DownloadStatus.queued);
  });
}
