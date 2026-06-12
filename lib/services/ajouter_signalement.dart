import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

Future<SignalementModel> createSignalement({
  required String titre,
  required String description,
  required String categorieId,
  required String adresse,
  required double latitude,
  required double longitude,
  XFile? photo,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/signalement-citoyen');

  if (photo != null) {
    final response = await AuthService.authorizedMultipartRequest(() async {
      final request = http.MultipartRequest('POST', uri)
        ..fields['titre'] = titre
        ..fields['description'] = description
        ..fields['categorieId'] = categorieId
        ..fields['adresse'] = adresse
        ..fields['latitude'] = latitude.toString()
        ..fields['longitude'] = longitude.toString();

      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: photo.name,
        );
        request.files.add(multipartFile);
      } else {
        request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
      }

      return request;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SignalementModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Échec création signalement. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  final response = await AuthService.authorizedPost(
    uri,
    extraHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'titre': titre,
      'description': description,
      'categorieId': categorieId,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
    }),
    encoding: Encoding.getByName('utf-8'),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return SignalementModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  throw Exception(
    'Échec création signalement. Status: ${response.statusCode}, Body: ${response.body}',
  );
}
