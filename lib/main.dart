import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/library_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/setlist_provider.dart';
import 'screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SetlistProvider()..loadSetlists()),
      ],
      child: const CancioneroApp(),
    ),
  );
}

class CancioneroApp extends StatelessWidget {
  const CancioneroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Cancionero',
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF5A623),
              secondary: Color(0xFFE8845C),
              surface: Colors.white,
              surfaceContainer: Color(0xFFE5E7EB),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF3F4F6),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D0D1A),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF5A623),
              secondary: Color(0xFFE8845C),
              surface: Color(0xFF1A1A2E),
              surfaceContainer: Color(0xFF16213E), // Previously used hardcoded
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D0D1A),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            useMaterial3: true,
          ),
          home: const ShellScreen(),
        );
      },
    );
  }
}
