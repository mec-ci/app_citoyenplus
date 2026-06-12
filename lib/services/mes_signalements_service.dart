import 'dart:convert';
import 'package:citoyen_plus/models/signalement.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class MesSignalementsService {
  static Future<List<SignalementModel>> fetchMesSignalements(
      String citoyenId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/signalement-citoyen');
    final response = await AuthService.authorizedGet(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];

      // ✅ Filtre uniquement les signalements de l'utilisateur connecté
      return data
          .map((json) => SignalementModel.fromJson(json))
          .where((s) => s.citoyenId == citoyenId)
          .toList()
        ..sort((a, b) {
          final dateA = a.createdAt ?? DateTime(0);
          final dateB = b.createdAt ?? DateTime(0);
          return dateB.compareTo(dateA); // du plus récent au plus ancien
        });
    } else {
      throw Exception(
          'Erreur lors de la récupération: ${response.body}');
    }
  }
}