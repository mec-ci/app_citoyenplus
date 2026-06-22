import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';
import 'error_handler.dart';

class DioClient {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static Dio? _dio;

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(dio, _storage),
      _HttpErrorInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
    ]);

    return dio;
  }

  static Dio getInstance() {
    _dio ??= _createDio();
    return _dio!;
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Rafraîchit les tokens via GET /auth/refresh-token en envoyant le refresh
  /// token dans le header Authorization. Utilise une instance Dio dédiée, sans
  /// l'intercepteur d'auth (qui écraserait le header avec l'access token et
  /// pourrait provoquer une boucle de rafraîchissement).
  static Future<Response?> refreshTokens(String refreshToken) {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
    return refreshDio.get(
      ApiEndpoints.refreshToken,
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
  }

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static void reset() {
    _dio = null;
  }
}

class _HttpErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();
    if ((method == 'GET' || method == 'POST') &&
        response.statusCode != null &&
        response.statusCode != 200 &&
        response.statusCode != 201) {
      final message = _extractMessage(response.data);
      HttpErrorHandler.showErrorAlert(
        'Erreur ${response.statusCode}',
        message,
      );
    }
    handler.next(response);
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'La requête a échoué avec le statut ${data['statusCode'] ?? "inconnu"}.';
    }
    return 'La requête a échoué.';
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._dio, this._storage);

  /// Routes d'authentification publiques : elles ne doivent JAMAIS recevoir le
  /// token stocké (un token périmé fausserait la requête) ni déclencher la
  /// logique de rafraîchissement sur 401 (qui masquerait le vrai message du
  /// serveur, ex. « Code OTP invalide », derrière « Authentication required »).
  static const List<String> _publicAuthPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/verify-email',
    '/auth/resend-email-otp',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  bool _isPublicAuthPath(String path) =>
      _publicAuthPaths.any((p) => path.contains(p));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublicAuthPath(options.path)) {
      handler.next(options);
      return;
    }
    final token = await _storage.read(key: 'accessToken');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // On laisse passer les erreurs des routes d'auth publiques telles quelles
    // (le vrai message du serveur doit remonter à l'écran).
    if (err.response?.statusCode != 401 ||
        _isPublicAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      await DioClient.clearTokens();
      handler.next(err);
      return;
    }

    try {
      final response = await DioClient.refreshTokens(refreshToken);

      final data = response?.data as Map<String, dynamic>?;

      final newAccessToken = data?['token'] as String?;
      if (newAccessToken == null) {
        await DioClient.clearTokens();
        handler.next(err);
        return;
      }

      final newRefreshToken = data?['refreshToken'] as String?;
      await _storage.write(key: 'accessToken', value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: 'refreshToken', value: newRefreshToken);
      }

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await DioClient.clearTokens();
      handler.next(err);
    }
  }
}
