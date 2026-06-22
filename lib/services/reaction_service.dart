import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';

/// Résultat d'un toggle de réaction (like) renvoyé par le backend.
class ReactionResult {
  final bool liked;
  final int likesCount;

  const ReactionResult({required this.liked, required this.likesCount});

  factory ReactionResult.fromJson(Map<String, dynamic> json) {
    return ReactionResult(
      liked: json['liked'] == true,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Service de gestion des réactions (likes) sur les signalements et actualités.
class ReactionService {
  static final Dio _dio = DioClient.getInstance();

  /// Active/désactive le like d'un signalement.
  static Future<ReactionResult> toggleSignalement(String id) async {
    final response = await _dio.post(
      ApiEndpoints.signalementReactionToggle(id),
    );
    return ReactionResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  /// Active/désactive le like d'une actualité.
  static Future<ReactionResult> toggleActualite(String id) async {
    final response = await _dio.post(
      ApiEndpoints.actualiteReactionToggle(id),
    );
    return ReactionResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
