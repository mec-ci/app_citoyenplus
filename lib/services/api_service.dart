import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/post.dart';
import '../models/signalement.dart';
import '../models/publication.dart';
import '../models/commentaire.dart';
import '../models/message.dart';
import '../models/utilisateur_profile.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Map<String, String> headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // GET ACTUALITE
  static Future<List<PostModel>> fetchPosts(String token) async {
    final response = await AuthService.authorizedGet(Uri.parse('$baseUrl/actualites'));

    final data = jsonDecode(response.body);
    final posts = data is Map<String, dynamic> ? data['data'] : data;

    return (posts as List)
        .map((e) => PostModel.fromJson(e))
        .toList();
  }

  // GET SIGNALEMENTS
  static Future<List<SignalementModel>> fetchSignalements(String token) async {
    final response = await AuthService.authorizedGet(Uri.parse('$baseUrl/signalement-citoyen'));

    final data = jsonDecode(response.body);
    final signalements = data is Map<String, dynamic> ? data['data'] : data;

    return (signalements as List)
        .map((e) => SignalementModel.fromJson(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchLibraryDocuments(String id, String token) async {
    final url = Uri.parse('$baseUrl/librairie/public/$id?sort=created_at&order=desc');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final docs = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (docs as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Erreur lors de la récupération des documents');
  }

  static Future<List<String>> fetchCategories() async {
    final url = Uri.parse('$baseUrl/categories');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final categories = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (categories as List).map((item) => item.toString()).toList();
    }
    throw Exception('Erreur lors de la récupération des catégories');
  }

  static Future<List<Map<String, dynamic>>> fetchQuizCategories(String token) async {
    final url = Uri.parse('$baseUrl/quizz/categories');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final categories = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (categories as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Erreur lors de la récupération des catégories de quizz');
  }

  static Future<List<Map<String, dynamic>>> fetchQuizzes(String token) async {
    final url = Uri.parse('$baseUrl/quizz');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final quizzes = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (quizzes as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Erreur lors de la récupération des quizz');
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications(String token) async {
    final url = Uri.parse('$baseUrl/notifications');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final notifications = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (notifications as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Erreur lors de la récupération des notifications');
  }

  static Future<List<Map<String, dynamic>>> fetchMessages(String token) async {
    final url = Uri.parse('$baseUrl/messages');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final messages = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (messages as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Erreur lors de la récupération des messages');
  }

  // CREER ACTUALITE
  static Future<bool> createPost({
    required String token,
    required String title,
    required String description,
    XFile? image,
  }) async {
    final uri = Uri.parse('$baseUrl/actualites');
    final response = await AuthService.authorizedMultipartRequest(() async {
      final request = http.MultipartRequest('POST', uri)
        ..fields['title'] = title
        ..fields['description'] = description;

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
          );
          request.files.add(multipartFile);
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image.path,
          ));
        }
      }

      return request;
    });

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // CREER SIGNALEMENT
  static Future<bool> createSignalement({
    required String token,
    required String description,
    required String categorieId,
    XFile? image,
  }) async {
    final uri = Uri.parse('$baseUrl/signalement-citoyen');
    final response = await AuthService.authorizedMultipartRequest(() async {
      final request = http.MultipartRequest('POST', uri)
        ..fields['description'] = description
        ..fields['categorieId'] = categorieId;

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
          );
          request.files.add(multipartFile);
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image.path,
          ));
        }
      }

      return request;
    });

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 🔹 Récupérer les signalements
  static Future<List<SignalementModel>> fetchAllSignalements(String token) async {
    final url = Uri.parse('$baseUrl/signalement-citoyen');

    final response = await AuthService.authorizedGet(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => SignalementModel.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement signalements');
    }
  }

  // ===== FEED & SOCIAL FEATURES =====

  /// Fetch paginated feed of publications (actualites + signalements)
  /// [limit] default 10, [cursor] for pagination (datetime ISO string or null for first page)
  static Future<Map<String, dynamic>> fetchPublications({
    String? cursor,
    int limit = 10,
  }) async {
    final params = {
      'type': 'actualite,signalement',
      'sort': 'created_at',
      'order': 'desc',
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final url = Uri.parse('$baseUrl/publications').replace(queryParameters: params);
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final publications = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      final nextCursor = decoded is Map ? decoded['next_cursor'] : null;
      
      return {
        'publications': (publications as List)
            .map((e) => Publication.fromJson(e as Map<String, dynamic>))
            .toList(),
        'nextCursor': nextCursor,
      };
    }
    throw Exception('Erreur lors du chargement du feed');
  }

  /// Fetch subscription-based feed for a user
  static Future<Map<String, dynamic>> fetchSubscriptionFeed({
    String? cursor,
    int limit = 10,
  }) async {
    final params = {
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final url = Uri.parse('$baseUrl/publications/abonnements').replace(queryParameters: params);
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final publications = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      final nextCursor = decoded is Map ? decoded['next_cursor'] : null;
      
      return {
        'publications': (publications as List)
            .map((e) => Publication.fromJson(e as Map<String, dynamic>))
            .toList(),
        'nextCursor': nextCursor,
      };
    }
    throw Exception('Erreur lors du chargement du feed abonnements');
  }

  /// Create a new publication (actualite or signalement)
  static Future<Publication> createPublication({
    required String type, // 'actualite' or 'signalement'
    required String texte,
    String? categorie,
    String? localisation,
    String? statut,
    List<XFile>? images,
  }) async {
    final uri = Uri.parse('$baseUrl/publications');
    
    final response = await AuthService.authorizedMultipartRequest(() async {
      final request = http.MultipartRequest('POST', uri)
        ..fields['type'] = type
        ..fields['texte'] = texte;
      
      if (categorie != null) request.fields['categorie'] = categorie;
      if (localisation != null) request.fields['localisation'] = localisation;
      if (statut != null) request.fields['statut'] = statut;
      
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final image = images[i];
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: image.name,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'images',
              image.path,
            ));
          }
        }
      }
      return request;
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final pubData = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return Publication.fromJson(pubData);
    }
    throw Exception('Erreur lors de la création de la publication');
  }

  // ===== COMMENTS =====

  /// Fetch comments for a publication
  static Future<List<Commentaire>> fetchPublicationComments(String publicationId) async {
    final url = Uri.parse('$baseUrl/publications/$publicationId/commentaires')
        .replace(queryParameters: {'sort': 'created_at', 'order': 'asc'});
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final comments = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (comments as List)
          .map((e) => Commentaire.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors du chargement des commentaires');
  }

  /// Create a comment on a publication
  static Future<Commentaire> createComment({
    required String publicationId,
    required String texte,
  }) async {
    final url = Uri.parse('$baseUrl/publications/$publicationId/commentaires');
    
    final response = await AuthService.authorizedPost(
      url,
      body: jsonEncode({'texte': texte}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final commentData = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return Commentaire.fromJson(commentData);
    }
    throw Exception('Erreur lors de la création du commentaire');
  }

  /// Delete a comment
  static Future<bool> deleteComment(String publicationId, String commentId) async {
    final url = Uri.parse('$baseUrl/publications/$publicationId/commentaires/$commentId');
    
    final response = await AuthService.authorizedDelete(url);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ===== LIKES =====

  /// Toggle like on a publication (POST to like, DELETE to unlike)
  static Future<bool> toggleLike(String publicationId) async {
    final url = Uri.parse('$baseUrl/publications/$publicationId/likes');
    
    // First try to like (POST)
    var response = await AuthService.authorizedPost(url, body: jsonEncode({}));
    
    if (response.statusCode == 409) {
      // Already liked, so unlike (DELETE)
      response = await AuthService.authorizedDelete(url);
    }
    
    return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
  }

  /// Get like count for a publication
  static Future<int> getLikeCount(String publicationId) async {
    final url = Uri.parse('$baseUrl/publications/$publicationId/likes');
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('count')) {
        return decoded['count'] as int;
      }
      if (decoded is List) {
        return decoded.length;
      }
    }
    return 0;
  }

  // ===== USER PROFILES =====

  /// Fetch a user's profile
  static Future<UtilisateurProfile> fetchUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final userData = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return UtilisateurProfile.fromJson(userData);
    }
    throw Exception('Erreur lors du chargement du profil');
  }

  /// Get publications by a specific user
  static Future<List<Publication>> fetchUserPublications(String userId) async {
    final params = {
      'userId': userId,
      'sort': 'created_at',
      'order': 'desc',
    };
    final url = Uri.parse('$baseUrl/publications').replace(queryParameters: params);
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final publications = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (publications as List)
          .map((e) => Publication.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors du chargement des publications');
  }

  // ===== FOLLOW/UNFOLLOW =====

  /// Follow a user
  static Future<bool> followUser(String targetUserId) async {
    final url = Uri.parse('$baseUrl/users/$targetUserId/follow');
    
    final response = await AuthService.authorizedPost(url, body: jsonEncode({}));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String targetUserId) async {
    final url = Uri.parse('$baseUrl/users/$targetUserId/follow');
    
    final response = await AuthService.authorizedDelete(url);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// Get followers list
  static Future<List<UtilisateurProfile>> getFollowers(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/followers');
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final followers = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (followers as List)
          .map((e) => UtilisateurProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors du chargement des abonnés');
  }

  /// Get following list
  static Future<List<UtilisateurProfile>> getFollowing(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/following');
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final following = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (following as List)
          .map((e) => UtilisateurProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors du chargement des abonnements');
  }

  // ===== MESSAGING =====

  /// Get all conversations for current user
  static Future<List<Conversation>> getConversations() async {
    final url = Uri.parse('$baseUrl/messages/conversations');
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final conversations = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (conversations as List)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors du chargement des conversations');
  }

  /// Get messages in a conversation
  static Future<List<Message>> getMessages(String conversationId, {int limit = 30}) async {
    final params = {'limit': limit.toString()};
    final url = Uri.parse('$baseUrl/messages/$conversationId').replace(queryParameters: params);
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final messages = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (messages as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors du chargement des messages');
  }

  /// Send a message in a conversation
  static Future<Message> sendMessage({
    required String conversationId,
    required String texte,
  }) async {
    final url = Uri.parse('$baseUrl/messages/$conversationId');
    
    final response = await AuthService.authorizedPost(
      url,
      body: jsonEncode({'texte': texte}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final messageData = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return Message.fromJson(messageData);
    }
    throw Exception('Erreur lors de l\'envoi du message');
  }

  // ===== SEARCH =====

  /// Search for users and publications
  static Future<Map<String, dynamic>> search(String query) async {
    final params = {
      'q': query,
      'type': 'users,publications',
    };
    final url = Uri.parse('$baseUrl/search').replace(queryParameters: params);
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      
      return {
        'users': (decoded['users'] as List? ?? [])
            .map((e) => UtilisateurProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
        'publications': (decoded['publications'] as List? ?? [])
            .map((e) => Publication.fromJson(e as Map<String, dynamic>))
            .toList(),
      };
    }
    throw Exception('Erreur lors de la recherche');
  }

  // ===== TRENDS =====

  /// Get trending topics/hashtags
  static Future<List<Map<String, dynamic>>> getTrends() async {
    final url = Uri.parse('$baseUrl/trends');
    
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final trends = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (trends as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Erreur lors du chargement des tendances');
  }

  // ===== REPORT/FLAG =====

  /// Report a publication as inappropriate
  static Future<bool> reportPublication({
    required String publicationId,
    required String reason,
    String? details,
  }) async {
    final url = Uri.parse('$baseUrl/publications/$publicationId/report');
    
    final body = {
      'reason': reason,
      if (details != null) 'details': details,
    };
    
    final response = await AuthService.authorizedPost(url, body: jsonEncode(body));
    return response.statusCode == 200 || response.statusCode == 201;
  }
}


