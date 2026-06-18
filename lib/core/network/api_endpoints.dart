class ApiEndpoints {
  static const String apiBaseUrl = 'https://admin.mec-ci.org/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String logout = '/auth/logout';
  static const String verifyToken = '/auth/verify';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String sessions = '/auth/sessions';

  static const String signalementCitoyen = '/signalement-citoyen';
  static const String categorieSignalement = '/categorie-signalement';

  static const String actualites = '/actualites';

  static const String quizz = '/quizz';
  static const String quizzCategories = '/quizz/categories';
  static const String quizzSubmit = '/quizz/submit';
  static const String quizzResults = '/quizz/results';

  static const String librairiePublic = '/librairie/public';

  static const String usersDetail = '/users/detail';
  static const String usersAvatar = '/users/avatar';

  static const String notificationsRegister = '/notifications/register-device';
}
