import 'package:dio/dio.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';
import 'package:citoyen_plus/models/categorie_signalement_model.dart';

class CategorieSignalementService {
  static final Dio _dio = DioClient.getInstance();

  static Future<List<CategorieSignalementModel>> fetchAllCategories() async {
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
  }
}
