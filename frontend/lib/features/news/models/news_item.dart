class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String category;
  final String? imageUrl;
  final String? url;
  final DateTime publishedAt;

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
    this.url,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);
    if (diff.inMinutes < 1) return "şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk";
    if (diff.inHours < 24) return "${diff.inHours} sa";
    return "${diff.inDays} g";
  }

  factory NewsItem.fromJson(Map<String, dynamic> j) {
    return NewsItem(
      id: j["id"] as String,
      title: (j["title"] ?? "") as String,
      summary: (j["summary"] ?? "") as String,
      source: (j["source"] ?? "AutoNews") as String,
      category: (j["category"] ?? "Öne Çıkanlar") as String,
      imageUrl: j["imageUrl"] as String?,
      url: j["url"] as String?,
      publishedAt: DateTime.parse(j["publishedAt"] as String),
    );
  }
}
