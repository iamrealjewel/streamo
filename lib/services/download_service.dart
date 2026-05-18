import 'dart:async';
import 'dart:io';
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
    try {
      if (format.hasAudio) {
        // Muxed: single stream download
        Future<yt.StreamInfo> getStreamInfo() async {
          final manifest = await ytClient.videos.streamsClient.getManifest(
            yt.VideoId(videoInfo.id),
            ytClients: [
              yt.YoutubeApiClient.tv,
              yt.YoutubeApiClient.ios,
              yt.YoutubeApiClient.androidVr,
            ],
          );
          yt.StreamInfo? targetStream;
          for (final stream in manifest.muxed) {
            if (stream.videoQuality.name == format.qualityLabel && stream.container.name == format.container) {
              targetStream = stream;
              break;
            }
          }
          targetStream ??= manifest.muxed.firstWhere((s) => s.videoQuality.name == format.qualityLabel, orElse: () => manifest.muxed.first);
          return targetStream;
        }

        await _downloadStreamWithRetry(
          ytClient: ytClient,
          getStreamInfo: getStreamInfo,
          savePath: savePath,
          onProgress: onProgress,
        );
      } else {
        // Video-only: download video + best audio, then merge with FFmpeg
        final videoTemp = savePath.replaceFirst('.mp4', '_video_tmp.${format.container}');
        final audioTemp = savePath.replaceFirst('.mp4', '_audio_tmp.webm');

        // Download video
        await _downloadStreamWithRetry(
          ytClient: ytClient,
          getStreamInfo: () async {
            final manifest = await ytClient.videos.streamsClient.getManifest(
              yt.VideoId(videoInfo.id),
              ytClients: [
                yt.YoutubeApiClient.tv,
                yt.YoutubeApiClient.ios,
                yt.YoutubeApiClient.androidVr,
              ],
            );
            yt.StreamInfo? targetStream;
            for (final stream in manifest.videoOnly) {
              if (stream.videoQuality.name == format.qualityLabel && stream.container.name == format.container) {
                targetStream = stream;
                break;
              }
            }
            targetStream ??= manifest.videoOnly.firstWhere((s) => s.videoQuality.name == format.qualityLabel, orElse: () => manifest.videoOnly.first);
            return targetStream;
          },
          savePath: videoTemp,
          onProgress: (p) => onProgress(p * 0.45),
        );

        // Download audio
        bool hasAudio = false;
        await _downloadStreamWithRetry(
          ytClient: ytClient,
          getStreamInfo: () async {
            final manifest = await ytClient.videos.streamsClient.getManifest(
              yt.VideoId(videoInfo.id),
              ytClients: [
                yt.YoutubeApiClient.tv,
                yt.YoutubeApiClient.ios,
                yt.YoutubeApiClient.androidVr,
              ],
            );
            final bestAudio = manifest.audioOnly.toList()
              ..sort((a, b) =>
                  b.bitrate.kiloBitsPerSecond.compareTo(a.bitrate.kiloBitsPerSecond));
            if (bestAudio.isEmpty) {
              throw Exception('No audio streams available for this video.');
            }
            hasAudio = true;
            return bestAudio.first;
          },
          savePath: audioTemp,
          onProgress: (p) => onProgress(0.45 + p * 0.25),
        );

        onProgress(0.7);

        // Merge with FFmpeg (30%)
        final cmd = '-y -i "$videoTemp" ${hasAudio ? '-i "$audioTemp"' : ''} '
            '-c:v copy ${hasAudio ? '-c:a aac -b:a 192k' : ''} "$savePath"';

        await _runFFmpeg(cmd, onProgress: (p) {
          onProgress(0.7 + p * 0.3);
        });

        // Cleanup temps
        _deleteIfExists(videoTemp);
        if (hasAudio) _deleteIfExists(audioTemp);
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
    try {
      await _downloadStreamWithRetry(
        ytClient: ytClient,
        getStreamInfo: () async {
          final manifest = await ytClient.videos.streamsClient.getManifest(
            yt.VideoId(videoInfo.id),
            ytClients: [
              yt.YoutubeApiClient.tv,
              yt.YoutubeApiClient.ios,
              yt.YoutubeApiClient.androidVr,
            ],
          );
          final audioStreams = manifest.audioOnly.toList()
            ..sort((a, b) =>
                b.bitrate.kiloBitsPerSecond.compareTo(a.bitrate.kiloBitsPerSecond));

          if (audioStreams.isEmpty) {
            throw Exception('No audio streams available for this video.');
          }
          return audioStreams.first;
        },
        savePath: savePath,
        onProgress: onProgress,
      );
    } finally {
      ytClient.close();
    }
  }

  /// Convert standard audio to premium MP3 format using custom bitrates.
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

  /// Unified stream downloader using resumable HTTP range requests.
  static Future<void> _downloadStreamWithRetry({
    required yt.YoutubeExplode ytClient,
    required Future<yt.StreamInfo> Function() getStreamInfo,
    required String savePath,
    required void Function(double) onProgress,
  }) async {
    final file = File(savePath);
    int downloaded = 0;
    int attempt = 0;
    const maxAttempts = 5;

    // Get the target stream info ONCE to avoid multiple getManifest calls
    final targetStream = await getStreamInfo();
    final totalBytes = targetStream.size.totalBytes;
    final streamUri = targetStream.url;

    // Delete existing file before we start fresh
    if (await file.exists()) {
      await file.delete();
    }
    await file.create(recursive: true);

    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 15);

    while (attempt < maxAttempts) {
      RandomAccessFile? raf;
      try {
        raf = await file.open(mode: downloaded == 0 ? FileMode.write : FileMode.append);
        
        final from = downloaded;
        final to = totalBytes - 1;

        Uri finalUri = streamUri;
        final headersMap = <String, String>{
          'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36',
          'cookie': 'CONSENT=YES+cb',
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'accept-language': 'en-US,en;q=0.5',
        };

        if (streamUri.queryParameters['c'] == 'ANDROID') {
          headersMap['Range'] = 'bytes=$from-$to';
        } else {
          // If not Android, pass range as query parameter
          finalUri = streamUri.replace(
            queryParameters: {
              ...streamUri.queryParameters,
              'range': '$from-$to',
            },
          );
        }

        final request = await httpClient.getUrl(finalUri);
        headersMap.forEach((key, value) {
          request.headers.set(key, value);
        });

        final response = await request.close().timeout(const Duration(seconds: 15));
        
        if (response.statusCode != 200 && response.statusCode != 206) {
          throw HttpException('Server returned status code ${response.statusCode}');
        }

        // Stream response bytes and write chunk-by-chunk with progress updates
        await for (final chunk in response.timeout(const Duration(seconds: 20))) {
          await raf.writeFrom(chunk);
          downloaded += chunk.length;
          if (totalBytes > 0) {
            onProgress((downloaded / totalBytes).clamp(0.0, 1.0));
          }
        }

        // Success!
        await raf.close();
        httpClient.close();
        return;
      } catch (e) {
        attempt++;
        print('DEBUG: Download attempt $attempt failed at $downloaded/$totalBytes bytes with error: $e. Retrying in 2s...');
        
        try {
          await raf?.close();
        } catch (_) {}

        if (attempt >= maxAttempts) {
          httpClient.close();
          throw Exception('Download failed after $maxAttempts attempts at $downloaded/$totalBytes: $e');
        }
        await Future.delayed(const Duration(seconds: 2));
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
