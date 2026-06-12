import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static const String baseUrl = ApiConfig.baseUrl;
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // INSCRIPTION
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "fullname": name,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      );

      if (!response.headers['content-type']!.contains('application/json')) {
        return {"success": false, "message": "Réponse invalide du serveur"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sauvegarde du token si existant
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        if (data['refreshToken'] != null) {
          await saveRefreshToken(data['refreshToken']);
        }

        return {"success": true, "data": data};
      } else {
        dynamic message = data["message"];

        // Si le message est une liste, on prend le premier élément
        if (message is List && message.isNotEmpty) {
          message = message.join("\n");
        }

        // Si ce n'est pas une String
        if (message is! String) {
          message = "Erreur lors de l'inscription";
        }

        return {"success": false, "message": message};
      }
    } catch (_) {
      return {
        "success": false,
        "message": "Erreur réseau, réessaie encore 🙏🏾",
      };
    }
  }

  // CONNEXION
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        if (data['refreshToken'] != null) {
          await saveRefreshToken(data['refreshToken']);
        }
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Email ou mot de passe incorrect",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Impossible de se connecter"};
    }
  }

  // 🔑 MÉTHODES DE GESTION DU TOKEN
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  static Future<Map<String, String>> _authHeaders([Map<String, String>? extra]) async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  static Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function() requestFactory,
  ) async {
    var response = await requestFactory();
    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await requestFactory();
      }
    }
    return response;
  }

  static Future<http.Response> authorizedGet(
    Uri url, {
    Map<String, String>? extraHeaders,
  }) async {
    return _authenticatedRequest(() async {
      return http.get(url, headers: await _authHeaders(extraHeaders));
    });
  }

  static Future<http.Response> authorizedPost(
    Uri url, {
    Map<String, String>? extraHeaders,
    Object? body,
    Encoding? encoding,
  }) async {
    return _authenticatedRequest(() async {
      return http.post(
        url,
        headers: await _authHeaders(extraHeaders),
        body: body,
        encoding: encoding,
      );
    });
  }

  static Future<http.Response> authorizedPatch(
    Uri url, {
    Map<String, String>? extraHeaders,
    Object? body,
    Encoding? encoding,
  }) async {
    return _authenticatedRequest(() async {
      return http.patch(
        url,
        headers: await _authHeaders(extraHeaders),
        body: body,
        encoding: encoding,
      );
    });
  }

  static Future<http.Response> authorizedPut(
    Uri url, {
    Map<String, String>? extraHeaders,
    Object? body,
    Encoding? encoding,
  }) async {
    return _authenticatedRequest(() async {
      return http.put(
        url,
        headers: await _authHeaders(extraHeaders),
        body: body,
        encoding: encoding,
      );
    });
  }

  static Future<http.Response> authorizedDelete(
    Uri url, {
    Map<String, String>? extraHeaders,
  }) async {
    return _authenticatedRequest(() async {
      return http.delete(url, headers: await _authHeaders(extraHeaders));
    });
  }

  static Future<http.Response> authorizedMultipartRequest(
    Future<http.MultipartRequest> Function() requestFactory,
  ) async {
    http.MultipartRequest request = await requestFactory();
    request.headers.addAll(await _authHeaders());
    var streamed = await request.send();
    if (streamed.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        request = await requestFactory();
        request.headers.addAll(await _authHeaders());
        streamed = await request.send();
      }
    }
    return await http.Response.fromStream(streamed);
  }

  static Future<bool> verifyToken() async {
    final token = await getToken();
    if (token == null) return false;
    final url = Uri.parse('$baseUrl/auth/verify');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> isAuthenticated() async {
    final valid = await verifyToken();
    if (valid) return true;
    return await refreshToken();
  }

  static Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    final urls = [
      Uri.parse('$baseUrl/auth/refresh'),
      Uri.parse('$baseUrl/auth/refresh-token'),
    ];

    for (final url in urls) {
      try {
        final response = url.path.endsWith('refresh-token')
            ? await http.get(
                url,
                headers: {
                  'Authorization': 'Bearer ${await getToken() ?? ''}',
                  'Accept': 'application/json',
                },
              )
            : await http.post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonEncode({'refreshToken': refreshToken}),
              );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['token'] != null) {
            await saveToken(data['token']);
          }
          if (data['refreshToken'] != null) {
            await saveRefreshToken(data['refreshToken']);
          }
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final account = await googleSignIn.signIn();
    if (account == null) {
      return {'success': false, 'message': 'Connexion Google annulée'};
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null || accessToken == null) {
      return {'success': false, 'message': 'Impossible de récupérer les jetons Google'};
    }

    final url = Uri.parse('$baseUrl/auth/google');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        if (data['refreshToken'] != null) {
          await saveRefreshToken(data['refreshToken']);
        }
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur de connexion Google',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau Google'};
    }
  }

  // MOT DE PASSE OUBLIÉ
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse("$baseUrl/auth/forgot-password");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email}),
      );

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {"success": false, "message": "Réponse invalide du serveur"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": data["message"] ?? "Un email de réinitialisation a été envoyé.",
        };
      } else {
        dynamic message = data["message"];
        if (message is List && message.isNotEmpty) message = message.join("\n");
        if (message is! String) message = "Une erreur est survenue. Réessaie.";
        return {"success": false, "message": message};
      }
    } catch (_) {
      return {"success": false, "message": "Erreur réseau, réessaie encore 🙏🏾"};
    }
  }

  static Future<void> logout() async {
    final url = Uri.parse('$baseUrl/auth/logout');
    try {
      await http.post(
        url,
        headers: await _authHeaders({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
    } catch (_) {}
    await clearTokens();
  }
}
