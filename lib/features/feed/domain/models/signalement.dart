import 'package:citoyen_plus/core/network/api_endpoints.dart';

class Signalement {
  final String id;
  final String titre;
  final String description;
  final String categorieId;
  final CategorieSignalement? categorie;
  final bool validation;
  final String adresse;
  final double latitude;
  final double longitude;
  final String? photo;
  final String statut;
  final String citoyenId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Signalement({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorieId,
    this.categorie,
    required this.validation,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    this.photo,
    required this.statut,
    required this.citoyenId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    final categorieJson = json['categorie'] as Map<String, dynamic>?;
    String? photoUrl = json['photo'] as String?;
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('http')) {
      photoUrl = '${ApiEndpoints.apiBaseUrl}$photoUrl';
    }

    return Signalement(
      id: json['id']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categorieId: json['categorieId']?.toString() ?? '',
      categorie: categorieJson != null
          ? CategorieSignalement.fromJson(categorieJson)
          : null,
      validation: json['validation'] == true,
      adresse: json['adresse']?.toString() ?? '',
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : 0.0,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : 0.0,
      photo: photoUrl,
      statut: json['statut']?.toString() ?? 'NOUVEAU',
      citoyenId: json['citoyenId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'categorieId': categorieId,
      if (categorie != null) 'categorie': categorie!.toJson(),
      'validation': validation,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      if (photo != null) 'photo': photo,
      'statut': statut,
      'citoyenId': citoyenId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    };
  }
}

class CategorieSignalement {
  final String nom;
  final String description;
  final bool validationObligatoire;

  CategorieSignalement({
    required this.nom,
    required this.description,
    required this.validationObligatoire,
  });

  factory CategorieSignalement.fromJson(Map<String, dynamic> json) {
    return CategorieSignalement(
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      validationObligatoire: json['validationObligatoire'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'validationObligatoire': validationObligatoire,
    };
  }
}
