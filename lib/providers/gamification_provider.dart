import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gamification_service.dart';

class GamificationState {
  final int totalPoints;
  final int niveau;
  final int pendingSyncPoints;
  final bool isSyncing;
  final int lastPointsGained;
  final bool showCelebration;

  const GamificationState({
    this.totalPoints = 0,
    this.niveau = 0,
    this.pendingSyncPoints = 0,
    this.isSyncing = false,
    this.lastPointsGained = 0,
    this.showCelebration = false,
  });

  GamificationState copyWith({
    int? totalPoints,
    int? niveau,
    int? pendingSyncPoints,
    bool? isSyncing,
    int? lastPointsGained,
    bool? showCelebration,
  }) {
    return GamificationState(
      totalPoints: totalPoints ?? this.totalPoints,
      niveau: niveau ?? this.niveau,
      pendingSyncPoints: pendingSyncPoints ?? this.pendingSyncPoints,
      isSyncing: isSyncing ?? this.isSyncing,
      lastPointsGained: lastPointsGained ?? this.lastPointsGained,
      showCelebration: showCelebration ?? this.showCelebration,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(const GamificationState()) {
    _loadPoints();
  }

  static const _pointsKey = 'user_points';
  static const _niveauKey = 'user_niveau';
  static const _pendingKey = 'pending_sync_points';

  /// Au démarrage : on lit d'abord le cache local (offline-first),
  /// puis on tente de se synchroniser avec le serveur.
  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      totalPoints: prefs.getInt(_pointsKey) ?? 0,
      niveau: prefs.getInt(_niveauKey) ?? 0,
      pendingSyncPoints: prefs.getInt(_pendingKey) ?? 0,
    );
    await refresh();
  }

  /// Recharge l'état depuis le serveur. Envoie d'abord le cumul en attente
  /// (fusion à la reconnexion) puis adopte l'état serveur. Sans plantage
  /// hors-ligne : en cas d'échec on conserve le cache local.
  Future<void> refresh() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      // 1) On pousse d'abord les points accumulés hors-ligne.
      if (state.pendingSyncPoints > 0) {
        final synced = await GamificationService.addPoints(
          state.pendingSyncPoints,
          'sync_offline',
        );
        await _persistFromServer(synced, clearPending: true);
        state = state.copyWith(isSyncing: false);
        return;
      }
      // 2) Sinon on adopte simplement l'état serveur.
      final me = await GamificationService.getMe();
      await _persistFromServer(me, clearPending: true);
      state = state.copyWith(isSyncing: false);
    } catch (_) {
      // Hors-ligne ou erreur serveur : on garde le cache local.
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Ajoute des points. On met d'abord à jour le cache local (réactif,
  /// fonctionne hors-ligne), puis on tente la synchronisation serveur.
  Future<void> addPoints(int amount, {String raison = 'quiz'}) async {
    final prefs = await SharedPreferences.getInstance();
    final newTotal = state.totalPoints + amount;
    final newPending = state.pendingSyncPoints + amount;
    await prefs.setInt(_pointsKey, newTotal);
    await prefs.setInt(_pendingKey, newPending);
    state = state.copyWith(
      totalPoints: newTotal,
      pendingSyncPoints: newPending,
      lastPointsGained: amount,
      showCelebration: true,
    );
    await _syncPending(raison: raison);
  }

  /// Affiche uniquement l'animation de gain de points, SANS modifier le total
  /// ni poster au serveur. À utiliser quand les points sont attribués côté
  /// serveur (ex. complétion de quiz) afin d'éviter un double comptage ;
  /// appeler ensuite [refresh] pour adopter le total serveur.
  void celebrate(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(lastPointsGained: amount, showCelebration: true);
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false, lastPointsGained: 0);
  }

  /// Envoie le cumul en attente au serveur et adopte la réponse (points/niveau).
  Future<void> _syncPending({String raison = 'quiz'}) async {
    if (state.pendingSyncPoints <= 0 || state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      final me = await GamificationService.addPoints(
        state.pendingSyncPoints,
        raison,
      );
      await _persistFromServer(me, clearPending: true);
      state = state.copyWith(isSyncing: false);
    } catch (_) {
      // On reste en cache local, le cumul sera renvoyé à la prochaine reconnexion.
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Persiste l'état serveur dans le cache local et reflète points/niveau.
  Future<void> _persistFromServer(
    GamificationMe me, {
    bool clearPending = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, me.points);
    await prefs.setInt(_niveauKey, me.niveau);
    if (clearPending) await prefs.setInt(_pendingKey, 0);
    state = state.copyWith(
      totalPoints: me.points,
      niveau: me.niveau,
      pendingSyncPoints: clearPending ? 0 : state.pendingSyncPoints,
    );
  }

  Future<void> syncNow() => refresh();
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
