enum FeedType { signalement, action, actualite }

class FeedItem {
  final FeedType type;
  final String id;
  final String titre;
  final String description;
  final String auteurInitiales;
  final String auteurNom;
  final String? imageUrl;
  final String? adresse;
  final String? ville;
  final String? statut;
  final String? sourceInstitution;
  final String? slug;
  final String? categorieNom;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final int? likesCount;
  final int? commentsCount;
  final bool? likedByMe;

  const FeedItem({
    required this.type,
    required this.id,
    required this.titre,
    required this.description,
    this.auteurInitiales = 'OF',
    this.auteurNom = 'Officiel',
    this.imageUrl,
    this.adresse,
    this.ville,
    this.statut,
    this.sourceInstitution,
    this.slug,
    this.categorieNom,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.likesCount,
    this.commentsCount,
    this.likedByMe,
  });

  String get duree {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} j';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} sem';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} mois';
    return '${diff.inDays ~/ 365} ans';
  }
}
