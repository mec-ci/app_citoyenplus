import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';

Future<PostModel> createArticle(
  String title,
  String content,
  String token, {
  required DateTime date,
  File? image,
}) async {
  final uri = Uri.parse('https://admin.mec-ci.org/api/v1/actualites');

  if (image != null) {
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..fields['content'] = content
      ..fields['date'] = date.toIso8601String()
      ..files.add(await http.MultipartFile.fromPath('imageUrl', image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PostModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Échec publication. Status: ${response.statusCode}, Body: ${response.body}');
    }
  } else {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
      }),
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
