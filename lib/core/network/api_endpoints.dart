class ApiEndpoints {
  static const String apiBaseUrl = 'https://admin.mec-ci.org/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendEmailOtp = '/auth/resend-email-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String signalementCitoyen = '/signalement-citoyen';
  static const String categorieSignalement = '/categorie-signalement';

  static const String actualites = '/actualites';
  static String actualiteById(String id) => '/actualites/$id';

  // ── Réactions (likes) ──────────────────────────────────────────────────────
  static String signalementReactionToggle(String id) =>
      '/signalement-citoyen/$id/reactions/toggle';
  static String actualiteReactionToggle(String id) =>
      '/actualites/$id/reactions/toggle';

  // ── Commentaires ───────────────────────────────────────────────────────────
  static String signalementCommentaires(String id) =>
      '/signalement-citoyen/$id/commentaires';
  static String actualiteCommentaires(String id) =>
      '/actualites/$id/commentaires';
  static String signalementCommentaireById(String id, String commentaireId) =>
      '/signalement-citoyen/$id/commentaires/$commentaireId';
  static String actualiteCommentaireById(String id, String commentaireId) =>
      '/actualites/$id/commentaires/$commentaireId';

  static const String quizz = '/quizz';
  static const String quizzCategories = '/quizz/categories';
  static const String quizzSubmit = '/quizz/submit';
  static const String quizzResults = '/quizz/results';
  static String quizzResultsByUser(String userId) => '/quizz/results/$userId';

  // ── Gamification ─────────────────────────────────────────────────────────
  static const String gamificationMe = '/gamification/me';
  static const String gamificationPoints = '/gamification/points';
  static const String gamificationLeaderboard = '/gamification/leaderboard';

  static const String librairiePublic = '/librairie/public';
  static const String librairieCategories = '/librairie/public/categories';

  static const String usersDetail = '/users/detail';
  // Mise à jour du profil et de l'avatar : PATCH /users (multipart, champ `image`)
  static const String usersUpdate = '/users';
  static const String usersPassword = '/users/password';

  static const String notificationsRegister = '/notification/register-device';
}
