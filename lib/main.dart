// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'auth/auth_wrapper.dart';
import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/unknown-route-screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // INTL LOCALIZATION
  await initializeDateFormatting('uz_UZ', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('ru_RU', null);

  runApp(const MedlineApp());
}

class MedlineApp extends StatelessWidget {
  const MedlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MEDLINE',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,          // Har doim light theme
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0077B6),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF0F7FF),
              canvasColor: Colors.white,          // Dropdown foni
              cardColor: Colors.white,            // Card foni
              dialogBackgroundColor: Colors.white,// Dialog foni
              popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              textTheme: const TextTheme(
                bodyLarge:   TextStyle(color: Color(0xFF023E8A)),
                bodyMedium:  TextStyle(color: Color(0xFF023E8A)),
                bodySmall:   TextStyle(color: Color(0xFF5E8DB8)),
                titleLarge:  TextStyle(color: Color(0xFF023E8A), fontWeight: FontWeight.w700),
                titleMedium: TextStyle(color: Color(0xFF023E8A)),
              ),
              listTileTheme: const ListTileThemeData(textColor: Color(0xFF023E8A)),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF5F9FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD0E8FF), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                labelStyle: const TextStyle(color: Color(0xFF5E8DB8)),
              ),
              dropdownMenuTheme: const DropdownMenuThemeData(
                menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
              ),
            ),
            home: const LoginScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/auth': (_) => const AuthWrapper(),
            },
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (_) => const UnknownRouteScreen(),
            ),
          );
        },
      ),
    );
  }
}