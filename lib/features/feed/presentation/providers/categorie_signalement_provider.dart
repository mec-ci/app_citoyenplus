import 'package:dio/dio.dart';
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
    } on DioException {
      state = CategorieSignalementState(
        categories: _mockFallbackCategories,
        isLoading: false,
      );
    } catch (e) {
      state = CategorieSignalementState(
        categories: state.categories,
        isLoading: false,
        error: 'Impossible de charger les categories.',
      );
    }
  }
}

final categorieSignalementProvider =
    StateNotifierProvider<CategorieSignalementNotifier,
        CategorieSignalementState>((ref) {
  return CategorieSignalementNotifier();
});

List<CategorieSignalementModel> get _mockFallbackCategories => [
  CategorieSignalementModel(
    id: 'fb_cat_1',
    nom: 'Voirie',
    description: 'Problèmes de voirie',
    validationObligatoire: false,
  ),
  CategorieSignalementModel(
    id: 'fb_cat_2',
    nom: 'Éclairage public',
    description: 'Pannes d\'éclairage',
    validationObligatoire: false,
  ),
  CategorieSignalementModel(
    id: 'fb_cat_3',
    nom: 'Eau et assainissement',
    description: 'Problèmes d\'eau',
    validationObligatoire: false,
  ),
  CategorieSignalementModel(
    id: 'fb_cat_4',
    nom: 'Déchets',
    description: 'Collecte des déchets',
    validationObligatoire: false,
  ),
  CategorieSignalementModel(
    id: 'fb_cat_5',
    nom: 'Sécurité',
    description: 'Sécurité publique',
    validationObligatoire: false,
  ),
];
