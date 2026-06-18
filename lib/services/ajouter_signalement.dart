import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

Future<SignalementModel> createSignalement({
  required String titre,
  required String description,
  required String categorieId,
  required String adresse,
  required double latitude,
  required double longitude,
  XFile? photo,
}) async {
  final dio = DioClient.getInstance();

  if (photo != null) {
    final formData = FormData.fromMap({
      'titre': titre,
      'description': description,
      'categorieId': categorieId,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.name,
      ),
    });

    final response = await dio.post(
      ApiEndpoints.signalementCitoyen,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return SignalementModel.fromJson(response.data as Map<String, dynamic>);
  }

  final response = await dio.post(ApiEndpoints.signalementCitoyen, data: {
    'titre': titre,
    'description': description,
    'categorieId': categorieId,
    'adresse': adresse,
    'latitude': latitude,
    'longitude': longitude,
  });

  return SignalementModel.fromJson(response.data as Map<String, dynamic>);
}
