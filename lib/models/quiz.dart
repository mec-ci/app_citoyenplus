class QuizModel {
  final String id;
  final String title;
  final String? description;
  final String difficulte;
  final String categorieId;
  final List<Question> questions;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.difficulte,
    required this.categorieId,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    return QuizModel(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      difficulte: json['difficulte']?.toString() ?? 'FACILE',
      categorieId: (json['categorieId'] ?? '').toString(),
      questions: rawQuestions
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'difficulte': difficulte,
      'categorieId': categorieId,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class Question {
  final String text;
  final List<Choice> choices;

  Question({required this.text, required this.choices});

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List? ?? [];
    return Question(
      text: json['text']?.toString() ?? '',
      choices: rawChoices
          .map((c) => Choice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}

class Choice {
  final String text;
  final bool isCorrect;

  Choice({required this.text, required this.isCorrect});

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      text: json['text']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}
