import 'package:flutter/material.dart';

class CivixBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CivixBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFE65C00),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_outlined),
          label: 'Signalements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism_outlined),
          label: 'Actions',
        ),
      ],
    );
  }
}
