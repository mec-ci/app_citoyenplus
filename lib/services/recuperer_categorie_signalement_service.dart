import 'dart:convert';
import 'auth_service.dart';
import '../config/api_config.dart';

import '../models/categorie_signalement_model.dart';

Future<List<CategorieSignalementModel>> fetchAllCategories() async {
  final response = await AuthService.authorizedGet(
    Uri.parse('${ApiConfig.baseUrl}/categorie-signalement'),
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    List<dynamic> jsonList;
    if (decoded is List) {
      jsonList = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      jsonList = decoded['data'] as List;
    } else {
      return [];
    }
    return jsonList
        .map((json) => CategorieSignalementModel.fromJson(json))
        .toList();
  } else {
    throw Exception(
        'Erreur lors de la récupération des catégories: ${response.body}');
  }
}
