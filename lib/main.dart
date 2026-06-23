import 'package:citoyen_plus/core/network/error_handler.dart';
import 'package:citoyen_plus/features/auth/presentation/providers/auth_provider.dart';
import 'package:citoyen_plus/services/ai_chat_service.dart';
import 'package:citoyen_plus/services/notification_service.dart';
import 'package:citoyen_plus/ui/accueil.dart';
import 'package:citoyen_plus/ui/login.dart';
import 'package:citoyen_plus/ui/splash_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le fichier .env est optionnel : il est ignoré par git et peut être absent
  // d'un build (ex. APK de CI sans secrets). On ne doit jamais laisser une
  // exception ici empêcher l'appel à runApp(), sinon l'app reste sur un écran
  // blanc au démarrage. isOptional initialise un environnement vide si le
  // fichier manque, et le try/catch couvre tout autre échec (fichier illisible…).
  // Les accès à dotenv.env (AiChatService, ApiConfig) sont eux aussi protégés.
  try {
    await dotenv.load(fileName: 'assets/.env', isOptional: true);
  } catch (e) {
    debugPrint('dotenv load error: $e');
  }
  AiChatService.init();

  try {
    await Firebase.initializeApp()
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await NotificationService.init()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'citoyen+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE65C00),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65C00),
          primary: const Color(0xFFE65C00),
          secondary: const Color(0xFF1556B5),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE65C00),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Metropolis',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Georgia', fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'Georgia', fontSize: 14),
          titleLarge: TextStyle(
            fontFamily: 'Metropolis',
            fontWeight: FontWeight.bold,
          ),
          labelLarge: TextStyle(fontFamily: 'Metropolis'),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFE65C00),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1556B5),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
      navigatorKey: HttpErrorHandler.navigatorKey,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(authProvider.notifier).checkAuth()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        ref.read(authProvider.notifier).logout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.isLoading
        ? const SplashScreen()
        : authState.status == AuthStatus.authenticated
            ? const Home()
            : const LoginView();
  }
}
