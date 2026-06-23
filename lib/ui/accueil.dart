import 'package:citoyen_plus/ui/accueil_view.dart';
import 'package:citoyen_plus/ui/mes_actions_view.dart';
import 'package:citoyen_plus/ui/notifications_view.dart';
import 'package:citoyen_plus/ui/profil_view.dart';
import 'package:citoyen_plus/ui/search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/feed/presentation/pages/create_signalement_page.dart';
import '../features/feed/presentation/pages/create_action_page.dart';
import '../features/feed/presentation/providers/feed_provider.dart';
import 'ai_chat_view.dart';
import 'librairie_view.dart';
import 'quiz_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int selectedIndex = 0;

  List<Widget> get pages => [
    AccueilView(
      onNotificationPressed: () => goTo(5),
      onSearchPressed: _goToSearch,
      onProfilePressed: _goToProfile,
    ),
    QuizView(
      onNotificationPressed: _goToNotifications,
      onSearchPressed: _goToSearch,
      onProfilePressed: _goToProfile,
    ),
    LibrairieView(
      onNotificationPressed: _goToNotifications,
      onSearchPressed: _goToSearch,
      onProfilePressed: _goToProfile,
    ),
    AiChatView(
      onNotificationPressed: _goToNotifications,
      onSearchPressed: _goToSearch,
      onProfilePressed: _goToProfile,
    ),
    NotificationView(onMesActionsPressed: () => goTo(5)),
    MesActionsView(posts: const [], onBackPressed: () => goTo(4)),
  ];

  void goTo(int index) {
    setState(() => selectedIndex = index);
  }

  void _goToSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchView()));
  }

  void _goToProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilView()));
  }

  void _goToNotifications() {
    setState(() => selectedIndex = 4);
  }

  void onItemTapped(int index) {
    if (index == 4) {
      showAddOptions();
    } else {
      setState(() => selectedIndex = index);
    }
  }

  int get _navIndex {
    if (selectedIndex <= 3) return selectedIndex;
    return 0;
  }

  void showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Que souhaites-tu faire ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.report_problem_outlined,
              iconColor: const Color(0xFFE65C00),
              title: 'Signaler un probleme',
              subtitle: 'Envoyer un signalement aux autorites',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateSignalementPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.emoji_events_outlined,
              iconColor: const Color(0xFF3B6D11),
              title: 'Partager une action citoyenne',
              subtitle: 'Montrer votre engagement civique',
              onTap: () async {
                Navigator.pop(context);
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateActionPage(
                      onPublished: () {
                        ProviderScope.containerOf(
                          context,
                        ).read(feedProvider.notifier).refresh();
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Accueil',
              selected: _navIndex == 0,
              onTap: () => onItemTapped(0),
            ),
            _NavItem(
              icon: Icons.emoji_events_outlined,
              label: 'Quiz',
              selected: _navIndex == 1,
              onTap: () => onItemTapped(1),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -13),
                  child: GestureDetector(
                    onTap: showAddOptions,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65C00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
            _NavItem(
              icon: Icons.account_balance_outlined,
              label: 'Infos',
              selected: _navIndex == 2,
              onTap: () => onItemTapped(2),
            ),
            _NavItem(
              icon: Icons.smart_toy_outlined,
              label: 'Chatbot',
              selected: _navIndex == 3,
              onTap: () => onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: selected ? const Color(0xFFE65C00) : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? const Color(0xFFE65C00) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
