/// Modèles des quiz tels que renvoyés par l'API (`GET /quizz`).
///
/// Forme réelle du backend (préfixe `/api/v1`, Bearer JWT) :
/// ```
/// {
///   id, title, description, difficulte,            // difficulte ∈ FACILE|MOYEN|DIFFICILE|null
///   categorie: { id, nom },
///   questions: [ { id, text, correctId, choices: [ { id, text } ] } ]
/// }
/// ```
/// `correctId` est l'identifiant du choix correct : il sert uniquement au
/// feedback/score local (le score officiel est recalculé côté serveur).
class ApiQuiz {
  final String id;
  final String title;
  final String? description;

  /// Difficulté brute renvoyée par l'API : `FACILE`, `MOYEN`, `DIFFICILE`
  /// ou `null` si non renseignée.
  final String? difficulte;

  /// Identifiant et nom de la catégorie associée (peuvent être vides si
  /// l'API ne les renvoie pas).
  final String categorieId;
  final String categorieNom;

  final List<ApiQuestion> questions;

  ApiQuiz({
    required this.id,
    required this.title,
    this.description,
    required this.difficulte,
    required this.categorieId,
    required this.categorieNom,
    required this.questions,
  });

  factory ApiQuiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? const [];
    final categorie = json['categorie'];
    final categorieMap =
        categorie is Map ? categorie.cast<String, dynamic>() : const {};

    final rawDifficulte = json['difficulte']?.toString();
    return ApiQuiz(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      difficulte: (rawDifficulte == null || rawDifficulte.isEmpty)
          ? null
          : rawDifficulte.toUpperCase(),
      categorieId: (categorieMap['id'] ?? '').toString(),
      categorieNom: (categorieMap['nom'] ?? categorieMap['titre'] ?? '')
          .toString(),
      questions: rawQuestions
          .map((q) => ApiQuestion.fromJson((q as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ApiQuestion {
  final String id;
  final String text;

  /// Identifiant du choix correct (pour le feedback/score local).
  final String? correctId;
  final List<ApiChoice> choices;

  ApiQuestion({
    required this.id,
    required this.text,
    required this.correctId,
    required this.choices,
  });

  factory ApiQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List? ?? const [];
    final correct = json['correctId']?.toString();
    return ApiQuestion(
      id: (json['id'] ?? '').toString(),
      text: json['text']?.toString() ?? '',
      correctId: (correct == null || correct.isEmpty) ? null : correct,
      choices: rawChoices
          .map((c) => ApiChoice.fromJson((c as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Index (0-based) du choix correct dans [choices], ou `-1` si introuvable.
  int get correctIndex {
    if (correctId == null) return -1;
    return choices.indexWhere((c) => c.id == correctId);
  }
}

class ApiChoice {
  final String id;
  final String text;

  ApiChoice({required this.id, required this.text});

  factory ApiChoice.fromJson(Map<String, dynamic> json) {
    return ApiChoice(
      id: (json['id'] ?? '').toString(),
      text: json['text']?.toString() ?? '',
    );
  }
}
