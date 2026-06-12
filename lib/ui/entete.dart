import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'profil_view.dart';

class EntetePersonalise extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationPressed;

  const EntetePersonalise({super.key, this.onNotificationPressed});

  static const _orange = Color(0xFFFF7F00);
  static const _blue = Color(0xFF1556B5);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,

      // ── Logo ────────────────────────────────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: Image.asset('assets/logo_MEC_1.png', fit: BoxFit.contain),
      ),

      // ── Titre app ────────────────────────────────────────────────────
      title: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_orange, _blue],
        ).createShader(bounds),
        child: const Text(
          'Citoyen +',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),

      actions: [
        // ── Bouton Profil ──────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilView()),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, size: 22, color: _blue),
          ),
        ),

        const SizedBox(width: 8),

        // ── Bouton Notifications ───────────────────────────────────────
        GestureDetector(
          onTap: onNotificationPressed,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              child: const Icon(Icons.send_outlined, size: 22, color: _orange),
            ),
          ),
        ),

        const SizedBox(width: 12),
      ],

      // ── Ligne de séparation dégradée ──────────────────────────────────
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange, _blue],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);
}