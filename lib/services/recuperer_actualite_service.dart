import 'package:dio/dio.dart';
import 'package:citoyen_plus/models/post.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

class RecupererActualiteService {
  static final Dio _dio = DioClient.getInstance();

  static Future<List<PostModel>> fetchAllPosts() async {
    final response = await _dio.get(ApiEndpoints.actualites);
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
