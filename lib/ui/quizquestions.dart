import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/gamification_provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quiz_score_screen.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);
const _green = Color(0xFF34C759);
const _red = Color(0xFFFF2D55);

class Quizquestions extends ConsumerStatefulWidget {
  final String categorie;
  final int level;

  /// Identifiant RÉEL du quiz côté API (UUID). `null` en mode hors-ligne
  /// (banque locale) : la soumission serveur est alors impossible et le
  /// résultat n'est pas envoyé.
  final String? quizId;

  /// Questions au format map. Chaque entrée peut porter les vrais identifiants
  /// (`questionId`, `choiceIds`) lorsque les questions viennent de l'API.
  final List<Map<String, dynamic>> questions;
  final Future<void> Function(bool passed)? onLevelCompleted;

  const Quizquestions({
    super.key,
    required this.categorie,
    required this.level,
    this.quizId,
    required this.questions,
    this.onLevelCompleted,
  });

  @override
  ConsumerState<Quizquestions> createState() => _QuizquestionsState();
}

class _QuizquestionsState extends ConsumerState<Quizquestions>
    with TickerProviderStateMixin {
  int questionIndex = 0;
  int correctCount = 0;
  int? selectedAnswer;
  bool _answered = false;

  int _currentScore = 0;
  final List<double> _timePerQuestion = [];
  final List<Map<String, dynamic>> _answers = [];

  int _secondsRemaining = 30;
  Timer? _timer;
  late AnimationController _timerAnimCtrl;

  final int _maxSeconds = 30;

  @override
  void initState() {
    super.initState();
    _timerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() => setState(() {}));
    _timerAnimCtrl.forward();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = _maxSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _autoAdvance();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _autoAdvance() {
    if (_answered) return;
    setState(() {
      _answered = true;
      selectedAnswer = -1;
    });
    _timePerQuestion.add(_maxSeconds.toDouble());
    final q = widget.questions[questionIndex];
    _answers.add({
      'questionId': questionIndex,
      'questionRealId': q['questionId'],
      'choiceRealId': null, // aucune réponse (temps écoulé)
      'selectedChoice': -1,
      'isCorrect': false,
      'timeSpent': _maxSeconds,
    });
    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    final timeSpent = _maxSeconds - _secondsRemaining;
    _timePerQuestion.add(timeSpent.toDouble());

    final isCorrect = index == widget.questions[questionIndex]['correct'];

    int pointsGained = 0;
    if (isCorrect) {
      pointsGained += 10;
      if (timeSpent < 10) pointsGained += 5;
      correctCount++;
    }

    setState(() {
      selectedAnswer = index;
      _answered = true;
      _currentScore += pointsGained;
    });

    final q = widget.questions[questionIndex];
    final choiceIds = q['choiceIds'];
    final String? choiceRealId =
        (choiceIds is List && index >= 0 && index < choiceIds.length)
            ? choiceIds[index]?.toString()
            : null;

    _answers.add({
      'questionId': questionIndex,
      'questionRealId': q['questionId'],
      'choiceRealId': choiceRealId,
      'selectedChoice': index,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
    });

    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _nextQuestion() {
    if (questionIndex < widget.questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedAnswer = null;
        _answered = false;
        _secondsRemaining = _maxSeconds;
      });
      _timerAnimCtrl.reset();
      _timerAnimCtrl.forward();
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final total = widget.questions.length;
    final pct = (correctCount / total * 100).round();
    final totalPoints = _currentScore;
    final passed = pct >= 60;

    ref
        .read(gamificationProvider.notifier)
        .addPoints(totalPoints, raison: 'quiz:${widget.categorie}:niveau${widget.level}');

    // Persiste le résultat du quiz côté serveur (best-effort, repli local).
    _submitQuizResult();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScoreScreen(
          score: correctCount,
          total: total,
          totalPoints: totalPoints,
          passed: passed,
          level: widget.level,
          categorie: widget.categorie,
          onLevelCompleted: widget.onLevelCompleted,
          timePerQuestion: _timePerQuestion,
          answers: _answers,
        ),
      ),
    );
  }

  /// Soumet le résultat au backend `POST /quizz/submit` avec :
  /// - le VRAI `quizId` (UUID renvoyé par l'API),
  /// - le `userId` de l'utilisateur connecté,
  /// - `answers` = `[{ questionId: <vrai id>, choiceId: <vrai id du choix> }]`.
  ///
  /// En cas d'échec (hors-ligne / erreur réseau), le résultat est mis en file
  /// d'attente locale (`pending_quiz_results`) pour un renvoi ultérieur.
  Future<void> _submitQuizResult() async {
    final quizId = widget.quizId;

    // Construit la soumission à partir des VRAIS identifiants des questions et
    // des choix. On ignore les réponses sans choix sélectionné (temps écoulé)
    // ou dépourvues d'identifiants (questions hors banque API).
    final payloadAnswers = <Map<String, dynamic>>[];
    for (final a in _answers) {
      final questionRealId = a['questionRealId'];
      final choiceRealId = a['choiceRealId'];
      if (questionRealId == null || choiceRealId == null) continue;
      payloadAnswers.add({
        'questionId': questionRealId.toString(),
        'choiceId': choiceRealId.toString(),
      });
    }

    // Pas de quizId réel (mode hors-ligne / banque locale) ou aucune réponse
    // exploitable : impossible de soumettre au serveur.
    if (quizId == null || quizId.isEmpty || payloadAnswers.isEmpty) return;

    final userId = await UserService.currentUserId();
    if (userId == null) {
      await _cachePendingResult(quizId, payloadAnswers, userId: null);
      return;
    }

    try {
      final result = await ApiService.postQuizResult(
        userId: userId,
        quizId: quizId,
        answers: payloadAnswers,
      );
      if (result == null) {
        await _cachePendingResult(quizId, payloadAnswers, userId: userId);
      }
    } catch (_) {
      // Repli local : on conserve le résultat pour un renvoi ultérieur.
      await _cachePendingResult(quizId, payloadAnswers, userId: userId);
    }
  }

  Future<void> _cachePendingResult(
    String quizId,
    List<Map<String, dynamic>> answers, {
    required String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'pending_quiz_results';
    final list = prefs.getStringList(key) ?? <String>[];
    list.add(jsonEncode({
      'userId': userId,
      'quizId': quizId,
      'answers': answers,
      'savedAt': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(key, list);
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[questionIndex];
    final int correct = (question['correct'] as int?) ?? -1;
    final List options = (question['options'] as List?) ?? const [];
    final int total = widget.questions.length;
    final double progress = (questionIndex + 1) / total;
    final double timerValue = _secondsRemaining / _maxSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categorie,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
            Text(
              'Niveau ${widget.level}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: _orange, size: 18),
                  const SizedBox(width: 2),
                  Text(
                    '$_currentScore',
                    style: const TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Timer circulaire + progression
            Row(
              children: [
                // Timer circulaire
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: timerValue,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _secondsRemaining <= 10 ? _red : _orange,
                        ),
                      ),
                      Center(
                        child: Text(
                          '$_secondsRemaining',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _secondsRemaining <= 10 ? _red : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Question ${questionIndex + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            '${questionIndex + 1} / $total',
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                question['question'],
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final bool isSelected = selectedAnswer == i;
                  final bool isCorrectAnswer = i == correct;

                  Color borderColor = Colors.grey.shade200;
                  Color bgColor = Colors.white;
                  Color textColor = Colors.black87;
                  Widget? trailing;

                  if (_answered) {
                    if (isCorrectAnswer) {
                      borderColor = _green;
                      bgColor = _green.withValues(alpha: 0.08);
                      textColor = _green;
                      trailing = const Icon(Icons.check_circle,
                          color: _green, size: 20);
                    } else if (isSelected && !isCorrectAnswer) {
                      borderColor = _red;
                      bgColor = _red.withValues(alpha: 0.08);
                      textColor = _red;
                      trailing =
                          const Icon(Icons.cancel, color: _red, size: 20);
                    } else {
                      borderColor = Colors.grey.shade200;
                    }
                  } else if (isSelected) {
                    borderColor = _orange;
                    bgColor = _orange.withValues(alpha: 0.08);
                    textColor = _orange;
                  }

                  return GestureDetector(
                    onTap: () => _selectAnswer(i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected && !_answered ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: borderColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[i].toString(),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (trailing != null) trailing,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bouton suivant
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _answered ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  disabledBackgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  questionIndex < total - 1
                      ? 'Question suivante →'
                      : 'Voir le résultat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _answered ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
