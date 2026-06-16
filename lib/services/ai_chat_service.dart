import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AiChatService {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Envoie l'historique complet des messages et reçoit la réponse de l'IA Gemini.
  /// [messages] = liste de { "role": "user"|"assistant"|"system", "content": "..." }
  static Future<String> sendMessage(List<Map<String, String>> messages) async {
    final apiKey = ApiConfig.geminiApiKey;

    // Extraction du system prompt s'il existe
    String? systemPrompt;
    final List<Map<String, dynamic>> contents = [];

    for (var msg in messages) {
      final role = msg['role'];
      final content = msg['content'] ?? '';

      if (role == 'system') {
        systemPrompt = content;
      } else {
        contents.add({
          "role": role == 'assistant' ? 'model' : 'user',
          "parts": [
            {"text": content}
          ]
        });
      }
    }

    final Map<String, dynamic> requestBody = {
      "contents": contents,
      if (systemPrompt != null)
        "system_instruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 1024,
      }
    };

    final response = await http.post(
      Uri.parse('$_geminiBaseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      try {
        return json['candidates'][0]['content']['parts'][0]['text'] ?? "Pas de réponse.";
      } catch (e) {
        return "Désolé, je n'ai pas pu générer une réponse.";
      }
    } else {
      throw Exception('Erreur Gemini: ${response.statusCode} - ${response.body}');
    }
  }
}
