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

        final stream = ytClient.videos.streamsClient.get(targetStream);
        final file = File(savePath);
        final sink = file.openWrite();
        final totalBytes = targetStream.size.totalBytes;
        int receivedBytes = 0;

        await for (final chunk in stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress(receivedBytes / totalBytes);
          }
        }
        await sink.flush();
        await sink.close();
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
        final videoFile = File(videoTemp);
        final videoSink = videoFile.openWrite();
        final videoStream = ytClient.videos.streamsClient.get(targetStream);
        final videoTotalBytes = targetStream.size.totalBytes;
        int videoReceivedBytes = 0;

        await for (final chunk in videoStream) {
          videoSink.add(chunk);
          videoReceivedBytes += chunk.length;
          if (videoTotalBytes > 0) {
            onProgress((videoReceivedBytes / videoTotalBytes) * 0.45);
          }
        }
        await videoSink.flush();
        await videoSink.close();

        // Download audio
        if (bestAudio.isNotEmpty) {
          final audioFile = File(audioTemp);
          final audioSink = audioFile.openWrite();
          final audioStreamInfo = bestAudio.first;
          final audioStream = ytClient.videos.streamsClient.get(audioStreamInfo);
          final audioTotalBytes = audioStreamInfo.size.totalBytes;
          int audioReceivedBytes = 0;

          await for (final chunk in audioStream) {
            audioSink.add(chunk);
            audioReceivedBytes += chunk.length;
            if (audioTotalBytes > 0) {
              onProgress(0.45 + (audioReceivedBytes / audioTotalBytes) * 0.25);
            }
          }
          await audioSink.flush();
          await audioSink.close();
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
    try {
      final manifest = await ytClient.videos.streamsClient.getManifest(yt.VideoId(videoInfo.id));
      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) =>
            b.bitrate.kiloBitsPerSecond.compareTo(a.bitrate.kiloBitsPerSecond));

      if (audioStreams.isEmpty) {
        throw Exception('No audio streams available for this video.');
      }

      final targetStream = audioStreams.first;
      final stream = ytClient.videos.streamsClient.get(targetStream);
      final file = File(savePath);
      final sink = file.openWrite();
      final totalBytes = targetStream.size.totalBytes;
      int receivedBytes = 0;

      await for (final chunk in stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
      await sink.flush();
      await sink.close();
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
