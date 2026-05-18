class VideoInfo {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration duration;
  final String url;
  final List<VideoFormat> videoFormats;
  final List<AudioFormat> audioFormats;

  VideoInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    required this.url,
    required this.videoFormats,
    required this.audioFormats,
  });

  String get durationString {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class VideoFormat {
  final String qualityLabel; // e.g., "1080p", "720p60"
  final int width;
  final int height;
  final int fps;
  final String container; // mp4, webm
  final int? bitrate;
  final String streamUrl;
  final bool hasAudio;

  VideoFormat({
    required this.qualityLabel,
    required this.width,
    required this.height,
    required this.fps,
    required this.container,
    this.bitrate,
    required this.streamUrl,
    required this.hasAudio,
  });

  String get displayLabel {
    final fpsStr = fps > 30 ? ' ${fps}fps' : '';
    return '$qualityLabel$fpsStr';
  }
}

class AudioFormat {
  final int bitrate; // kbps
  final String container; // webm, mp4a
  final String streamUrl;

  AudioFormat({
    required this.bitrate,
    required this.container,
    required this.streamUrl,
  });
}

class AudioBitrate {
  final int kbps;
  const AudioBitrate(this.kbps);

  static const List<AudioBitrate> all = [
    AudioBitrate(320),
    AudioBitrate(256),
    AudioBitrate(192),
    AudioBitrate(128),
    AudioBitrate(96),
    AudioBitrate(64),
  ];
}
