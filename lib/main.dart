import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const DoReMiApp());
}

/// Aplicación principal Do Re Mi con tema oscuro Material 3 de alto contraste
/// optimizado para lectura de letras y acordes en escenarios.
class DoReMiApp extends StatelessWidget {
  const DoReMiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFB300), // Ámbar dorado de alto contraste sobre fondo oscuro
      brightness: Brightness.dark,
      surface: const Color(0xFF101216),
    );

    return MaterialApp(
      title: 'Do Re Mi',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14171D),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF14171D),
          indicatorColor: colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
