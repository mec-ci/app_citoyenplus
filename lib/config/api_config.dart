import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String baseUrl = 'https://admin.mec-ci.org/api/v1';
  static const String host = 'https://admin.mec-ci.org';
  static String get geminiApiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      // dotenv non initialisé (fichier .env absent du build) : pas de clé.
      return '';
    }
  }
}
