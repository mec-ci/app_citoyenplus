import '../config/api_config.dart';

class SignalementModel {
  final String id;
  final String titre;
  final String description;
  final String categorieId;
  final String? categorieNom; // ✅ ex: "Voirie", extrait de categorie.nom
  final String adresse;
  final double latitude;
  final double longitude;
  final String? photo;
  final String? statut;
  final String citoyenId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SignalementModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorieId,
    this.categorieNom,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    this.photo,
    this.statut,
    required this.citoyenId,
    this.createdAt,
    this.updatedAt,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    final categorieJson = json['categorie'] as Map<String, dynamic>?;

    return SignalementModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      categorieId: json['categorieId'] ?? '',
      categorieNom: categorieJson?['nom'], // ✅ "Voirie"
      adresse: json['adresse'] ?? '',
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'])
          : (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'])
          : (json['longitude'] as num).toDouble(),
        photo: json['photo'] != null
          ? '${ApiConfig.host}${json['photo']}'
          : null,
      statut: json['statut'],
      citoyenId: json['citoyenId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
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
}