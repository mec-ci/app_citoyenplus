import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';

/// Un badge obtenu par l'utilisateur dans le cadre de la gamification.
class GamificationBadge {
  final String code;
  final String label;
  final DateTime? obtenuLe;

  const GamificationBadge({
    required this.code,
    required this.label,
    this.obtenuLe,
  });

  factory GamificationBadge.fromJson(Map<String, dynamic> json) {
    return GamificationBadge(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      obtenuLe: json['obtenuLe'] != null
          ? DateTime.tryParse(json['obtenuLe'].toString())
          : null,
    );
  }
}

/// État de gamification renvoyé par `GET /gamification/me`
/// et `POST /gamification/points`.
class GamificationMe {
  final int points;
  final int niveau;
  final List<GamificationBadge> badges;

  const GamificationMe({
    required this.points,
    required this.niveau,
    this.badges = const [],
  });

  factory GamificationMe.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'] as List? ?? const [];
    return GamificationMe(
      points: (json['points'] as num?)?.toInt() ?? 0,
      niveau: (json['niveau'] as num?)?.toInt() ?? 0,
      badges: rawBadges
          .map((e) => GamificationBadge.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Une entrée du classement renvoyé par `GET /gamification/leaderboard`.
class LeaderboardEntry {
  final String userId;
  final String nom;
  final int points;
  final int niveau;

  const LeaderboardEntry({
    required this.userId,
    required this.nom,
    required this.points,
    required this.niveau,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: (json['userId'] ?? '').toString(),
      nom: json['nom']?.toString() ?? 'Utilisateur',
      points: (json['points'] as num?)?.toInt() ?? 0,
      niveau: (json['niveau'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Service de gamification synchronisée avec le serveur.
class GamificationService {
  static final Dio _dio = DioClient.getInstance();

  /// Récupère l'état de gamification de l'utilisateur connecté.
  static Future<GamificationMe> getMe() async {
    final response = await _dio.get(ApiEndpoints.gamificationMe);
    final raw = response.data;
    final map = raw is Map<String, dynamic>
        ? (raw['data'] is Map ? (raw['data'] as Map).cast<String, dynamic>() : raw)
        : <String, dynamic>{};
    return GamificationMe.fromJson(map);
  }

  /// Ajoute des points pour une raison donnée et renvoie l'état mis à jour.
  static Future<GamificationMe> addPoints(int points, String raison) async {
    final response = await _dio.post(
      ApiEndpoints.gamificationPoints,
      data: {'points': points, 'raison': raison},
    );
    final raw = response.data;
    final map = raw is Map<String, dynamic>
        ? (raw['data'] is Map ? (raw['data'] as Map).cast<String, dynamic>() : raw)
        : <String, dynamic>{};
    return GamificationMe.fromJson(map);
  }

  /// Récupère le classement.
  static Future<List<LeaderboardEntry>> leaderboard({int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.gamificationLeaderboard,
      queryParameters: {'limit': limit},
    );
    final raw = response.data;
    final list = raw is Map<String, dynamic> ? (raw['data'] as List? ?? const []) : (raw as List? ?? const []);
    return list
        .map((e) => LeaderboardEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
