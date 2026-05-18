class QueuedVideo {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String durationString;
  final String url;
  bool isSelected;

  QueuedVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.durationString,
    required this.url,
    this.isSelected = true,
  });
}
