import 'package:flutter/material.dart';
import 'library/library_screen.dart';
import 'setlists/setlists_screen.dart';
import 'settings/settings_screen.dart';
import 'song_view_screen.dart';
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

  static const _tabs = [
    _TabDef(icon: Icons.library_music_outlined, activeIcon: Icons.library_music, label: 'Canciones'),
    _TabDef(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories, label: 'Estudio'),
    _TabDef(icon: Icons.graphic_eq_outlined, activeIcon: Icons.graphic_eq, label: 'Afinador'),
    _TabDef(icon: Icons.queue_music_outlined, activeIcon: Icons.queue_music, label: 'Setlists'),
    _TabDef(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Configuración'),
  ];

  static const _screens = [
    LibraryScreen(),
    SizedBox(), // Placeholder para Estudio (nunca se muestra en IndexedStack)
    SizedBox(), // Placeholder para Afinador (se navega con push)
    SetlistsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return isWide ? _buildWideLayout() : _buildNarrowLayout();
  }

  // ─── Layout móvil (barra abajo) ───────────────────────────────────────────

  Widget _buildNarrowLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SongViewScreen()));
            return;
          }
          if (i == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TunerScreen()));
            return;
          }
          setState(() => _selectedIndex = i);
        },
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon, color: Theme.of(context).colorScheme.primary),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  // ─── Layout desktop (barra lateral) ───────────────────────────────────────

  Widget _buildWideLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              if (i == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SongViewScreen()));
                return;
              }
              if (i == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TunerScreen()));
                return;
              }
              setState(() => _selectedIndex = i);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
            selectedLabelTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12),
            leading: const _RailHeader(),
            destinations: _tabs
                .map((t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label),
                    ))
                .toList(),
          ),
          VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
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
  const _TabDef({required this.icon, required this.activeIcon, required this.label});
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
            'Cancionero',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
