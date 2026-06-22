import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';

/// Un badge obtenu par l'utilisateur dans le système de gamification.
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
    final dateRaw = json['obtenuLe'] ?? json['obtenu_le'] ?? json['date'];
    return GamificationBadge(
      code: (json['code'] ?? '').toString(),
      label: json['label']?.toString() ??
          json['libelle']?.toString() ??
          json['code']?.toString() ??
          '',
      obtenuLe: dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null,
    );
  }
}

/// État de gamification de l'utilisateur connecté renvoyé par le backend.
class GamificationState {
  final int points;
  final int niveau;
  final List<GamificationBadge> badges;

  const GamificationState({
    this.points = 0,
    this.niveau = 1,
    this.badges = const [],
  });

  factory GamificationState.fromJson(Map<String, dynamic> json) {
    final badgesRaw = json['badges'];
    final badges = badgesRaw is List
        ? badgesRaw
            .whereType<Map>()
            .map((e) => GamificationBadge.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <GamificationBadge>[];
    return GamificationState(
      points: (json['points'] as num?)?.toInt() ?? 0,
      niveau: (json['niveau'] as num?)?.toInt() ?? 1,
      badges: badges,
    );
  }
}

/// Une entrée du classement (leaderboard).
class LeaderboardEntry {
  final String userId;
  final String nom;
  final int points;
  final int niveau;

  const LeaderboardEntry({
    required this.userId,
    required this.nom,
    this.points = 0,
    this.niveau = 1,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: (json['userId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      nom: json['nom']?.toString() ??
          json['name']?.toString() ??
          json['fullname']?.toString() ??
          'Utilisateur',
      points: (json['points'] as num?)?.toInt() ?? 0,
      niveau: (json['niveau'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Service d'accès au système de gamification (points, niveaux, badges).
class GamificationService {
  static final Dio _dio = DioClient.getInstance();

  /// Récupère l'état de gamification de l'utilisateur connecté.
  static Future<GamificationState> getMe() async {
    final response = await _dio.get(ApiEndpoints.gamificationMe);
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? (data['data'] is Map ? data['data'] : data)
        : <String, dynamic>{};
    return GamificationState.fromJson((map as Map).cast<String, dynamic>());
  }

  /// Ajoute des points pour une raison donnée et renvoie l'état mis à jour.
  static Future<GamificationState> addPoints(int points, String raison) async {
    final response = await _dio.post(
      ApiEndpoints.gamificationPoints,
      data: {'points': points, 'raison': raison},
    );
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? (data['data'] is Map ? data['data'] : data)
        : <String, dynamic>{};
    return GamificationState.fromJson((map as Map).cast<String, dynamic>());
  }

  /// Récupère le classement des utilisateurs.
  static Future<List<LeaderboardEntry>> leaderboard({int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.gamificationLeaderboard,
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    final items = data is Map<String, dynamic> ? data['data'] ?? data : data;
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => LeaderboardEntry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
