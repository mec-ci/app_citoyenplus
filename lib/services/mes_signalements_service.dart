import 'package:dio/dio.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

class MesSignalementsService {
  static final Dio _dio = DioClient.getInstance();

  static Future<List<SignalementModel>> fetchMesSignalements(
      String citoyenId) async {
    final response = await _dio.get(
      ApiEndpoints.signalementCitoyenByUser(citoyenId),
    );

    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    final signalements = (items as List)
        .map((json) => SignalementModel.fromJson(json as Map<String, dynamic>))
        .toList();

    signalements.sort((a, b) {
      final dateA = a.createdAt ?? DateTime(0);
      final dateB = b.createdAt ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    return signalements;
  }
}
