import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/signalement_repository.dart';
import '../../domain/models/signalement.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';

final dioClientProvider = Provider<Dio>((ref) {
  return DioClient.getInstance();
});

final signalementRepositoryProvider = Provider<ISignalementRepository>((ref) {
  return SignalementRepository(dio: ref.read(dioClientProvider));
});

final signalementProvider =
    StateNotifierProvider<SignalementNotifier, SignalementState>((ref) {
      return SignalementNotifier(ref.read(signalementRepositoryProvider));
    });

class SignalementState {
  final List<Signalement> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool isCreating;
  final int page;
  final int limit;
  final int totalPages;

  const SignalementState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.isCreating = false,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  SignalementState copyWith({
    List<Signalement>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? isCreating,
    int? page,
    int? limit,
    int? totalPages,
  }) {
    return SignalementState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      isCreating: isCreating ?? this.isCreating,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  bool get hasNextPage => page < totalPages;
}

class SignalementNotifier extends StateNotifier<SignalementState> {
  final ISignalementRepository _repository;

  SignalementNotifier(this._repository) : super(const SignalementState());

  Future<void> fetchSignalements({int? page}) async {
    final targetPage = page ?? state.page;
    // La première page (re)charge le flux ; les suivantes l'enrichissent
    // (défilement infini) en conservant les éléments déjà chargés.
    final isFirstPage = targetPage <= 1;
    state = state.copyWith(
      isLoading: isFirstPage,
      isLoadingMore: !isFirstPage,
      error: null,
    );
    try {
      final result = await _repository.getSignalements(page: targetPage, limit: state.limit);
      state = state.copyWith(
        items: isFirstPage ? result.items : [...state.items, ...result.items],
        isLoading: false,
        isLoadingMore: false,
        page: targetPage,
        totalPages: result.totalPages,
        error: null,
      );
    } on AppException catch (exception) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: exception.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Erreur inconnue lors du chargement des signalements.',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (!state.hasNextPage || state.isLoading || state.isLoadingMore) return;
    await fetchSignalements(page: state.page + 1);
  }

  Future<void> refresh() async {
    await fetchSignalements(page: 1);
  }

  Future<bool> createSignalement(CreateSignalementDto dto) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final signalement = await _repository.createSignalement(dto);
      state = state.copyWith(
        isCreating: false,
        items: [signalement, ...state.items],
      );
      return true;
    } on AppException catch (exception) {
      state = state.copyWith(isCreating: false, error: exception.message);
      return false;
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        error: 'Erreur inconnue lors de la création du signalement.',
      );
      return false;
    }
  }

  void reset() {
    state = const SignalementState();
  }
}
