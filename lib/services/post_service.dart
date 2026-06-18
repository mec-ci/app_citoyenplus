import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/post.dart';

Future<PostModel> createArticle(
  String title,
  String content, {
  required DateTime date,
  required String excerpt,
  XFile? image,
}) async {
  final dio = DioClient.getInstance();

  PostModel parseResponse(dynamic responseData) {
    final data = responseData;
    final item = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return PostModel.fromJson(item as Map<String, dynamic>);
  }

  if (image != null) {
    final formData = FormData.fromMap({
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'date': date.toIso8601String(),
      'imageUrl': await MultipartFile.fromFile(
        image.path,
        filename: image.name,
      ),
    });

    final response = await dio.post(
      ApiEndpoints.actualites,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return parseResponse(response.data);
  }

  final response = await dio.post(ApiEndpoints.actualites, data: {
    'title': title,
    'content': content,
    'excerpt': excerpt,
    'date': date.toIso8601String(),
  });

  return parseResponse(response.data);
}
