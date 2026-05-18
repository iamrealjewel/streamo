enum DownloadStatus { queued, downloading, converting, completed, failed }

enum DownloadType { video, audio }

class DownloadItem {
  final String id;
  final String title;
  final String thumbnailUrl;
  final DownloadType type;
  final String quality;
  DownloadStatus status;
  double progress;
  String? filePath;
  String? errorMessage;

  DownloadItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.type,
    required this.quality,
    required this.status,
    this.progress = 0.0,
    this.filePath,
    this.errorMessage,
  });
}
