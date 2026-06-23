import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiChatService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  static String? _apiKey;
  static const String _model = 'gpt-oss-120b';
  static const String _baseUrl = 'https://api.cerebras.ai/v1/chat/completions';

  static void init() {
    _apiKey = dotenv.env['CEREBRAS_API_KEY']?.trim();

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('AiChatService: [ERREUR] Aucune clé CEREBRAS_API_KEY dans le .env');
    } else {
      debugPrint('AiChatService: Service Cerebras prêt avec le modèle $_model');
    }
  }

  static Future<String> sendMessage(List<Map<String, String>> messages) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Clé API Cerebras manquante dans le fichier .env');
    }

    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
        },
      );

      final data = response.data;
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        return data['choices'][0]['message']['content'].toString().trim();
      }
      return 'L\'IA a renvoyé une réponse vide.';
    } on DioException catch (e) {
      debugPrint('--- ERREUR CEREBRAS (DEBUG) ---');
      debugPrint('Type: ${e.type}');
      debugPrint('Message brut: ${e.message}');
      debugPrint('Erreur sous-jacente: ${e.error}');
      debugPrint('StatusCode: ${e.response?.statusCode}');
      debugPrint('ResponseData: ${e.response?.data}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Clé Cerebras invalide ou expirée. Vérifiez votre tableau de bord console.cerebras.ai.');
      }

      throw Exception('Erreur API Cerebras : ${e.message}');
    }
  }
}