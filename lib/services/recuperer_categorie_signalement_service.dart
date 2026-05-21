import 'dart:convert';
import 'package:http/http.dart' as http ;

import '../models/categorie_signalement_model.dart';

Future<List<CategorieSignalementModel>> fetchAllCategories(String token) async {
  final response = await http.get(
    Uri.parse('https://admin.mec-ci.org/api/v1/categorie-signalement'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
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
