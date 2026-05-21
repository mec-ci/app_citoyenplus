import 'package:citoyen_plus/ui/accueil_view.dart';
import 'package:citoyen_plus/ui/mes_actions_view.dart';
import 'package:citoyen_plus/ui/notifications_view.dart';
import 'package:flutter/material.dart';
import '../models/categorie_signalement_model.dart';
import '../widgets/poster_action.dart';
import '../widgets/signalement_sheet.dart';
import 'ai_chat_view.dart';
import 'ajouter_view.dart';
import 'librairie_view.dart';
import 'quiz_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  // ✅ Index étendu :
  // 0 = Accueil, 1 = Quiz, 2 = (bouton +), 3 = Librairie, 4 = IA
  // 5 = Notifications, 6 = MesActions (cachés de la navbar)
  int selectedIndex = 0;

  List<CategorieSignalementModel> categories = [];

  late final List<Widget> pages = [
    AccueilView(onNotificationPressed: () => goTo(5)),
    QuizView(),
    AjouterView(),
    LibrairieView(),
    AiChatView(),
    NotificationView(
      onMesActionsPressed: () => goTo(6),
    ),
    MesActionsView(posts: const [], onBackPressed: () => goTo(5)),
  ];

  void goTo(int index) {
    setState(() => selectedIndex = index);
  }

  void onItemTapped(int index) {
    if (index == 2) {
      showAddOptions();
    } else {
      setState(() => selectedIndex = index);
    }
  }

  // Retourne l'index navbar correspondant (5 et 6 → pas d'onglet sélectionné)
  int get _navIndex {
    if (selectedIndex <= 4) return selectedIndex;
    return 0; // accueil sélectionné par défaut quand on est sur notif/actions
  }

  void showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Que souhaites-tu faire ?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.volunteer_activism, color: Colors.green),
              title: const Text("Poster une action citoyenne"),
              onTap: () {
                Navigator.pop(context);
                showAddPost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.orange),
              title: const Text("Signaler une action citoyenne"),
              onTap: () {
                Navigator.pop(context);
                showSignalementSheet(context, (newSignalement) {
                  setState(() {});
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void showAddPost() {
    showPosterActionSheet(context, () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 26, color: Colors.orange),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_alt_rounded, size: 26, color: Colors.orange),
            label: "Quiz",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded, size: 30, color: Colors.orange),
            label: "Ajouter",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded, size: 26, color: Colors.orange),
            label: "Librairie",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded, size: 26, color: Colors.orange),
            label: "IA",
          ),
        ],
      ),
    );
  }
}