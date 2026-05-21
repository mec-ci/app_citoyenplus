class CategorieSignalementModel {
  final String id;
  final String nom;
  final String description;
  final bool validationObligatoire;
 

  CategorieSignalementModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.validationObligatoire,
    
  });

  factory CategorieSignalementModel.fromJson(Map<String, dynamic> json) {
    return CategorieSignalementModel(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      validationObligatoire: json['validationObligatoire'] ?? false,
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'validationObligatoire': validationObligatoire,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorieSignalementModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
