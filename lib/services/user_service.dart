import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/post.dart';
import '../models/signalement.dart';

class UserService {
  static final Dio _dio = DioClient.getInstance();

  static Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get(ApiEndpoints.usersDetail);
    return response.data as Map<String, dynamic>;
  }

  /// Récupère l'identifiant de l'utilisateur connecté depuis le profil serveur.
  /// Renvoie null en cas d'échec réseau ou si l'id est introuvable.
  static Future<String?> currentUserId() async {
    try {
      final data = await fetchProfile();
      final user = (data['data'] ?? data);
      if (user is Map) {
        final id = user['id'] ?? user['_id'] ?? user['userId'];
        final str = id?.toString();
        if (str != null && str.isNotEmpty) return str;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchProfileById(String userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data as Map<String, dynamic>;
  }

  static Future<List<PostModel>> fetchUserActualites(String userId) async {
    final response = await _dio.get('${ApiEndpoints.actualites}/$userId');
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SignalementModel>> fetchUserSignalements(String userId) async {
    final response = await _dio.get(
      ApiEndpoints.signalementCitoyen,
      queryParameters: {'citoyenId': userId},
    );
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => SignalementModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{'fullname': name};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await _dio.patch(ApiEndpoints.usersDetail, data: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<String?> uploadAvatar(XFile photo) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        photo.path,
        filename: photo.name,
      ),
    });

    final response = await _dio.post(
      ApiEndpoints.usersAvatar,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      return data['avatarUrl'] as String?;
    }
    return null;
  }

  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _dio.put(ApiEndpoints.changePassword, data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> fetchSessions() async {
    final response = await _dio.get(ApiEndpoints.sessions);
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }
}
