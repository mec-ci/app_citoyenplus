import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

class AuthService {
  static final Dio _dio = DioClient.getInstance();
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'fullname': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        await DioClient.saveTokens(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
        );
      }
      return {'success': true, 'data': data};
    } on DioException catch (e) {
      final message = _extractMessage(e);
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        await DioClient.saveTokens(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
        );
      }
      return {'success': true, 'data': data};
    } on DioException catch (e) {
      final message = _extractMessage(e);
      return {'success': false, 'message': message};
    }
  }

  static Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return false;
    try {
      // Le backend n'expose pas /auth/verify : on valide le token en récupérant
      // le profil de l'utilisateur authentifié.
      await _dio.get(ApiEndpoints.usersDetail);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;
    try {
      // Le backend lit le refresh token dans le header Authorization (GET).
      final response = await DioClient.refreshTokens(refreshToken);
      final data = response?.data as Map<String, dynamic>?;
      if (data != null && data['token'] != null) {
        await DioClient.saveTokens(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'success': true,
        'message': data['message'] ?? 'Un email de réinitialisation a été envoyé.',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractMessage(e)};
    }
  }

  static Future<void> logout() async {
    // L'authentification est sans état (JWT) côté backend : la déconnexion
    // consiste simplement à effacer les tokens stockés localement.
    await DioClient.clearTokens();
    DioClient.reset();
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {'email': email, 'otp': otp, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'success': true,
        'message': data['message'] ?? 'Mot de passe réinitialisé avec succès.',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _extractMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> verifyRefreshToken({
    required String refreshToken,
  }) async {
    try {
      // Le backend lit le refresh token dans le header Authorization (GET).
      final response = await DioClient.refreshTokens(refreshToken);
      final data = response?.data as Map<String, dynamic>? ?? {};
      if (data['token'] != null) {
        await DioClient.saveTokens(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
        );
      }
      return {'success': true, 'data': data};
    } on DioException catch (e) {
      return {'success': false, 'message': _extractMessage(e)};
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static String _extractMessage(DioException e) {
    final response = e.response;
    if (response?.data is Map) {
      final data = response!.data as Map;
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'Une erreur est survenue.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    }
    return 'Une erreur est survenue.';
  }
}
