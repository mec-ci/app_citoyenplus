import 'package:citoyen_plus/features/onboarding/onboarding_service.dart';
import 'package:citoyen_plus/services/auth_service.dart';
import 'package:citoyen_plus/ui/accueil.dart';
import 'package:citoyen_plus/ui/login.dart';
import 'package:flutter/material.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Soyez un citoyen actif',
      description:
          'Accédez à un fil d’actualité hybride et signalez facilement les problèmes environnementaux : insalubrité, routes ou éclairage.',
      icon: Icons.public,
    ),
    _OnboardingPageData(
      title: 'Apprenez et Gagnez',
      description:
          'Participez à des quiz civiques sur la Constitution et l’histoire de la Côte d’Ivoire, gagnez des points virtuels et montez dans le classement.',
      icon: Icons.emoji_events,
    ),
    _OnboardingPageData(
      title: 'Infos et documentation',
      description:
          'Consultez la documentation et les infos sur le droit et les institutions ivoiriennes, le tout disponible en un seul endroit.',
      icon: Icons.menu_book_outlined,
    ),
  ];

  Future<void> _goNext() async {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
      return;
    }

    await OnboardingService.setOnboardingSeen();
    if (!mounted) return;

    final authenticated = await AuthService.isAuthenticated();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            authenticated ? const Home() : const LoginView(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            height: 144,
            width: 144,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E6),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(page.icon, size: 72, color: const Color(0xFFE65C00)),
          ),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bienvenue',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1556B5),
                      fontSize: 22,
                    ),
                  ),
                  TextButton(
                    onPressed: _goNext,
                    child: Text(
                      _currentIndex == _pages.length - 1
                          ? 'Commencer'
                          : 'Passer',
                      style: const TextStyle(color: Color(0xFF1556B5)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (_, index) => _buildPage(_pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? const Color(0xFFE65C00)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1556B5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _currentIndex == _pages.length - 1 ? 'Commencer' : 'Suivant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
