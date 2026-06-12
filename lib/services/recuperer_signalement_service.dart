import 'dart:convert';
import 'package:citoyen_plus/models/signalement.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class RecupererSignalementService {
  static Future<List<SignalementModel>> fetchAllSignalement(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/signalement-citoyen');
    final response = await AuthService.authorizedGet(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Si ton API renvoie { data: [...] }
      final List<dynamic> postsJson = jsonResponse['data'];

      return postsJson.map((json) => SignalementModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des signalements: ${response.body}');
    }
  }
}

