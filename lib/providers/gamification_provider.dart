import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gamification_service.dart' as gs;

/// État local du provider de gamification.
///
/// `totalPoints` / `niveau` reflètent la source serveur quand elle est
/// disponible, sinon le cache SharedPreferences (mode hors-ligne).
/// `pendingSyncPoints` accumule les points gagnés hors-ligne afin d'être
/// envoyés au backend à la reconnexion.
class GamificationState {
  final int totalPoints;
  final int niveau;
  final int pendingSyncPoints;
  final bool isSyncing;
  final int lastPointsGained;
  final bool showCelebration;
  final List<gs.GamificationBadge> badges;

  const GamificationState({
    this.totalPoints = 0,
    this.niveau = 1,
    this.pendingSyncPoints = 0,
    this.isSyncing = false,
    this.lastPointsGained = 0,
    this.showCelebration = false,
    this.badges = const [],
  });

  GamificationState copyWith({
    int? totalPoints,
    int? niveau,
    int? pendingSyncPoints,
    bool? isSyncing,
    int? lastPointsGained,
    bool? showCelebration,
    List<gs.GamificationBadge>? badges,
  }) {
    return GamificationState(
      totalPoints: totalPoints ?? this.totalPoints,
      niveau: niveau ?? this.niveau,
      pendingSyncPoints: pendingSyncPoints ?? this.pendingSyncPoints,
      isSyncing: isSyncing ?? this.isSyncing,
      lastPointsGained: lastPointsGained ?? this.lastPointsGained,
      showCelebration: showCelebration ?? this.showCelebration,
      badges: badges ?? this.badges,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(const GamificationState()) {
    _init();
  }

  static const _pointsKey = 'user_points';
  static const _niveauKey = 'user_niveau';
  static const _pendingKey = 'pending_sync_points';

  /// Au démarrage : charge le cache local puis tente de rafraîchir depuis le
  /// serveur (ne crashe pas hors-ligne).
  Future<void> _init() async {
    await _loadCache();
    await refresh();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      totalPoints: prefs.getInt(_pointsKey) ?? 0,
      niveau: prefs.getInt(_niveauKey) ?? 1,
      pendingSyncPoints: prefs.getInt(_pendingKey) ?? 0,
    );
  }

  /// Rafraîchit l'état depuis `GET /gamification/me`.
  /// En cas d'échec réseau, conserve le cache local sans crasher.
  Future<void> refresh() async {
    try {
      // Pousse d'abord les points accumulés hors-ligne, puis lit l'état serveur.
      await _syncPending();
      final remote = await gs.GamificationService.getMe();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pointsKey, remote.points);
      await prefs.setInt(_niveauKey, remote.niveau);
      state = state.copyWith(
        totalPoints: remote.points,
        niveau: remote.niveau,
        badges: remote.badges,
      );
    } catch (_) {
      // Hors-ligne / erreur serveur : on garde le cache déjà chargé.
    }
  }

  /// Ajoute des points : met à jour le cache local immédiatement (repli),
  /// puis tente de refléter la réponse serveur.
  Future<void> addPoints(int amount, {String raison = 'quiz'}) async {
    final prefs = await SharedPreferences.getInstance();
    // Mise à jour optimiste locale (repli hors-ligne, comportement existant).
    final localTotal = state.totalPoints + amount;
    await prefs.setInt(_pointsKey, localTotal);
    state = state.copyWith(
      totalPoints: localTotal,
      lastPointsGained: amount,
      showCelebration: true,
    );

    try {
      final remote = await gs.GamificationService.addPoints(amount, raison);
      await prefs.setInt(_pointsKey, remote.points);
      await prefs.setInt(_niveauKey, remote.niveau);
      // Les points distants ont été pris en compte : rien en attente.
      await prefs.setInt(_pendingKey, state.pendingSyncPoints);
      state = state.copyWith(
        totalPoints: remote.points,
        niveau: remote.niveau,
        badges: remote.badges,
      );
    } catch (_) {
      // Échec réseau : on accumule pour synchroniser plus tard.
      final newPending = state.pendingSyncPoints + amount;
      await prefs.setInt(_pendingKey, newPending);
      state = state.copyWith(pendingSyncPoints: newPending);
    }
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false, lastPointsGained: 0);
  }

  /// Envoie les points accumulés hors-ligne au backend.
  Future<void> _syncPending() async {
    if (state.pendingSyncPoints <= 0 || state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    final amount = state.pendingSyncPoints;
    try {
      final remote =
          await gs.GamificationService.addPoints(amount, 'sync-offline');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pendingKey, 0);
      await prefs.setInt(_pointsKey, remote.points);
      await prefs.setInt(_niveauKey, remote.niveau);
      state = state.copyWith(
        pendingSyncPoints: 0,
        isSyncing: false,
        totalPoints: remote.points,
        niveau: remote.niveau,
        badges: remote.badges,
      );
    } catch (_) {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> syncNow() => _syncPending();
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
