import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/song_dialogs.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<SongMetadata> onOpenSong;
  final VoidCallback onOpenStudy;

  const HomeScreen({
    super.key,
    required this.onOpenSong,
    required this.onOpenStudy,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, library)),
                if (library.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!library.hasLibrary)
                  SliverFillRemaining(child: _buildWelcome(context, library))
                else ...[
                  SliverToBoxAdapter(
                    child: _buildWelcomeCard(context, library),
                  ),
                  SliverToBoxAdapter(child: _buildStatistics(context, library)),
                  SliverToBoxAdapter(
                    child: _buildRecentHeader(context, library),
                  ),
                  if (library.recentSongs.isEmpty)
                    SliverToBoxAdapter(child: _buildNoRecentSongs(context))
                  else
                    SliverList.builder(
                      itemCount: library.recentSongs.length,
                      itemBuilder: (context, index) {
                        final song = library.recentSongs[index];
                        return _buildRecentSong(context, song, index + 1);
                      },
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: OutlinedButton.icon(
                        onPressed: onOpenStudy,
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: const Text('Ir al Estudio'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LibraryProvider library) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: Color(0xFFF5A623), size: 26),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'DOREMI',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ),
          if (library.hasLibrary) ...[
            IconButton(
              tooltip: 'Nueva canción',
              onPressed: () => SongDialogs.showNewSongDialog(
                context,
                library,
                onSongCreated: onOpenSong,
              ),
              icon: const Icon(Icons.add, color: Color(0xFFF5A623)),
            ),
            IconButton(
              tooltip: 'Actualizar biblioteca',
              onPressed: library.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => IconButton(
              tooltip: settings.isDarkMode ? 'Tema claro' : 'Tema oscuro',
              onPressed: settings.toggleTheme,
              icon: Icon(
                settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, LibraryProvider library) {
    final theme = Theme.of(context);
    final recentCount = library.recentSongs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              recentCount == 0
                  ? 'Tu música está lista. Elegí una canción en Estudio para empezar.'
                  : 'Seguí disfrutando de tu música. Estas son tus canciones recientes.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onOpenStudy,
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('Abrir Estudio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, LibraryProvider library) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _StatisticCard(
              icon: Icons.library_music_outlined,
              label: 'Canciones',
              value: '${library.songs.length}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatisticCard(
              icon: Icons.play_circle_outline,
              label: 'Aperturas',
              value: '${library.songOpenCount}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatisticCard(
              icon: Icons.open_in_new,
              label: 'Usos',
              value: '${library.appOpenCount}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHeader(BuildContext context, LibraryProvider library) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Canciones abiertas recientemente',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${library.recentSongs.length}/5',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSong(BuildContext context, SongMetadata song, int number) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: () => onOpenSong(song),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
            foregroundColor: colorScheme.primary,
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            song.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: song.displayArtist.isEmpty
              ? null
              : Text(
                  song.displayArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildNoRecentSongs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'Cuando abras canciones, las vas a encontrar acá.',
        style: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context, LibraryProvider library) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.library_music_outlined,
                size: 64,
                color: Color(0xFFF5A623),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Bienvenido a DOREMI!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Elegí la carpeta donde guardás tus canciones para empezar.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: library.pickLibraryFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Elegir carpeta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: colorScheme.primary),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}
