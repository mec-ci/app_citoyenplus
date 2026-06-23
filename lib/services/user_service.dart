import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/error_handler.dart';
import '../models/post.dart';
import '../models/signalement.dart';

class UserService {
  static final Dio _dio = DioClient.getInstance();

  /// Construit une URL absolue à partir d'un chemin renvoyé par l'API.
  /// Le backend stocke les médias (avatars, photos) sous forme de chemin
  /// relatif (ex: `uploads/users-avatar/xxx.jpg`). On le préfixe par l'hôte de
  /// l'API, comme c'est déjà le cas pour les photos de signalement.
  static String? absoluteMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path : '/$path';
    return '${ApiEndpoints.apiBaseUrl}$clean';
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get(ApiEndpoints.usersDetail);
    return response.data as Map<String, dynamic>;
  }

  /// Récupère l'identifiant de l'utilisateur connecté à partir de son profil.
  /// Le backend déduit l'utilisateur du token ; on récupère son id pour le
  /// passer explicitement dans le body de soumission des quiz.
  static Future<String?> currentUserId() async {
    try {
      final data = await fetchProfile();
      final user = data['data'] is Map
          ? (data['data'] as Map).cast<String, dynamic>()
          : data;
      final id = user['id'] ?? user['_id'] ?? user['uid'];
      final value = id?.toString();
      return (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchProfileById(String userId) async {
    final response = await _dio.get('/users/$userId/profile');
    return response.data as Map<String, dynamic>;
  }

  /// Récupère les actualités présentes en base (liste paginée publique).
  static Future<List<PostModel>> fetchUserActualites(String userId) async {
    final response = await _dio.get(ApiEndpoints.actualites);
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les signalements d'un citoyen donné via la route dédiée
  /// `GET /signalement-citoyen/utilisateur/:citoyenId`, qui ne renvoie que les
  /// signalements de cet utilisateur (et non l'ensemble du flux public).
  static Future<List<SignalementModel>> fetchUserSignalements(String userId) async {
    final response = await _dio.get(
      ApiEndpoints.signalementCitoyenByUser(userId),
    );
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((item) => SignalementModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Met à jour le profil de l'utilisateur authentifié via PATCH /users
  /// (multipart/form-data). Le backend ne gère que fullname / email / phone.
  static Future<bool> updateProfile({
    required String name,
    String? email,
    String? phone,
  }) async {
    final fields = <String, dynamic>{'fullname': name};
    if (email != null) fields['email'] = email;
    if (phone != null) fields['phone'] = phone;

    final response = await _dio.patch(
      ApiEndpoints.usersUpdate,
      data: FormData.fromMap(fields),
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Téléverse l'avatar via PATCH /users (champ `image`). Renvoie l'URL/chemin
  /// de l'avatar retourné par le backend (champ `avatar`).
  static Future<String?> uploadAvatar(XFile photo) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        photo.path,
        filename: photo.name,
      ),
    });

    final response = await _dio.patch(
      ApiEndpoints.usersUpdate,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      final raw = (data['avatar'] ?? data['avatarUrl']) as String?;
      return absoluteMediaUrl(raw);
    }
    return null;
  }

  /// Change le mot de passe via PATCH /users/password.
  /// Le backend attend `oldPassword`, `password` et `confirmPassword`.
  /// En cas d'erreur HTTP (ex. 400), le message renvoyé par le serveur est
  /// propagé via une [Exception] afin que l'écran puisse l'afficher.
  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.patch(ApiEndpoints.usersPassword, data: {
        'oldPassword': oldPassword,
        'password': newPassword,
        'confirmPassword': newPassword,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(HttpErrorHandler.extractErrorMessage(e));
    }
  }
}
