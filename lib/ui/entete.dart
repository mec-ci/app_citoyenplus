import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

      // Le titre de la page n'est plus affiché (top bar allégée).
      title: null,
      actions: [
        // Recherche et notifications retirées de la top bar ; les points sont
        // désormais consultables dans le profil.
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
