import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/video_info.dart';

class YoutubeService {
  static Future<VideoInfo> getVideoInfo(String url) async {
    final ytClient = yt.YoutubeExplode();
    try {
      final video = await ytClient.videos.get(url);
      final manifest = await ytClient.videos.streamsClient.getManifest(video.id);

      // Collect video formats (muxed + video-only)
      final videoFormats = <VideoFormat>[];
      final seen = <String>{};

      // Muxed streams (video + audio combined)
      for (final stream in manifest.muxed) {
        final label = stream.videoQuality.name;
        final key = '${label}_${stream.container.name}_muxed';
        if (!seen.contains(key)) {
          seen.add(key);
          videoFormats.add(VideoFormat(
            qualityLabel: label,
            width: stream.videoResolution.width,
            height: stream.videoResolution.height,
            fps: stream.framerate.framesPerSecond.round(),
            container: stream.container.name,
            bitrate: stream.bitrate.kiloBitsPerSecond.round(),
            streamUrl: stream.url.toString(),
            hasAudio: true,
          ));
        }
      }

      // Video-only streams (higher quality, needs audio merge)
      for (final stream in manifest.videoOnly) {
        final label = stream.videoQuality.name;
        final fps = stream.framerate.framesPerSecond.round();
        final key = '${label}_${fps}_${stream.container.name}_videoonly';
        if (!seen.contains(key)) {
          seen.add(key);
          videoFormats.add(VideoFormat(
            qualityLabel: label,
            width: stream.videoResolution.width,
            height: stream.videoResolution.height,
            fps: fps,
            container: stream.container.name,
            bitrate: stream.bitrate.kiloBitsPerSecond.round(),
            streamUrl: stream.url.toString(),
            hasAudio: false,
          ));
        }
      }

      // Sort by resolution descending, then fps
      videoFormats.sort((a, b) {
        final heightCmp = b.height.compareTo(a.height);
        if (heightCmp != 0) return heightCmp;
        return b.fps.compareTo(a.fps);
      });

      // Collect audio formats
      final audioFormats = manifest.audioOnly
          .map((s) => AudioFormat(
                bitrate: s.bitrate.kiloBitsPerSecond.round(),
                container: s.container.name,
                streamUrl: s.url.toString(),
              ))
          .toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

      // Best thumbnail (maxres preferred)
      String thumbnailUrl =
          'https://img.youtube.com/vi/${video.id.value}/maxresdefault.jpg';

      return VideoInfo(
        id: video.id.value,
        title: video.title,
        author: video.author,
        thumbnailUrl: thumbnailUrl,
        duration: video.duration ?? Duration.zero,
        url: url,
        videoFormats: videoFormats,
        audioFormats: audioFormats,
      );
    } catch (e) {
      if (identical(0, 0.0)) { // Simple check for JS/Web
        throw Exception('YouTube metadata fetching often fails on Web due to CORS. Please test on Android, iOS, or Windows.\nInternal error: $e');
      }
      throw Exception('Could not fetch video info: $e');
    } finally {
      ytClient.close();
    }
  }

  static String? extractVideoId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'v=([a-zA-Z0-9_-]{11})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static bool isValidYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }
}
