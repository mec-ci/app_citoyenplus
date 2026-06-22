import 'package:dio/dio.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';
import 'package:citoyen_plus/models/categorie_signalement_model.dart';

class CategorieSignalementService {
  static final Dio _dio = DioClient.getInstance();

  static Future<List<CategorieSignalementModel>> fetchAllCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categorieSignalement);
      final data = response.data;
      final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
      if (items is List) {
        return items
            .map((json) =>
                CategorieSignalementModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      return _mockCategories;
    }
  }

  static List<CategorieSignalementModel> get _mockCategories => [
    CategorieSignalementModel(
      id: 'mock_cat_1',
      nom: 'Voirie',
      description: 'Problèmes de voirie et routes',
      validationObligatoire: false,
    ),
    CategorieSignalementModel(
      id: 'mock_cat_2',
      nom: 'Éclairage public',
      description: 'Pannes d\'éclairage public',
      validationObligatoire: false,
    ),
    CategorieSignalementModel(
      id: 'mock_cat_3',
      nom: 'Eau et assainissement',
      description: 'Problèmes d\'eau et d\'assainissement',
      validationObligatoire: false,
    ),
    CategorieSignalementModel(
      id: 'mock_cat_4',
      nom: 'Déchets',
      description: 'Problèmes de collecte des déchets',
      validationObligatoire: false,
    ),
    CategorieSignalementModel(
      id: 'mock_cat_5',
      nom: 'Sécurité',
      description: 'Problèmes de sécurité publique',
      validationObligatoire: false,
    ),
  ];
}
