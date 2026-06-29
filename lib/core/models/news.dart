/// A news / announcement post (`GET /api/news` + `/api/news/:slug`).
class NewsPost {
  const NewsPost({
    required this.slug,
    required this.title,
    this.body = '',
    this.type,
    this.publishedAt,
  });

  factory NewsPost.fromJson(Map<String, dynamic> json) => NewsPost(
    slug: json['slug']?.toString() ?? '',
    title: json['title']?.toString().trim() ?? '',
    body: json['body']?.toString() ?? '',
    type: json['type']?.toString(),
    publishedAt: json['published_at']?.toString(),
  );

  final String slug;
  final String title;
  final String body;
  final String? type;
  final String? publishedAt;
}

/// `GET /api/news` envelope.
typedef NewsList = ({List<NewsPost> items, int total});

NewsList parseNewsList(Map<String, dynamic> json) => (
  items:
      (json['items'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(NewsPost.fromJson)
          .toList() ??
      const <NewsPost>[],
  total: (json['total'] as num?)?.toInt() ?? 0,
);
