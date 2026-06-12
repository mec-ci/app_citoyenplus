import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

Future<PostModel> createArticle(
  String title,
  String content, {
  required DateTime date,
  XFile? image,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/actualites');

  if (image != null) {
    final response = await AuthService.authorizedMultipartRequest(() async {
      final request = http.MultipartRequest('POST', uri)
        ..fields['title'] = title
        ..fields['content'] = content
        ..fields['date'] = date.toIso8601String();

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'imageUrl',
          bytes,
          filename: image.name,
        );
        request.files.add(multipartFile);
      } else {
        request.files.add(await http.MultipartFile.fromPath('imageUrl', image.path));
      }

      return request;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PostModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Échec publication. Status: ${response.statusCode}, Body: ${response.body}');
    }
  } else {
    final response = await AuthService.authorizedPost(
      uri,
      extraHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
      }),
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PostModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Échec publication. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
