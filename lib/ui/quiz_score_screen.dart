import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);
const _green = Color(0xFF34C759);
const _red = Color(0xFFFF2D55);

class QuizScoreScreen extends StatefulWidget {
  final int score;
  final int total;
  final int totalPoints;
  final bool passed;
  final int level;
  final String categorie;
  final Future<void> Function(bool passed)? onLevelCompleted;
  final List<double> timePerQuestion;
  final List<Map<String, dynamic>> answers;

  const QuizScoreScreen({
    super.key,
    required this.score,
    required this.total,
    required this.totalPoints,
    required this.passed,
    required this.level,
    required this.categorie,
    this.onLevelCompleted,
    this.timePerQuestion = const [],
    this.answers = const [],
  });

  @override
  State<QuizScoreScreen> createState() => _QuizScoreScreenState();
}

class _QuizScoreScreenState extends State<QuizScoreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pointsCtrl;
  late Animation<double> _pointsAnim;
  int _displayPoints = 0;
  late List<_ConfettiParticle> _particles;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(60, (_) => _ConfettiParticle());
    _pointsCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.totalPoints * 15).clamp(800, 2500)),
    );
    _pointsAnim = CurvedAnimation(parent: _pointsCtrl, curve: Curves.easeOutCubic);
    _pointsCtrl.addListener(() {
      setState(() {
        _displayPoints = (_pointsAnim.value * widget.totalPoints).round();
      });
    });
    _pointsCtrl.forward();
    _showConfetti = widget.passed && widget.totalPoints > 0;

    if (widget.passed && widget.level < 3) {
      _unlockNextLevel();
    }
  }

  Future<void> _unlockNextLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiz_${widget.categorie}_${widget.level}_done', true);
    widget.onLevelCompleted?.call(true);
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.score / widget.total * 100).round();

    String emoji;
    String title;
    Color mainColor;
    if (pct >= 80) {
      emoji = '🏆';
      title = 'Excellent !';
      mainColor = _orange;
    } else if (pct >= 60) {
      emoji = '🎉';
      title = 'Niveau réussi !';
      mainColor = _green;
    } else {
      emoji = '💪';
      title = 'Continue à apprendre !';
      mainColor = _red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Résultats',
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_showConfetti)
            CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_particles, _pointsCtrl),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Trophée animé
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(emoji, style: const TextStyle(fontSize: 80)),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: mainColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.score} / ${widget.total}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: mainColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pct% de bonnes réponses',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: widget.score / widget.total,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Points gagnés
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: _orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Points gagnés',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '+$_displayPoints pts',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: _orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Détail rapide
                if (widget.timePerQuestion.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _detailItem(
                          Icons.timer_outlined,
                          'Temps moyen',
                          '${(widget.timePerQuestion.reduce((a, b) => a + b) / widget.timePerQuestion.length).round()}s',
                          _blue,
                        ),
                        _detailItem(
                          Icons.bolt_rounded,
                          'Bonus rapidité',
                          widget.answers
                              .where((a) =>
                                  a['isCorrect'] == true &&
                                  (a['timeSpent'] as int?) != null &&
                                  a['timeSpent'] < 10)
                              .length
                              .toString(),
                          _orange,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Message niveau suivant
                if (widget.passed && widget.level < 3)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: _green, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Niveau ${widget.level + 1} débloqué !',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!widget.passed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Obtiens 60% pour passer au niveau suivant',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),

                // Boutons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                    label: const Text(
                      'Rejouer',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.home_rounded, color: _blue),
                    label: const Text(
                      'Retour aux quiz',
                      style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

// ── Confetti Particle ──────────────────────────────────────────────────────

class _ConfettiParticle {
  double x = Random().nextDouble();
  double y = Random().nextDouble() * -1;
  double speed = 0.003 + Random().nextDouble() * 0.008;
  double size = 4 + Random().nextDouble() * 6;
  Color color = [
    _orange,
    _blue,
    _green,
    Colors.red,
    Colors.amber,
    Colors.purple,
  ][Random().nextInt(6)];
  double rotation = Random().nextDouble() * 2 * pi;
  double rotSpeed = (Random().nextDouble() - 0.5) * 0.1;
  double drift = (Random().nextDouble() - 0.5) * 0.002;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Animation<double> animation;

  _ConfettiPainter(this.particles, this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final now = animation.value;
    for (final p in particles) {
      p.y += p.speed;
      p.x += p.drift + sin(now * 10 + p.rotation) * 0.002;
      p.rotation += p.rotSpeed;

      if (p.y > 1.0) {
        p.y = -0.05;
        p.x = Random().nextDouble();
      }

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
      final cx = p.x * size.width;
      final cy = p.y * size.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
