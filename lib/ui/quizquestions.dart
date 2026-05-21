import 'package:flutter/material.dart';

const _orange = Color(0xFFFF7F00);
const _blue = Color(0xFF1556B5);
const _green = Color(0xFF34C759);
const _red = Color(0xFFFF2D55);

class Quizquestions extends StatefulWidget {
  final String categorie;
  final int level;
  final List<Map<String, dynamic>> questions;
  final Future<void> Function(bool passed)? onLevelCompleted;

  const Quizquestions({
    super.key,
    required this.categorie,
    required this.level,
    required this.questions,
    this.onLevelCompleted,
  });

  @override
  State<Quizquestions> createState() => QuizPageState();
}

class QuizPageState extends State<Quizquestions> {
  int questionIndex = 0;
  int score = 0;
  int? selectedAnswer;
  bool _answered = false;

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      selectedAnswer = index;
      _answered = true;
      if (index == widget.questions[questionIndex]['correct']) score++;
    });
  }

  void nextQuestion() {
    if (questionIndex < widget.questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedAnswer = null;
        _answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final total = widget.questions.length;
    final pct = (score / total * 100).round();
    final passed = pct >= 60;
    final emoji = pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '💪';
    final msg = pct >= 80
        ? 'Excellent !'
        : pct >= 60
            ? 'Niveau réussi !'
            : 'Continue à apprendre !';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              msg,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '$score / $total bonnes réponses ($pct%)',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            if (passed && widget.level < 3)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔓 Niveau ${widget.level + 1} débloqué !',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            if (!passed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Obtiens 60% pour passer au niveau suivant',
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / total,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                color: pct >= 80
                    ? _green
                    : pct >= 60
                        ? _orange
                        : _red,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (widget.onLevelCompleted != null) {
                    await widget.onLevelCompleted!(passed);
                  }
                  if (mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Retour aux niveaux',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[questionIndex];
    final int correct = question['correct'];
    final int total = widget.questions.length;
    final double progress = (questionIndex + 1) / total;

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
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$score pts',
                style: const TextStyle(
                    color: _orange, fontWeight: FontWeight.w800, fontSize: 15),
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
            // Barre de progression
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
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                color: _blue,
              ),
            ),
            const SizedBox(height: 28),

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
                itemCount: 4,
                itemBuilder: (context, i) {
                  final bool isSelected = selectedAnswer == i;
                  final bool isCorrect = i == correct;

                  Color borderColor = Colors.grey.shade200;
                  Color bgColor = Colors.white;
                  Color textColor = Colors.black87;
                  Widget? trailing;

                  if (_answered) {
                    if (isCorrect) {
                      borderColor = _green;
                      bgColor = _green.withValues(alpha: 0.08);
                      textColor = _green;
                      trailing = const Icon(Icons.check_circle,
                          color: _green, size: 20);
                    } else if (isSelected && !isCorrect) {
                      borderColor = _red;
                      bgColor = _red.withValues(alpha: 0.08);
                      textColor = _red;
                      trailing =
                          const Icon(Icons.cancel, color: _red, size: 20);
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
                        border: Border.all(color: borderColor, width: 1.5),
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
                                ['A', 'B', 'C', 'D'][i],
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
                              question['options'][i],
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
                onPressed: _answered ? nextQuestion : null,
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
