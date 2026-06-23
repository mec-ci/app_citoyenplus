import 'package:dio/dio.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

class MesSignalementsService {
  static final Dio _dio = DioClient.getInstance();

  /// Récupère les signalements de l'utilisateur connecté via la route dédiée
  /// `GET /signalement-citoyen/me` : le backend déduit le citoyen du JWT, aucun
  /// identifiant n'est donc nécessaire côté client.
  static Future<List<SignalementModel>> fetchMesSignalements() async {
    final response = await _dio.get(
      ApiEndpoints.signalementCitoyenMe,
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
