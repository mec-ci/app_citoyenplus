import 'dart:convert';
import 'package:citoyen_plus/models/post.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class RecupererActualiteService {
  static Future<List<PostModel>> fetchAllPosts(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/actualites');
    final response = await AuthService.authorizedGet(url);

    //print('📥 POSTS STATUS : ${response.statusCode}');
    //print('📥 POSTS BODY   : ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsJson = jsonResponse['data'];
      return postsJson.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des posts: ${response.body}');
    }
  }
}