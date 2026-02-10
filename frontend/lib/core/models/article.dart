class Article {
  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final String? sourceName;
  final DateTime? publishedAt;
  final String? url;

  /// 🆕 Yorum sayısı (counter cache – backend’den gelir)
  final int commentsCount;

  const Article({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    this.sourceName,
    this.publishedAt,
    this.url,
    this.commentsCount = 0, // ✅ default
  });

  // ---------------------------
  // JSON -> Article
  // ---------------------------
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: json['summary']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      url: json['url']?.toString(),
      sourceName: (json['source'] is Map)
          ? json['source']['name']?.toString()
          : json['sourceName']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,

      // 🆕 backend yoksa 0
      commentsCount: int.tryParse((json['commentsCount'] ?? 0).toString()) ?? 0,
    );
  }

  // ---------------------------
  // Article -> JSON
  // (Saved / SharedPreferences için)
  // ---------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      'url': url,
      'publishedAt': publishedAt?.toIso8601String(),
      'source': sourceName == null ? null : {'name': sourceName},

      // 🆕 persist edelim ki cache bozulmasın
      'commentsCount': commentsCount,
    };
  }

  // ---------------------------
  // Kopya üretmek için
  // ---------------------------
  Article copyWith({
    String? id,
    String? title,
    String? summary,
    String? imageUrl,
    String? sourceName,
    DateTime? publishedAt,
    String? url,
    int? commentsCount,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceName: sourceName ?? this.sourceName,
      publishedAt: publishedAt ?? this.publishedAt,
      url: url ?? this.url,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  // ---------------------------
  // Equality (Saved list, karşılaştırma için)
  // ---------------------------
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Article && runtimeType == other.runtimeType && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
