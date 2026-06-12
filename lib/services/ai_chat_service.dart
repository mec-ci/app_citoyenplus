import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AiChatService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/ai-chat'; // ← endpoint à créer sur ton backend

  /// Envoie l'historique complet des messages et reçoit la réponse de l'IA.
  /// [messages] = liste de { "role": "user"|"assistant", "content": "..." }
  static Future<String> sendMessage(
      List<Map<String, String>> messages) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Jeton manquant. Connecte-toi d\'abord.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'messages': messages}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      // Adapte selon la structure de réponse de ton backend
      return json['response'] ?? json['content'] ?? "Pas de réponse.";
    } else {
      throw Exception(
          'Erreur IA: ${response.statusCode} - ${response.body}');
    }
  }
}