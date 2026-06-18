import '../config/api_config.dart';

class PostModel {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String content;
  final String? imageUrl;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.content,
    this.imageUrl,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['imageUrl'] as String?;
    return PostModel(
      id: (json['id'] ?? '').toString(),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: (rawImage != null && rawImage.isNotEmpty)
          ? (rawImage.startsWith('http')
              ? rawImage
              : '${ApiConfig.host}$rawImage')
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'excerpt': excerpt,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'date': date.toIso8601String(),
    };
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
