import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../widgets/song_card.dart';
import 'song_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, library),
              if (library.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFF5A623)),
                  ),
                )
              else if (!library.hasLibrary)
                SliverFillRemaining(child: _buildWelcome(context, library))
              else if (library.songs.isEmpty)
                SliverFillRemaining(child: _buildEmpty(context))
              else
                _buildSongList(context, library),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          if (!library.hasLibrary) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: library.pickLibraryFolder,
            tooltip: 'Cambiar carpeta',
            backgroundColor: const Color(0xFFF5A623),
            foregroundColor: Colors.black,
            child: const Icon(Icons.folder_open),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, LibraryProvider library) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF0D0D1A),
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            const Icon(Icons.music_note, color: Color(0xFFF5A623), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Cancionero',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      actions: [
        if (library.hasLibrary)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: library.refresh,
          ),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context, LibraryProvider library) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.library_music_outlined,
                size: 72,
                color: Color(0xFFF5A623),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Bienvenido al Cancionero!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Elegí la carpeta donde tenés tus archivos de canciones (.chord, .pro, .txt)',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: library.pickLibraryFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Elegir carpeta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No se encontraron canciones',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Asegurate de que la carpeta tenga archivos\n.chord, .pro o .txt',
            style: TextStyle(color: Colors.white30, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  SliverList _buildSongList(BuildContext context, LibraryProvider library) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                '${library.songs.length} canciones',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            );
          }
          final song = library.songs[index - 1];
          return SongCard(
            song: song,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SongViewScreen(metadata: song)),
            ),
          );
        },
        childCount: library.songs.length + 1,
      ),
    );
  }
}
