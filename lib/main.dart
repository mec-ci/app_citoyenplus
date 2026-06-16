import 'package:citoyen_plus/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'citoyen+',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFFF7F00), // Orange principal
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: const Color(0xFFFF7F00),
            secondary: const Color(0xFF1556B5), // Bleu secondaire
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFF7F00),
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
            selectedItemColor: Color(0xFFFF7F00),
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
        home: SplashScreen(),
      ),
    );
  }
}
