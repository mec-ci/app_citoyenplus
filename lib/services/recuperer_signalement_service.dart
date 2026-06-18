import 'package:dio/dio.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

class RecupererSignalementService {
  static final Dio _dio = DioClient.getInstance();

  static Future<List<SignalementModel>> fetchAllSignalement() async {
    final response = await _dio.get(ApiEndpoints.signalementCitoyen);
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    return (items as List)
        .map((json) => SignalementModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
