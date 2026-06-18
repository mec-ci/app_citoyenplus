import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gamification_provider.dart';

class EntetePersonalise extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;

  const EntetePersonalise({
    super.key,
    this.title = 'Citoyen +',
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(gamificationProvider).totalPoints;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      leadingWidth: 82,

      // ── Logo ────────────────────────────────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: Image.asset('assets/logo_MEC_1.png', fit: BoxFit.contain),
      ),

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      actions: [
        // Badge points
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE65C00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFE65C00), size: 16),
              const SizedBox(width: 3),
              Text(
                '$points pts',
                style: const TextStyle(
                  color: Color(0xFFE65C00),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSearchPressed,
          icon: const Icon(Icons.search_outlined, color: Color(0xFF1556B5)),
          tooltip: 'Rechercher',
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              onPressed: onNotificationPressed,
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1556B5),
              ),
              tooltip: 'Notifications',
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onProfilePressed,
          icon: const Icon(
            Icons.account_circle_outlined,
            color: Color(0xFF1556B5),
          ),
          tooltip: 'Profil',
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE0E0E0)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);
}
