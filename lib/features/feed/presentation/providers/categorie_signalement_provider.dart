import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citoyen_plus/models/categorie_signalement_model.dart';
import 'package:citoyen_plus/services/recuperer_categorie_signalement_service.dart';

class CategorieSignalementState {
  final List<CategorieSignalementModel> categories;
  final bool isLoading;
  final String? error;

  const CategorieSignalementState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategorieSignalementState copyWith({
    List<CategorieSignalementModel>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategorieSignalementState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategorieSignalementNotifier
    extends StateNotifier<CategorieSignalementState> {
  CategorieSignalementNotifier() : super(const CategorieSignalementState());

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await CategorieSignalementService.fetchAllCategories();
      state = CategorieSignalementState(
        categories: categories,
        isLoading: false,
      );
    } catch (_) {
      // Aucun repli local : proposer de fausses catégories enverrait un
      // identifiant inexistant au serveur (signalement rejeté). On expose
      // plutôt une erreur pour permettre une nouvelle tentative.
      state = const CategorieSignalementState(
        categories: [],
        isLoading: false,
        error: 'Impossible de charger les catégories. Réessayez.',
      );
    }
  }
}

final categorieSignalementProvider =
    StateNotifierProvider<CategorieSignalementNotifier,
        CategorieSignalementState>((ref) {
  return CategorieSignalementNotifier();
});
