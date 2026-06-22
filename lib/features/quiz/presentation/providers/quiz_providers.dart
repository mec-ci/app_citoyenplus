import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citoyen_plus/services/api_service.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/models/quiz.dart';

class QuizCategoriesState {
  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final String? error;

  const QuizCategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  QuizCategoriesState copyWith({
    List<Map<String, dynamic>>? categories,
    bool? isLoading,
    String? error,
  }) {
    return QuizCategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class QuizCategoriesNotifier extends StateNotifier<QuizCategoriesState> {
  QuizCategoriesNotifier() : super(const QuizCategoriesState());

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await ApiService.fetchQuizCategories();
      state = QuizCategoriesState(categories: categories, isLoading: false);
    } on DioException {
      state = QuizCategoriesState(
        categories: _mockFallbackCategories,
        isLoading: false,
      );
    } catch (e) {
      state = QuizCategoriesState(
        categories: state.categories,
        isLoading: false,
        error: 'Impossible de charger les categories de quiz.',
      );
    }
  }
}

List<Map<String, dynamic>> get _mockFallbackCategories => [
  {'id': 'fallback_1', 'nom': 'Constitution', '_count': {'quizzes': 0}},
  {'id': 'fallback_2', 'nom': 'Institutions', '_count': {'quizzes': 0}},
  {'id': 'fallback_3', 'nom': 'Histoire', '_count': {'quizzes': 0}},
];

final quizCategoriesProvider = StateNotifierProvider<QuizCategoriesNotifier, QuizCategoriesState>((ref) {
  return QuizCategoriesNotifier();
});

class QuizListState {
  final List<ApiQuiz> quizzes;
  final bool isLoading;
  final String? error;

  const QuizListState({
    this.quizzes = const [],
    this.isLoading = false,
    this.error,
  });

  QuizListState copyWith({
    List<ApiQuiz>? quizzes,
    bool? isLoading,
    String? error,
  }) {
    return QuizListState(
      quizzes: quizzes ?? this.quizzes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class QuizListNotifier extends StateNotifier<QuizListState> {
  QuizListNotifier() : super(const QuizListState());

  Future<void> fetchQuizzes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quizzes = await ApiService.fetchQuizzes();
      state = QuizListState(quizzes: quizzes, isLoading: false);
    } on DioException {
      state = QuizListState(quizzes: [], isLoading: false);
    } catch (e) {
      state = QuizListState(
        quizzes: state.quizzes,
        isLoading: false,
        error: 'Impossible de charger les quiz.',
      );
    }
  }
}

final quizListProvider = StateNotifierProvider<QuizListNotifier, QuizListState>((ref) {
  return QuizListNotifier();
});

class QuizDetailState {
  final ApiQuiz? quiz;
  final bool isLoading;
  final String? error;

  const QuizDetailState({
    this.quiz,
    this.isLoading = false,
    this.error,
  });

  QuizDetailState copyWith({
    ApiQuiz? quiz,
    bool? isLoading,
    String? error,
  }) {
    return QuizDetailState(
      quiz: quiz ?? this.quiz,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class QuizDetailNotifier extends StateNotifier<QuizDetailState> {
  QuizDetailNotifier() : super(const QuizDetailState());

  Future<void> fetchQuiz(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.getInstance().get('/quizz/$id');
      final data = response.data is Map<String, dynamic>
          ? response.data['data'] ?? response.data
          : response.data;
      final quiz = ApiQuiz.fromJson((data as Map).cast<String, dynamic>());
      state = QuizDetailState(quiz: quiz, isLoading: false);
    } catch (e) {
      state = QuizDetailState(
        quiz: state.quiz,
        isLoading: false,
        error: 'Impossible de charger le quiz.',
      );
    }
  }
}

final quizDetailProvider = StateNotifierProvider<QuizDetailNotifier, QuizDetailState>((ref) {
  return QuizDetailNotifier();
});

class SubmitQuizState {
  final Map<String, dynamic>? result;
  final bool isLoading;
  final String? error;

  const SubmitQuizState({
    this.result,
    this.isLoading = false,
    this.error,
  });

  SubmitQuizState copyWith({
    Map<String, dynamic>? result,
    bool? isLoading,
    String? error,
  }) {
    return SubmitQuizState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubmitQuizNotifier extends StateNotifier<SubmitQuizState> {
  SubmitQuizNotifier() : super(const SubmitQuizState());

  Future<bool> submitQuiz({
    required String userId,
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.getInstance().post('/quizz/submit', data: {
        'userId': userId,
        'quizId': quizId,
        'answers': answers,
      });
      final result = response.data as Map<String, dynamic>;
      state = SubmitQuizState(result: result, isLoading: false);
      return true;
    } catch (e) {
      state = SubmitQuizState(
        result: state.result,
        isLoading: false,
        error: 'Erreur lors de la soumission.',
      );
      return false;
    }
  }
}

final submitQuizProvider = StateNotifierProvider<SubmitQuizNotifier, SubmitQuizState>((ref) {
  return SubmitQuizNotifier();
});
