import 'package:flutter/material.dart';

class EntetePersonalise extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
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
