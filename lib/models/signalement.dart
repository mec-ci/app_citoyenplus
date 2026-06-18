import 'package:citoyen_plus/core/network/api_endpoints.dart';

class SignalementModel {
  final String id;
  final String titre;
  final String description;
  final String categorieId;
  final CategorieSignalementModel? categorie;
  final bool validation;
  final String adresse;
  final double latitude;
  final double longitude;
  final String? photo;
  final String statut;
  final String citoyenId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  SignalementModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorieId,
    this.categorie,
    this.validation = false,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    this.photo,
    this.statut = 'NOUVEAU',
    required this.citoyenId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    final categorieJson = json['categorie'] as Map<String, dynamic>?;
    String? photoUrl = json['photo'] as String?;
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = '${ApiEndpoints.apiBaseUrl}$photoUrl';
    }

    return SignalementModel(
      id: (json['id'] ?? '').toString(),
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categorieId: (json['categorieId'] ?? '').toString(),
      categorie: categorieJson != null
          ? CategorieSignalementModel.fromJson(categorieJson)
          : null,
      validation: json['validation'] == true,
      adresse: json['adresse']?.toString() ?? '',
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'])
          : (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'])
          : (json['longitude'] as num?)?.toDouble() ?? 0.0,
      photo: photoUrl,
      statut: json['statut']?.toString() ?? 'NOUVEAU',
      citoyenId: (json['citoyenId'] ?? '').toString(),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'description': description,
      'categorieId': categorieId,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      if (photo != null) 'photo': photo,
    };
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    return parsed;
  }
}

class CategorieSignalementModel {
  final String nom;
  final String description;
  final bool validationObligatoire;

  CategorieSignalementModel({
    required this.nom,
    required this.description,
    required this.validationObligatoire,
  });

  factory CategorieSignalementModel.fromJson(Map<String, dynamic> json) {
    return CategorieSignalementModel(
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
