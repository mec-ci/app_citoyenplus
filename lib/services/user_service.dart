import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/post.dart';
import '../models/signalement.dart';

class UserService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    final url = Uri.parse('$baseUrl/users/detail');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur lors de la récupération du profil');
  }

  static Future<Map<String, dynamic>> fetchProfileById(String userId, String token) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur lors de la récupération du profil utilisateur');
  }

  static Future<List<PostModel>> fetchUserActualites(String userId, String token) async {
    final url = Uri.parse('$baseUrl/actualites/$userId');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final postsJson = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (postsJson as List)
          .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors de la récupération des actualités utilisateur');
  }

  static Future<List<SignalementModel>> fetchUserSignalements(String userId, String token) async {
    final url = Uri.parse('$baseUrl/signalement-citoyen/$userId');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final signalementsJson = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (signalementsJson as List)
          .map((item) => SignalementModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur lors de la récupération des signalements utilisateur');
  }

  static Future<bool> updateProfile({
    required String token,
    required String name,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) async {
    final url = Uri.parse('$baseUrl/users');
    final body = <String, dynamic>{'fullname': name};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await AuthService.authorizedPatch(
      url,
      extraHeaders: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<String?> uploadAvatar(String token, XFile photo) async {
    final url = Uri.parse('$baseUrl/users/avatar');
    final response = await AuthService.authorizedMultipartRequest(() async {
      final request = http.MultipartRequest('POST', url);
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: photo.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('avatar', photo.path));
      }
      return request;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['avatarUrl'] as String?;
    }
    return null;
  }

  static Future<bool> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/change-password');
    final response = await AuthService.authorizedPut(
      url,
      extraHeaders: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> fetchSessions(String userId, String token) async {
    final url = Uri.parse('$baseUrl/auth/sessions?userId=$userId');
    final response = await AuthService.authorizedGet(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final sessionsJson = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      return (sessionsJson as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    return [];
  }
}
