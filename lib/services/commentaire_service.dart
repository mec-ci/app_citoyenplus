import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';

/// Auteur d'un commentaire.
class CommentaireAuteur {
  final String id;
  final String nom;
  final String? avatar;

  const CommentaireAuteur({required this.id, required this.nom, this.avatar});

  factory CommentaireAuteur.fromJson(Map<String, dynamic> json) {
    return CommentaireAuteur(
      id: (json['id'] ?? '').toString(),
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? 'Utilisateur',
      avatar: json['avatar']?.toString(),
    );
  }
}

/// Un commentaire sur un signalement ou une actualité.
class Commentaire {
  final String id;
  final String contenu;
  final DateTime? createdAt;
  final CommentaireAuteur? auteur;

  const Commentaire({
    required this.id,
    required this.contenu,
    this.createdAt,
    this.auteur,
  });

  factory Commentaire.fromJson(Map<String, dynamic> json) {
    final auteurJson = json['auteur'] as Map<String, dynamic>?;
    return Commentaire(
      id: (json['id'] ?? '').toString(),
      contenu: json['contenu']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      auteur: auteurJson != null
          ? CommentaireAuteur.fromJson(auteurJson)
          : null,
    );
  }
}

/// Page de commentaires paginée.
class CommentairePage {
  final List<Commentaire> data;
  final int total;
  final int page;
  final int limit;

  const CommentairePage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });
}

enum CommentaireCible { signalement, actualite }

/// Service de gestion des commentaires (signalements et actualités).
class CommentaireService {
  static final Dio _dio = DioClient.getInstance();

  static String _basePath(CommentaireCible cible, String id) {
    switch (cible) {
      case CommentaireCible.signalement:
        return ApiEndpoints.signalementCommentaires(id);
      case CommentaireCible.actualite:
        return ApiEndpoints.actualiteCommentaires(id);
    }
  }

  /// Récupère les commentaires d'une cible.
  static Future<CommentairePage> fetch({
    required CommentaireCible cible,
    required String id,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      _basePath(cible, id),
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = response.data;
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final list = (map['data'] as List?) ?? const [];
    return CommentairePage(
      data: list
          .map((e) => Commentaire.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      total: (map['total'] as num?)?.toInt() ?? list.length,
      page: (map['page'] as num?)?.toInt() ?? page,
      limit: (map['limit'] as num?)?.toInt() ?? limit,
    );
  }

  /// Publie un commentaire et renvoie le commentaire créé.
  static Future<Commentaire> add({
    required CommentaireCible cible,
    required String id,
    required String contenu,
  }) async {
    final response = await _dio.post(
      _basePath(cible, id),
      data: {'contenu': contenu},
    );
    final raw = response.data;
    final map = raw is Map<String, dynamic>
        ? (raw['data'] is Map ? (raw['data'] as Map).cast<String, dynamic>() : raw)
        : <String, dynamic>{};
    return Commentaire.fromJson(map);
  }
}
