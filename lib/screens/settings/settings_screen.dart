import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<LibraryProvider, SettingsProvider>(
        builder: (context, library, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                child: Text(
                  'Configuración',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),

              // ── Biblioteca ───────────────────────────────────────────────
              _buildSection(
                context,
                title: 'Biblioteca',
                icon: Icons.folder_outlined,
                children: [
                  if (library.hasLibrary) ...[
                    _infoRow(
                      context,
                      'Carpeta actual',
                      library.libraryPath!.split('/').last,
                      subtitle: library.libraryPath,
                    ),
                    _divider(context),
                    _infoRow(context, 'Canciones encontradas', '${library.songs.length}'),
                    _divider(context),
                    _infoRow(context, 'Categorías (carpetas)', '${library.songsByCategory.length}'),
                    _divider(context),
                  ],
                  _actionButton(
                    context,
                    label: library.hasLibrary ? 'Cambiar carpeta' : 'Elegir carpeta',
                    icon: Icons.folder_open,
                    onTap: library.pickLibraryFolder,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Visualización ─────────────────────────────────────────────
              _buildSection(
                context,
                title: 'Visualización de canciones',
                icon: Icons.text_fields_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tamaño de letra', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70), fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${settings.fontSize.round()} px',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 24,
                    divisions: 6,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    onChanged: settings.setFontSize,
                  ),
                  _divider(context),
                  _switchRow(
                    context,
                    label: 'Mostrar acordes por defecto',
                    subtitle: 'Al abrir una canción, se ven los acordes',
                    value: settings.showChords,
                    onChanged: settings.setShowChords,
                  ),
                  _divider(context),
                  _switchRow(
                    context,
                    label: 'Tema oscuro',
                    subtitle: 'Utilizar colores oscuros en la aplicación',
                    value: settings.isDarkMode,
                    onChanged: (_) => settings.toggleTheme(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Acerca de ─────────────────────────────────────────────────
              _buildSection(
                context,
                title: 'Acerca de',
                icon: Icons.info_outline,
                children: [
                  _infoRow(context, 'Versión', '1.0.0'),
                  _divider(context),
                  _infoRow(context, 'Formatos soportados', '.chord  .pro  .txt'),
                  _divider(context),
                  _infoRow(context, 'Sincronización', 'Syncthing (local)'),
                ],
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70), fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _switchRow(BuildContext context, {
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70), fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14)),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), indent: 16, endIndent: 16);
}
