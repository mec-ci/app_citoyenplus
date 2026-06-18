import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class GamificationState {
  final int totalPoints;
  final int pendingSyncPoints;
  final bool isSyncing;
  final int lastPointsGained;
  final bool showCelebration;

  const GamificationState({
    this.totalPoints = 0,
    this.pendingSyncPoints = 0,
    this.isSyncing = false,
    this.lastPointsGained = 0,
    this.showCelebration = false,
  });

  GamificationState copyWith({
    int? totalPoints,
    int? pendingSyncPoints,
    bool? isSyncing,
    int? lastPointsGained,
    bool? showCelebration,
  }) {
    return GamificationState(
      totalPoints: totalPoints ?? this.totalPoints,
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
  static const _pendingKey = 'pending_sync_points';

  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      totalPoints: prefs.getInt(_pointsKey) ?? 0,
      pendingSyncPoints: prefs.getInt(_pendingKey) ?? 0,
    );
    _syncIfNeeded();
  }

  Future<void> addPoints(int amount) async {
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
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false, lastPointsGained: 0);
  }

  Future<void> _syncIfNeeded() async {
    if (state.pendingSyncPoints <= 0 || state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      await ApiService.syncPoints(state.pendingSyncPoints);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pendingKey, 0);
      state = state.copyWith(pendingSyncPoints: 0, isSyncing: false);
    } catch (_) {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> syncNow() => _syncIfNeeded();
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
