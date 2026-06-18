import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citoyen_plus/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? userData;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = true,
    this.error,
    this.userData,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userData: userData ?? this.userData,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, error: null);
    final isAuth = await AuthService.isAuthenticated();
    state = state.copyWith(
      status: isAuth ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      isLoading: false,
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await AuthService.login(email: email, password: password);
    if (result['success'] == true) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        userData: result['data'] as Map<String, dynamic>?,
      );
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      error: result['message'] as String?,
    );
    return false;
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await AuthService.signup(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    if (result['success'] == true) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        userData: result['data'] as Map<String, dynamic>?,
      );
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      error: result['message'] as String?,
    );
    return false;
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
