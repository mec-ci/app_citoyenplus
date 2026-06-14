import 'package:flutter/material.dart';

class CivixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;

  const CivixAppBar({
    super.key,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
      title: const Text(
        'Fil d\'actualité',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    onPressed: onNotificationPressed,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
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
              const SizedBox(width: 14),
              IconButton(
                onPressed: onSearchPressed,
                icon: const Icon(Icons.search_outlined, color: Colors.black87),
              ),
              const SizedBox(width: 14),
              IconButton(
                onPressed: onProfilePressed,
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
