import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import 'home_screen.dart';
import 'setlists/setlists_screen.dart';
import 'settings/settings_screen.dart';
import 'study_screen.dart';
import 'tuner/tuner_screen.dart';

/// Pantalla contenedora con navegación adaptativa.
/// - Pantalla angosta (móvil): BottomNavigationBar
/// - Pantalla ancha (desktop): NavigationRail lateral
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;
  bool _isShowingStudyReader = false;
  final _studyKey = GlobalKey<StudyScreenState>();

  static const _tabs = [
    _TabDef(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    _TabDef(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: 'Estudio',
    ),
    _TabDef(
      icon: Icons.graphic_eq_outlined,
      activeIcon: Icons.graphic_eq,
      label: 'Afinador',
    ),
    _TabDef(
      icon: Icons.queue_music_outlined,
      activeIcon: Icons.queue_music,
      label: 'Setlists',
    ),
    _TabDef(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Configuración',
    ),
  ];

  List<Widget> get _screens => [
    HomeScreen(
      onOpenSong: _openSongInStudy,
      onOpenStudy: () => setState(() => _selectedIndex = 1),
    ),
    StudyScreen(
      key: _studyKey,
      onReaderVisibilityChanged: (showingReader) {
        if (_isShowingStudyReader == showingReader) return;
        setState(() => _isShowingStudyReader = showingReader);
      },
    ),
    SizedBox(), // Placeholder para Afinador (se navega con push)
    SetlistsScreen(),
    SettingsScreen(),
  ];

  void _openSongInStudy(SongMetadata song) {
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _studyKey.currentState?.openSong(song);
    });
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar DOREMI?'),
        content: const Text('¿Querés salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.shortestSide < 600;
    final isWide = !isPhone;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return PopScope<void>(
      canPop: !isPhone || !isAndroid,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !isPhone || !isAndroid) {
          return;
        }
        if (_selectedIndex == 1 && _isShowingStudyReader) {
          _studyKey.currentState?.showSongList();
          return;
        }
        unawaited(_confirmExit());
      },
      child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ─── Layout móvil (barra abajo) ───────────────────────────────────────────

  Widget _buildNarrowLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _selectedIndex == 1 && _isShowingStudyReader
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                if (i == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TunerScreen()),
                  );
                  return;
                }
                setState(() => _selectedIndex = i);
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(
                        t.activeIcon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ─── Layout desktop (barra lateral) ───────────────────────────────────────

  Widget _buildWideLayout() {
    final size = MediaQuery.sizeOf(context);
    final hideRailForReader =
        _selectedIndex == 1 &&
        _isShowingStudyReader &&
        size.width < 1400 &&
        size.width > size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (!hideRailForReader) ...[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                if (i == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TunerScreen()),
                  );
                  return;
                }
                setState(() => _selectedIndex = i);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 12,
              ),
              leading: const _RailHeader(),
              destinations: _tabs
                  .map(
                    (t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label),
                    ),
                  )
                  .toList(),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ],
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Logo y nombre en la cabecera del NavigationRail (desktop)
class _RailHeader extends StatelessWidget {
  const _RailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.music_note, color: Color(0xFFF5A623), size: 30),
          const SizedBox(height: 4),
          Text(
            'DOREMI',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
