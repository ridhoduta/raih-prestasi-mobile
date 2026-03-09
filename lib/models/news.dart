class News {
  final String id;
  final String title;
  final String content;
  final String? thumbnail;
  final bool isPublished;
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.thumbnail,
    this.isPublished = false,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      thumbnail: json['thumbnail'],
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
