import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/download_item.dart';
import '../models/video_info.dart';
import '../models/queued_video.dart';
import '../services/youtube_service.dart';
import '../services/download_service.dart';

class DownloadProvider extends ChangeNotifier {
  final List<DownloadItem> _downloads = [];
  final List<QueuedVideo> _searchQueue = [];
  
  VideoInfo? _currentVideoInfo;
  bool _isFetchingInfo = false;
  String? _fetchError;

  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<QueuedVideo> get searchQueue => _searchQueue;
  
  VideoInfo? get currentVideoInfo => _currentVideoInfo;
  bool get isFetchingInfo => _isFetchingInfo;
  String? get fetchError => _fetchError;

  // Active downloads (queued/downloading/converting)
  List<DownloadItem> get activeDownloads =>
      _downloads.where((d) => 
        d.status == DownloadStatus.queued ||
        d.status == DownloadStatus.downloading || 
        d.status == DownloadStatus.converting
      ).toList();

  // Completed downloads
  List<DownloadItem> get completedDownloads =>
      _downloads.where((d) => d.status == DownloadStatus.completed).toList();

  // ─── Search Queue State Management ─────────────────────────────────────────

  void addToQueue(QueuedVideo video) {
    if (!_searchQueue.any((v) => v.id == video.id)) {
      _searchQueue.add(video);
      notifyListeners();
    }
  }

  void removeFromQueue(String id) {
    _searchQueue.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  void toggleQueueSelection(String id) {
    final idx = _searchQueue.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _searchQueue[idx].isSelected = !_searchQueue[idx].isSelected;
      notifyListeners();
    }
  }

  void toggleAllQueueSelection(bool selected) {
    for (var v in _searchQueue) {
      v.isSelected = selected;
    }
    notifyListeners();
  }

  void clearQueue() {
    _searchQueue.clear();
    notifyListeners();
  }

  // ─── Single Item Downloader ────────────────────────────────────────────────

  Future<void> fetchVideoInfo(String url) async {
    _isFetchingInfo = true;
    _fetchError = null;
    _currentVideoInfo = null;
    notifyListeners();

    try {
      _currentVideoInfo = await YoutubeService.getVideoInfo(url);
    } catch (e) {
      _fetchError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isFetchingInfo = false;
      notifyListeners();
    }
  }

  void clearVideoInfo() {
    _currentVideoInfo = null;
    _fetchError = null;
    notifyListeners();
  }

  Future<void> startVideoDownload({
    required VideoInfo videoInfo,
    required VideoFormat format,
  }) async {
    final item = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: videoInfo.title,
      thumbnailUrl: videoInfo.thumbnailUrl,
      type: DownloadType.video,
      quality: format.qualityLabel,
      status: DownloadStatus.downloading,
    );

    _downloads.insert(0, item);
    notifyListeners();

    try {
      final savePath = await _getSavePath(
        '${_sanitizeFilename(videoInfo.title)}_${format.qualityLabel}.mp4',
      );

      item.filePath = savePath;

      await DownloadService.downloadVideo(
        videoInfo: videoInfo,
        format: format,
        savePath: savePath,
        onProgress: (progress) {
          item.progress = progress;
          notifyListeners();
        },
      );

      item.status = DownloadStatus.completed;
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> startAudioDownload({
    required VideoInfo videoInfo,
    required AudioBitrate bitrate,
  }) async {
    final item = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: videoInfo.title,
      thumbnailUrl: videoInfo.thumbnailUrl,
      type: DownloadType.audio,
      quality: '${bitrate.kbps}kbps',
      status: DownloadStatus.downloading,
    );

    _downloads.insert(0, item);
    notifyListeners();

    try {
      final tempPath = await _getSavePath(
        '${_sanitizeFilename(videoInfo.title)}_temp.webm',
        temp: true,
      );
      final savePath = await _getSavePath(
        '${_sanitizeFilename(videoInfo.title)}_${bitrate.kbps}kbps.mp3',
      );

      item.filePath = savePath;

      // Step 1: Download audio stream
      await DownloadService.downloadAudioStream(
        videoInfo: videoInfo,
        savePath: tempPath,
        onProgress: (progress) {
          item.progress = progress * 0.7; // 70% for download
          notifyListeners();
        },
      );

      // Step 2: Convert to MP3
      item.status = DownloadStatus.converting;
      item.progress = 0.7;
      notifyListeners();

      await DownloadService.convertToMp3(
        inputPath: tempPath,
        outputPath: savePath,
        bitrateKbps: bitrate.kbps,
        onProgress: (progress) {
          item.progress = 0.7 + (progress * 0.3); // remaining 30%
          notifyListeners();
        },
      );

      // Cleanup temp file
      try {
        File(tempPath).deleteSync();
      } catch (_) {}

      item.status = DownloadStatus.completed;
      item.progress = 1.0;
    } catch (e, stack) {
      print('Download failed: $e');
      print('Download failed stack: $stack');
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ─── Batch Downloader for Search Queues ────────────────────────────────────

  Future<void> startBatchDownload({
    required List<QueuedVideo> items,
    required DownloadType type,
    required dynamic formatOrBitrate, // 'best' / '1080p' for video, 320 / 256 for audio
  }) async {
    for (final queuedItem in items) {
      _downloadSingleQueuedItem(queuedItem, type, formatOrBitrate);
    }
  }

  Future<void> _downloadSingleQueuedItem(
    QueuedVideo queuedItem,
    DownloadType type,
    dynamic formatOrBitrate,
  ) async {
    final activeItem = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + queuedItem.id,
      title: queuedItem.title,
      thumbnailUrl: queuedItem.thumbnailUrl,
      type: type,
      quality: type == DownloadType.video ? '$formatOrBitrate' : '${formatOrBitrate}kbps',
      status: DownloadStatus.queued,
    );

    _downloads.insert(0, activeItem);
    notifyListeners();

    try {
      // 1. Fetch metadata on the fly
      final videoInfo = await YoutubeService.getVideoInfo(queuedItem.url);

      activeItem.status = DownloadStatus.downloading;
      notifyListeners();

      if (type == DownloadType.video) {
        // Select preferred format or default to best
        final reqQuality = '$formatOrBitrate';
        VideoFormat? format;
        for (final fmt in videoInfo.videoFormats) {
          if (fmt.qualityLabel == reqQuality || fmt.qualityLabel.contains(reqQuality)) {
            format = fmt;
            break;
          }
        }
        format ??= videoInfo.videoFormats.isNotEmpty ? videoInfo.videoFormats.first : null;

        if (format == null) throw Exception('No matching video streams available.');

        final savePath = await _getSavePath(
          '${_sanitizeFilename(videoInfo.title)}_${format.qualityLabel}.mp4',
        );

        activeItem.filePath = savePath;

        await DownloadService.downloadVideo(
          videoInfo: videoInfo,
          format: format,
          savePath: savePath,
          onProgress: (progress) {
            activeItem.progress = progress;
            notifyListeners();
          },
        );
      } else {
        // Audio conversion
        final kbps = formatOrBitrate is int ? formatOrBitrate : int.tryParse('$formatOrBitrate') ?? 320;
        final bitrateObj = AudioBitrate(kbps);

        final tempPath = await _getSavePath(
          '${_sanitizeFilename(videoInfo.title)}_temp.webm',
          temp: true,
        );
        final savePath = await _getSavePath(
          '${_sanitizeFilename(videoInfo.title)}_${bitrateObj.kbps}kbps.mp3',
        );

        activeItem.filePath = savePath;

        // Step 1: Download
        await DownloadService.downloadAudioStream(
          videoInfo: videoInfo,
          savePath: tempPath,
          onProgress: (progress) {
            activeItem.progress = progress * 0.7;
            notifyListeners();
          },
        );

        // Step 2: Convert
        activeItem.status = DownloadStatus.converting;
        activeItem.progress = 0.7;
        notifyListeners();

        await DownloadService.convertToMp3(
          inputPath: tempPath,
          outputPath: savePath,
          bitrateKbps: bitrateObj.kbps,
          onProgress: (progress) {
            activeItem.progress = 0.7 + (progress * 0.3);
            notifyListeners();
          },
        );

        // Cleanup
        try {
          File(tempPath).deleteSync();
        } catch (_) {}
      }

      activeItem.status = DownloadStatus.completed;
      activeItem.progress = 1.0;
    } catch (e, stack) {
      print('Queued item download failed: $e');
      print('Queued item download stack: $stack');
      activeItem.status = DownloadStatus.failed;
      activeItem.errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ─── Utility Operations ────────────────────────────────────────────────────

  void removeDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _downloads.removeWhere((d) => d.status == DownloadStatus.completed);
    notifyListeners();
  }

  Future<String> _getSavePath(String filename, {bool temp = false}) async {
    Directory dir;
    if (temp) {
      dir = await getTemporaryDirectory();
    } else if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/Streamo');
    } else if (Platform.isWindows) {
      final downloads = await getDownloadsDirectory();
      dir = Directory(p.join(downloads!.path, 'YtMp3'));
    } else {
      dir = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(dir.path, 'YtMp3'));
    }

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return p.join(dir.path, filename);
  }

  String _sanitizeFilename(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.substring(0, sanitized.length > 80 ? 80 : sanitized.length);
  }
}
