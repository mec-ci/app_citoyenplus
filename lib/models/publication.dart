class Publication {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String type; // 'actualite' ou 'signalement'
  final String categorie;
  final String texte;
  final List<String> images; // URLs
  final String? localisation;
  final String? statut; // pour signalement : 'non_resolu', 'en_cours', 'resolu'
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool liked; // pour l'utilisateur connecté

  Publication({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.type,
    required this.categorie,
    required this.texte,
    required this.images,
    this.localisation,
    this.statut,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    this.liked = false,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      authorName: json['authorName'] ?? json['author_name'] ?? json['userName'] ?? 'Utilisateur',
      authorAvatar: json['authorAvatar'] ?? json['author_avatar'] ?? json['userAvatar'],
      type: (json['type'] ?? 'actualite').toLowerCase(),
      categorie: json['categorie'] ?? json['category'] ?? '',
      texte: json['texte'] ?? json['text'] ?? json['content'] ?? '',
      images: (json['images'] as List?)?.map((img) => img.toString()).toList() ?? [],
      localisation: json['localisation'] ?? json['location'],
      statut: json['statut'] ?? json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      commentsCount: json['commentsCount'] ?? json['comments_count'] ?? 0,
      liked: json['liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'type': type,
        'categorie': categorie,
        'texte': texte,
        'images': images,
        'localisation': localisation,
        'statut': statut,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'liked': liked,
      };
}
