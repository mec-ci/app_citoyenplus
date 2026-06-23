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
  static const String _model = 'deepseek-chat';
  static const String _baseUrl = 'https://api.deepseek.com';

  static void init() {
    String? envKey;
    try {
      envKey = dotenv.env['DEEPSEEK_API_KEY'];
    } catch (_) {
      // dotenv non initialisé (fichier .env absent du build).
      envKey = null;
    }
    _apiKey = (envKey == null || envKey.isEmpty)
        ? 'sk-f72bd6d7b6224e3cba7ecbeea84575ae'
        : envKey;
    debugPrint('AiChatService: DeepSeek API key loaded = ${_apiKey != null && _apiKey!.isNotEmpty}');
  }

  static Future<String> sendMessage(List<Map<String, String>> messages) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Clé API DeepSeek non configurée.');
    }

    String? systemMessage;
    final chatMessages = <Map<String, dynamic>>[];
    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemMessage = msg['content'] ?? '';
        continue;
      }
      chatMessages.add({
        'role': msg['role'] ?? 'user',
        'content': msg['content'] ?? '',
      });
    }

    final requestBody = <String, dynamic>{
      'model': _model,
      'messages': [
        if (systemMessage != null && systemMessage.isNotEmpty)
          {'role': 'system', 'content': systemMessage},
        ...chatMessages,
      ],
      'stream': false,
    };

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: requestBody,
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        if (message != null) {
          return message['content']?.toString() ?? 'Pas de réponse.';
        }
      }
      return 'Pas de réponse.';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      String errorDetail;
      if (responseData is Map) {
        final error = responseData['error'] as Map?;
        if (error != null) {
          errorDetail = error['message']?.toString() ?? jsonEncode(responseData);
        } else {
          errorDetail = jsonEncode(responseData);
        }
      } else {
        errorDetail = responseData?.toString() ?? e.message ?? 'Erreur inconnue';
      }
      debugPrint('DeepSeek error [$statusCode]: $errorDetail');
      throw Exception(errorDetail);
    }
  }
}
