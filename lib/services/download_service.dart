import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/video_info.dart';

class DownloadService {

  /// Download a muxed video stream directly, or video+audio for high-res.
  static Future<void> downloadVideo({
    required VideoInfo videoInfo,
    required VideoFormat format,
    required String savePath,
    required void Function(double) onProgress,
  }) async {
    final ytClient = yt.YoutubeExplode();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.youtube.com/',
      },
    ));
    try {
      final manifest = await ytClient.videos.streamsClient.getManifest(yt.VideoId(videoInfo.id));

      if (format.hasAudio) {
        // Muxed: single stream download
        yt.StreamInfo? targetStream;
        for (final stream in manifest.muxed) {
          if (stream.videoQuality.name == format.qualityLabel && stream.container.name == format.container) {
            targetStream = stream;
            break;
          }
        }
        targetStream ??= manifest.muxed.firstWhere((s) => s.videoQuality.name == format.qualityLabel, orElse: () => manifest.muxed.first);

        await _downloadWithRetry(
          dio: dio,
          url: targetStream.url.toString(),
          savePath: savePath,
          onProgress: onProgress,
        );
      } else {
        // Video-only: download video + best audio, then merge with FFmpeg
        final bestAudio = manifest.audioOnly.toList()
          ..sort((a, b) =>
              b.bitrate.kiloBitsPerSecond.compareTo(a.bitrate.kiloBitsPerSecond));

        final videoTemp = savePath.replaceFirst('.mp4', '_video_tmp.${format.container}');
        final audioTemp = savePath.replaceFirst('.mp4', '_audio_tmp.webm');

        // Find target video stream
        yt.StreamInfo? targetStream;
        for (final stream in manifest.videoOnly) {
          if (stream.videoQuality.name == format.qualityLabel && stream.container.name == format.container) {
            targetStream = stream;
            break;
          }
        }
        targetStream ??= manifest.videoOnly.firstWhere((s) => s.videoQuality.name == format.qualityLabel, orElse: () => manifest.videoOnly.first);

        // Download video
        await _downloadWithRetry(
          dio: dio,
          url: targetStream.url.toString(),
          savePath: videoTemp,
          onProgress: (p) => onProgress(p * 0.45),
        );

        // Download audio
        if (bestAudio.isNotEmpty) {
          final audioStreamInfo = bestAudio.first;
          await _downloadWithRetry(
            dio: dio,
            url: audioStreamInfo.url.toString(),
            savePath: audioTemp,
            onProgress: (p) => onProgress(0.45 + p * 0.25),
          );
        }

        onProgress(0.7);

        // Merge with FFmpeg (30%)
        final cmd = '-y -i "$videoTemp" ${bestAudio.isNotEmpty ? '-i "$audioTemp"' : ''} '
            '-c:v copy ${bestAudio.isNotEmpty ? '-c:a aac -b:a 192k' : ''} "$savePath"';

        await _runFFmpeg(cmd, onProgress: (p) {
          onProgress(0.7 + p * 0.3);
        });

        // Cleanup temps
        _deleteIfExists(videoTemp);
        if (bestAudio.isNotEmpty) _deleteIfExists(audioTemp);
      }
    } finally {
      ytClient.close();
    }
  }

  /// Download the best audio stream for MP3 conversion.
  static Future<void> downloadAudioStream({
    required VideoInfo videoInfo,
    required String savePath,
    required void Function(double) onProgress,
  }) async {
    final ytClient = yt.YoutubeExplode();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.youtube.com/',
      },
    ));
    try {
      final manifest = await ytClient.videos.streamsClient.getManifest(yt.VideoId(videoInfo.id));
      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) =>
            b.bitrate.kiloBitsPerSecond.compareTo(a.bitrate.kiloBitsPerSecond));

      if (audioStreams.isEmpty) {
        throw Exception('No audio streams available for this video.');
      }

      final targetStream = audioStreams.first;
      await _downloadWithRetry(
        dio: dio,
        url: targetStream.url.toString(),
        savePath: savePath,
        onProgress: onProgress,
      );
    } finally {
      ytClient.close();
    }
  }

  /// Convert an audio file to MP3 at the specified bitrate.
  static Future<void> convertToMp3({
    required String inputPath,
    required String outputPath,
    required int bitrateKbps,
    required void Function(double) onProgress,
  }) async {
    final cmd =
        '-y -i "$inputPath" -vn -ar 44100 -ac 2 -b:a ${bitrateKbps}k "$outputPath"';
    await _runFFmpeg(cmd, onProgress: onProgress);
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────

  /// Custom chunk downloader with resume support via HTTP Range header.
  static Future<void> _downloadWithRetry({
    required Dio dio,
    required String url,
    required String savePath,
    required void Function(double) onProgress,
  }) async {
    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }

    int downloaded = 0;
    int totalBytes = -1;
    int attempt = 0;
    const maxAttempts = 5;

    while (attempt < maxAttempts) {
      try {
        if (totalBytes > 0 && downloaded >= totalBytes) {
          return;
        }

        final options = Options(
          responseType: ResponseType.stream,
          headers: {
            if (downloaded > 0) 'Range': 'bytes=$downloaded-',
          },
        );

        final response = await dio.get<ResponseBody>(url, options: options);
        
        if (totalBytes == -1) {
          final contentLength = response.headers.value('content-length');
          if (contentLength != null) {
            totalBytes = downloaded + int.parse(contentLength);
          }
        }

        final fileSink = await file.open(mode: FileMode.writeOnlyAppend);
        final stream = response.data!.stream;

        try {
          await for (final chunk in stream) {
            await fileSink.writeFrom(chunk);
            downloaded += chunk.length;
            if (totalBytes > 0) {
              onProgress(downloaded / totalBytes);
            }
          }
          await fileSink.close();
          return; // Success!
        } catch (e) {
          await fileSink.close();
          rethrow;
        }
      } catch (e) {
        attempt++;
        print('DEBUG: Download attempt $attempt failed with error: $e. Retrying in 1s...');
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  static Future<void> _runFFmpeg(
    String command, {
    required void Function(double) onProgress,
  }) async {
    print('DEBUG: FFmpeg executing command: ffmpeg $command');
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final time = stats.getTime();
      final size = stats.getSize();
      final bitrate = stats.getBitrate();
      final speed = stats.getSpeed();
      print('DEBUG: FFmpeg stats -> time: ${time}ms, size: ${size}bytes, bitrate: ${bitrate}kbps, speed: ${speed}x');
      if (time > 0) {
        onProgress((time / 1000.0).clamp(0.0, 1.0));
      }
    });

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    print('DEBUG: FFmpeg session finished with return code: $returnCode');

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getOutput();
      final failStackTrace = await session.getFailStackTrace();
      print('DEBUG: FFmpeg execution FAILED!');
      print('DEBUG: FFmpeg logs: $logs');
      print('DEBUG: FFmpeg stack trace: $failStackTrace');
      throw Exception('FFmpeg conversion failed: $logs');
    }

    print('DEBUG: FFmpeg execution SUCCEEDED!');
    onProgress(1.0);
  }

  static void _deleteIfExists(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}
