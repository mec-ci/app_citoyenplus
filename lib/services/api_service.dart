import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/post.dart';
import '../models/signalement.dart';

class ApiService {
  static final Dio _dio = DioClient.getInstance();

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
  static Future<bool> postQuizResult({
    required String userId,
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _dio.post(ApiEndpoints.quizzSubmit, data: {
      'userId': userId,
      'quizId': quizId,
      'answers': answers,
    });
    return response.statusCode == 200 || response.statusCode == 201;
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

  static Future<List<SignalementModel>> fetchSignalements({
    int page = 1,
    int limit = 20,
    String? citoyenId,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (citoyenId != null) query['citoyenId'] = citoyenId;

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
    String? title,
  ) async {
    final query = <String, dynamic>{};
    if (title != null) query['title'] = title;

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

  /// Charge les catégories de quiz depuis l'API (`GET /quizz/categories`).
  /// En cas d'indisponibilité réseau (hors-ligne), repli EXPLICITE sur les
  /// données mock locales pour ne pas bloquer l'utilisateur.
  static Future<List<Map<String, dynamic>>> fetchQuizCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.quizzCategories);
      final data = response.data;
      final categories = data is Map<String, dynamic> ? data['data'] ?? data : data;
      return (categories as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on DioException {
      // Fallback offline explicite : données mock locales.
      return _mockQuizCategories;
    }
  }

  /// Charge les quiz depuis l'API (`GET /quizz`).
  /// Repli EXPLICITE sur le mock local en cas d'erreur réseau (offline).
  static Future<List<Map<String, dynamic>>> fetchQuizzes() async {
    try {
      final response = await _dio.get(ApiEndpoints.quizz);
      final data = response.data;
      final quizzes = data is Map<String, dynamic> ? data['data'] ?? data : data;
      return (quizzes as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on DioException {
      // Fallback offline explicite : données mock locales.
      return _mockQuizzes;
    }
  }

  // ── MOCK DATA ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get _mockQuizCategories => [
    {
      'id': 'mock_cat_1',
      'titre': 'Constitution',
      'description': 'Testez vos connaissances sur la Constitution ivoirienne',
      'totalXp': 100,
    },
    {
      'id': 'mock_cat_2',
      'titre': 'Institutions',
      'description': 'Les institutions de la République de Côte d\'Ivoire',
      'totalXp': 80,
    },
    {
      'id': 'mock_cat_3',
      'titre': 'Histoire',
      'description': 'L\'histoire de la Côte d\'Ivoire',
      'totalXp': 100,
    },
  ];

  static List<Map<String, dynamic>> get _mockQuizzes => [
    {
      'id': 'mock_quiz_1',
      'title': 'Quiz Constitution',
      'description': 'Testez vos connaissances sur la Constitution',
      'difficulte': 'FACILE',
      'categorieId': 'mock_cat_1',
      'questions': [
        {
          'text': 'En quelle année la Constitution ivoirienne actuelle a-t-elle été adoptée ?',
          'choices': [
            {'text': '2000', 'isCorrect': false},
            {'text': '2016', 'isCorrect': true},
            {'text': '2010', 'isCorrect': false},
            {'text': '1999', 'isCorrect': false},
          ],
        },
        {
          'text': 'Quel est le rôle du Conseil Constitutionnel ?',
          'choices': [
            {'text': 'Organiser les élections', 'isCorrect': false},
            {'text': 'Veiller au respect de la Constitution', 'isCorrect': true},
            {'text': 'Juger les criminels', 'isCorrect': false},
            {'text': 'Préparer les lois', 'isCorrect': false},
          ],
        },
        {
          'text': 'Combien de titres comporte la Constitution de 2016 ?',
          'choices': [
            {'text': '12', 'isCorrect': false},
            {'text': '14', 'isCorrect': true},
            {'text': '10', 'isCorrect': false},
            {'text': '16', 'isCorrect': false},
          ],
        },
        {
          'text': 'Qui est le garant de l\'indépendance de la justice ?',
          'choices': [
            {'text': 'Le Premier ministre', 'isCorrect': false},
            {'text': 'Le Président de la République', 'isCorrect': true},
            {'text': 'Le Conseil supérieur de la magistrature', 'isCorrect': false},
            {'text': 'Le Garde des Sceaux', 'isCorrect': false},
          ],
        },
        {
          'text': 'La Constitution ivoirienne consacre le principe de :',
          'choices': [
            {'text': 'La monarchie', 'isCorrect': false},
            {'text': 'La dictature', 'isCorrect': false},
            {'text': 'La séparation des pouvoirs', 'isCorrect': true},
            {'text': 'Le pouvoir absolu', 'isCorrect': false},
          ],
        },
      ],
    },
    {
      'id': 'mock_quiz_2',
      'title': 'Quiz Institutions',
      'description': 'Connaissez-vous les institutions ivoiriennes ?',
      'difficulte': 'MOYEN',
      'categorieId': 'mock_cat_2',
      'questions': [
        {
          'text': 'Quel est le rôle de l\'Assemblée Nationale ?',
          'choices': [
            {'text': 'Faire les lois', 'isCorrect': true},
            {'text': 'Juger les citoyens', 'isCorrect': false},
            {'text': 'Organiser les élections', 'isCorrect': false},
            {'text': 'Défendre le pays', 'isCorrect': false},
          ],
        },
        {
          'text': 'Qui nomme le Premier ministre en Côte d\'Ivoire ?',
          'choices': [
            {'text': 'Le Sénat', 'isCorrect': false},
            {'text': 'Le Président de la République', 'isCorrect': true},
            {'text': 'L\'Assemblée Nationale', 'isCorrect': false},
            {'text': 'Le peuple', 'isCorrect': false},
          ],
        },
        {
          'text': 'Combien y a-t-il de pouvoirs dans l\'État ivoirien ?',
          'choices': [
            {'text': '2', 'isCorrect': false},
            {'text': '3', 'isCorrect': true},
            {'text': '4', 'isCorrect': false},
            {'text': '5', 'isCorrect': false},
          ],
        },
        {
          'text': 'Quel est le mandat du Président de la République ?',
          'choices': [
            {'text': '4 ans', 'isCorrect': false},
            {'text': '5 ans', 'isCorrect': true},
            {'text': '6 ans', 'isCorrect': false},
            {'text': '7 ans', 'isCorrect': false},
          ],
        },
        {
          'text': 'Quelle institution contrôle les finances publiques ?',
          'choices': [
            {'text': 'La Cour suprême', 'isCorrect': false},
            {'text': 'La Cour des comptes', 'isCorrect': true},
            {'text': 'Le Sénat', 'isCorrect': false},
            {'text': 'La BCEAO', 'isCorrect': false},
          ],
        },
      ],
    },
    {
      'id': 'mock_quiz_3',
      'title': 'Quiz Histoire',
      'description': 'Testez votre connaissance de l\'histoire ivoirienne',
      'difficulte': 'FACILE',
      'categorieId': 'mock_cat_3',
      'questions': [
        {
          'text': 'En quelle année la Côte d\'Ivoire a-t-elle obtenu son indépendance ?',
          'choices': [
            {'text': '1958', 'isCorrect': false},
            {'text': '1960', 'isCorrect': true},
            {'text': '1962', 'isCorrect': false},
            {'text': '1970', 'isCorrect': false},
          ],
        },
        {
          'text': 'Qui fut le premier président de la Côte d\'Ivoire ?',
          'choices': [
            {'text': 'Alassane Ouattara', 'isCorrect': false},
            {'text': 'Laurent Gbagbo', 'isCorrect': false},
            {'text': 'Félix Houphouët-Boigny', 'isCorrect': true},
            {'text': 'Henri Konan Bédié', 'isCorrect': false},
          ],
        },
        {
          'text': 'Quelle est la devise nationale de la Côte d\'Ivoire ?',
          'choices': [
            {'text': 'Travail – Famille – Patrie', 'isCorrect': false},
            {'text': 'Union – Discipline – Travail', 'isCorrect': false},
            {'text': 'Paix – Unité – Progrès', 'isCorrect': true},
            {'text': 'Liberté – Égalité – Fraternité', 'isCorrect': false},
          ],
        },
        {
          'text': 'Quel événement majeur a eu lieu en Côte d\'Ivoire en 1999 ?',
          'choices': [
            {'text': 'L\'indépendance', 'isCorrect': false},
            {'text': 'Le premier coup d\'État', 'isCorrect': true},
            {'text': 'L\'élection présidentielle', 'isCorrect': false},
            {'text': 'La CAN', 'isCorrect': false},
          ],
        },
        {
          'text': 'Quel surnom donne-t-on à Abidjan ?',
          'choices': [
            {'text': 'La ville lumière', 'isCorrect': false},
            {'text': 'La perle des lagunes', 'isCorrect': true},
            {'text': 'La capitale culturelle', 'isCorrect': false},
            {'text': 'La cité du cacao', 'isCorrect': false},
          ],
        },
      ],
    },
  ];

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
