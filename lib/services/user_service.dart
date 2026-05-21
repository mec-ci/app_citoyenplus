import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'https://admin.mec-ci.org/api/v1';

  // Récupérer le profil
  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    final url = Uri.parse('$baseUrl/users/detail');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération du profil');
    }
  }

  // Mettre à jour le profil
  static Future<bool> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
  }) async {
    final url = Uri.parse('$baseUrl/users');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"fullname": name, "email": email, "phone": phone}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
