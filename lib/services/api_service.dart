import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/post.dart';
import '../models/signalement.dart';
import '../models/quiz.dart';
import 'user_service.dart';

class ApiService {
  static final Dio _dio = DioClient.getInstance();

  static const String _pendingQuizKey = 'pending_quiz_results';

  /// Renvoie au serveur les résultats de quiz mis en file d'attente hors-ligne
  /// (`pending_quiz_results`). Les entrées envoyées avec succès sont retirées ;
  /// celles qui échouent restent en file pour une prochaine tentative.
  /// Renvoie le nombre d'entrées effectivement synchronisées.
  static Future<int> flushPendingQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pendingQuizKey) ?? const <String>[];
    if (list.isEmpty) return 0;

    final remaining = <String>[];
    var synced = 0;
    for (final raw in list) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final quizId = data['quizId']?.toString();
        final answers = (data['answers'] as List?)
                ?.map((e) => (e as Map).cast<String, dynamic>())
                .toList() ??
            const <Map<String, dynamic>>[];
        final userId =
            data['userId']?.toString() ?? await UserService.currentUserId();

        if (quizId == null || quizId.isEmpty || userId == null || answers.isEmpty) {
          remaining.add(raw); // entrée inexploitable, on la conserve
          continue;
        }

        final result = await postQuizResult(
          userId: userId,
          quizId: quizId,
          answers: answers,
        );
        if (result == null) {
          remaining.add(raw); // échec → on réessaiera plus tard
        } else {
          synced++;
        }
      } catch (_) {
        remaining.add(raw); // erreur réseau → conservé
      }
    }

    await prefs.setStringList(_pendingQuizKey, remaining);
    return synced;
  }

  // ── Points ─────────────────────────────────────────────────────────────────
  static Future<bool> syncPoints(int amount) async {
    try {
      final response = await _dio.post('/users/points', data: {
        'points': amount,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Quiz – Résultat ────────────────────────────────────────────────────────
  /// Soumet le résultat d'un quiz au backend (`POST /quizz/submit`).
  ///
  /// Forme attendue par le backend (aucune modification serveur) :
  /// `{ userId, quizId, answers: [{ questionId, choiceId }] }`.
  /// Le `userId` provient de l'utilisateur connecté (côté mobile).
  /// Renvoie la réponse serveur (`{ userQuiz, score, correctCount,
  /// totalQuestions, percentage }`) en cas de succès, ou `null` si l'appel
  /// n'aboutit pas (le statut HTTP n'est pas 200/201). Les erreurs réseau
  /// (DioException) sont propagées à l'appelant pour le repli hors-ligne.
  static Future<Map<String, dynamic>?> postQuizResult({
    required String userId,
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _dio.post(ApiEndpoints.quizzSubmit, data: {
      'userId': userId,
      'quizId': quizId,
      'answers': answers,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Certaines réponses sont enveloppées dans une clé `data`.
        final inner = data['data'];
        if (inner is Map<String, dynamic>) return inner;
        return data;
      }
      return <String, dynamic>{};
    }
    return null;
  }

  /// Récupère les résultats de quiz d'un utilisateur (`GET /quizz/results/:userId`).
  static Future<List<Map<String, dynamic>>> fetchQuizResults(
    String userId,
  ) async {
    final response = await _dio.get(ApiEndpoints.quizzResultsByUser(userId));
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List).map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<PostModel>> fetchPosts({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.actualites,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère une actualité complète (avec son `content`) par son identifiant
  /// via `GET /actualites/:id`.
  static Future<PostModel> fetchPostById(String id) async {
    final response = await _dio.get(ApiEndpoints.actualiteById(id));
    final data = response.data;
    final item = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return PostModel.fromJson((item as Map).cast<String, dynamic>());
  }

  static Future<List<SignalementModel>> fetchSignalements({
    int page = 1,
    int limit = 20,
    String? citoyenId,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (citoyenId != null) query['citoyenId'] = citoyenId;
    // Recherche « autour de moi » : envoyée au backend (filtre par rayon + tri
    // par distance) lorsque coordonnées et rayon sont fournis.
    if (latitude != null && longitude != null && radiusKm != null) {
      query['latitude'] = latitude;
      query['longitude'] = longitude;
      query['radiusKm'] = radiusKm;
    }

    final response = await _dio.get(
      ApiEndpoints.signalementCitoyen,
      queryParameters: query,
    );
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((e) => SignalementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchLibraryDocuments(
    String? title, {
    String? categorie,
  }) async {
    final query = <String, dynamic>{};
    if (title != null) query['title'] = title;
    if (categorie != null) query['categorie'] = categorie;

    final response = await _dio.get(
      ApiEndpoints.librairiePublic,
      queryParameters: query,
    );
    final data = response.data;
    final docs = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (docs as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  /// Récupère la liste des catégories de documents de la librairie.
  static Future<List<String>> fetchLibraryCategories() async {
    final response = await _dio.get(ApiEndpoints.librairieCategories);
    final data = response.data;
    final list = data is Map<String, dynamic> ? data['data'] ?? data : data;
    if (list is! List) return const [];
    return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  /// Charge les catégories de quiz depuis l'API (`GET /quizz/categories`).
  /// Forme réelle : `[{ id, nom, _count: { quizzes } }]`. Les erreurs réseau
  /// sont propagées à l'appelant (qui gère le repli/`catchError`).
  static Future<List<Map<String, dynamic>>> fetchQuizCategories() async {
    final response = await _dio.get(ApiEndpoints.quizzCategories);
    final data = response.data;
    final categories =
        data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (categories as List)
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList();
  }

  /// Charge tous les quiz depuis l'API (`GET /quizz?page=…&limit=…`) et les
  /// parse en modèles [ApiQuiz] (avec de VRAIS identifiants : quiz, questions,
  /// choix). Pagine jusqu'à récupérer l'ensemble des quiz (`meta.totalPages`).
  ///
  /// Aucun repli mock ici : une erreur réseau (DioException) est PROPAGÉE à
  /// l'appelant, qui décide du repli hors-ligne (banque de questions locale).
  static Future<List<ApiQuiz>> fetchQuizzes({int limit = 50}) async {
    final List<ApiQuiz> all = [];
    int page = 1;
    int totalPages = 1;
    do {
      final response = await _dio.get(
        ApiEndpoints.quizz,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      final List items;
      if (data is Map<String, dynamic>) {
        items = (data['data'] ?? data['items'] ?? const []) as List;
        final meta = data['meta'];
        if (meta is Map && meta['totalPages'] != null) {
          totalPages = int.tryParse(meta['totalPages'].toString()) ?? 1;
        }
      } else {
        items = data as List;
      }
      all.addAll(
        items.map((e) => ApiQuiz.fromJson((e as Map).cast<String, dynamic>())),
      );
      page++;
    } while (page <= totalPages);
    return all;
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await _dio.get('/notifications');
    final data = response.data;
    final notifications = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (notifications as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  static Future<bool> createPost({
    required String title,
    required String description,
    required String excerpt,
    XFile? image,
  }) async {
    if (image != null) {
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'excerpt': excerpt,
        'imageUrl': await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      });
      final response = await _dio.post(
        ApiEndpoints.actualites,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    }

    final response = await _dio.post(ApiEndpoints.actualites, data: {
      'title': title,
      'description': description,
      'excerpt': excerpt,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _dio.get('/conversations');
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  static Future<bool> sendMessage({
    required String conversationId,
    required String texte,
  }) async {
    final response = await _dio.post(
      '/conversations/$conversationId/messages',
      data: {'texte': texte},
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> search(String query) async {
    final response =
        await _dio.get('/search', queryParameters: {'q': query});
    return response.data as Map<String, dynamic>;
  }

  static Future<bool> createSignalement({
    required String titre,
    required String description,
    required String categorieId,
    required String adresse,
    required double latitude,
    required double longitude,
    XFile? image,
  }) async {
    if (image != null) {
      final formData = FormData.fromMap({
        'titre': titre,
        'description': description,
        'categorieId': categorieId,
        'adresse': adresse,
        'latitude': latitude,
        'longitude': longitude,
        'photo': await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      });
      final response = await _dio.post(
        ApiEndpoints.signalementCitoyen,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    }

    final response = await _dio.post(ApiEndpoints.signalementCitoyen, data: {
      'titre': titre,
      'description': description,
      'categorieId': categorieId,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }
}
