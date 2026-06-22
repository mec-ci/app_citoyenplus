class Commentaire {
  final String id;
  final String publicationId;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String texte;
  final DateTime createdAt;
  final int likesCount;
  final bool liked;

  Commentaire({
    required this.id,
    required this.publicationId,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.texte,
    required this.createdAt,
    this.likesCount = 0,
    this.liked = false,
  });

  factory Commentaire.fromJson(Map<String, dynamic> json) {
    return Commentaire(
      id: json['id'] ?? '',
      publicationId: json['publicationId'] ?? json['publication_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      authorName: json['authorName'] ?? json['author_name'] ?? json['userName'] ?? 'Utilisateur',
      authorAvatar: json['authorAvatar'] ?? json['author_avatar'] ?? json['userAvatar'],
      texte: json['texte'] ?? json['text'] ?? json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      liked: json['liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicationId': publicationId,
        'userId': userId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'texte': texte,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'liked': liked,
      };
}
