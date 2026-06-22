import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';

/// Un résultat de quiz tel que renvoyé par `GET /quizz/results/:userId`.
class QuizResult {
  final String quizId;
  final String? categorie;
  final int score;
  final int total;
  final DateTime? date;

  const QuizResult({
    required this.quizId,
    this.categorie,
    this.score = 0,
    this.total = 0,
    this.date,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] ?? json['createdAt'] ?? json['created_at'];
    return QuizResult(
      quizId: (json['quizId'] ?? json['quiz_id'] ?? json['id'] ?? '')
          .toString(),
      categorie: json['categorie']?.toString() ??
          json['categorieTitre']?.toString() ??
          json['category']?.toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      date: dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null,
    );
  }
}

/// Service d'accès aux quiz et à la persistance des résultats côté serveur.
class QuizService {
  static final Dio _dio = DioClient.getInstance();

  /// Récupère les résultats/progression d'un utilisateur.
  static Future<List<QuizResult>> fetchResults(String userId) async {
    final response = await _dio.get(ApiEndpoints.quizzResultsByUser(userId));
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => QuizResult.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Convertit une question issue de l'API (format `{text, choices:[{text,
  /// isCorrect}]}`) vers le format consommé par l'écran de quiz
  /// (`{question, options:[...], correct: int}`). Tolérant aux nulls.
  static Map<String, dynamic>? mapApiQuestion(Map<String, dynamic> raw) {
    final text = raw['text']?.toString() ??
        raw['question']?.toString() ??
        raw['intitule']?.toString();
    if (text == null || text.isEmpty) return null;

    final choicesRaw = raw['choices'] ?? raw['options'] ?? raw['reponses'];
    if (choicesRaw is! List || choicesRaw.isEmpty) return null;

    final options = <String>[];
    int correct = 0;
    for (var i = 0; i < choicesRaw.length; i++) {
      final c = choicesRaw[i];
      if (c is Map) {
        options.add(
          (c['text'] ?? c['libelle'] ?? c['label'] ?? '').toString(),
        );
        if (c['isCorrect'] == true || c['correct'] == true) correct = i;
      } else {
        options.add(c.toString());
      }
    }
    if (options.isEmpty) return null;

    return {
      'question': text,
      'options': options,
      'correct': correct,
    };
  }
}
