import '../config/api_config.dart';

class PostModel {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String content;
  final String? imageUrl;
  final DateTime date;

  PostModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.content,
    this.imageUrl,
    required this.date,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['imageUrl'] as String?;
    return PostModel(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      excerpt: json['excerpt'] ?? '',
      content: json['content'] ?? '',
        imageUrl: (rawImage != null && rawImage.isNotEmpty)
          ? (rawImage.startsWith('http')
            ? rawImage
            : '${ApiConfig.host}$rawImage')
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'date': date.toIso8601String(),
    };
  }
}