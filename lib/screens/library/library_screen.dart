import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/song_dialogs.dart';
import '../../widgets/song_card.dart';
import '../song_view_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, _) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(library),
              if (library.hasLibrary) _buildSearchBar(library),
              Expanded(child: _buildContent(library)),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(LibraryProvider library) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 500;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(20, isSmall ? 10 : 20, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: Color(0xFFF5A623), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cancionero',
              style: TextStyle(fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (ctx, settings, _) => IconButton(
              icon: Icon(settings.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              color: Theme.of(context).colorScheme.primary,
              iconSize: isSmall ? 20 : 24,
              tooltip: 'Cambiar tema',
              onPressed: settings.toggleTheme,
            ),
          ),
          if (library.hasLibrary)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFF5A623)),
              iconSize: isSmall ? 20 : 24,
              tooltip: 'Nueva canción',
              onPressed: () => SongDialogs.showNewSongDialog(context, library),
            ),
          if (library.hasLibrary)
            IconButton(
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              iconSize: isSmall ? 20 : 24,
              tooltip: 'Actualizar biblioteca',
              onPressed: library.refresh,
            ),
        ],
      ),
    );
  }

  // ─── Barra de búsqueda ────────────────────────────────────────────────────

  Widget _buildSearchBar(LibraryProvider library) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (q) {
          library.setSearchQuery(q);
          setState(() => _isSearching = q.isNotEmpty);
        },
        decoration: InputDecoration(
          hintText: 'Buscar canciones o artistas...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 20),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 20),
                  onPressed: () {
                    _searchController.clear();
                    library.setSearchQuery('');
                    setState(() => _isSearching = false);
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
      ),
    );
  }

  // ─── Contenido principal ──────────────────────────────────────────────────

  Widget _buildContent(LibraryProvider library) {
    if (library.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF5A623)));
    }
    if (!library.hasLibrary) return _buildWelcome(library);
    if (library.songs.isEmpty) return _buildEmpty();
    if (_isSearching) return _buildFlatList(library.filteredSongs);
    return _buildGroupedList(library);
  }

  // ─── Vista: bienvenida ────────────────────────────────────────────────────

  Widget _buildWelcome(LibraryProvider library) {
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
              child: const Icon(Icons.library_music_outlined, size: 72, color: Color(0xFFF5A623)),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Bienvenido al Cancionero!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Elegí la carpeta donde tenés tus archivos de canciones (.chord, .pro, .txt)',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14),
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

  // ─── Vista: sin canciones ─────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
          const SizedBox(height: 16),
          Text('No se encontraron canciones', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Asegurate de que la carpeta tenga archivos\n.chord, .pro o .txt',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Vista: lista plana (buscando) ────────────────────────────────────────

  Widget _buildFlatList(List<SongMetadata> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Text('No se encontraron resultados', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: songs.length,
      itemBuilder: (context, i) =>
          SongCard(song: songs[i], onTap: () => _openSong(context, songs[i])),
    );
  }

  // ─── Vista: agrupada por categoría (carpeta) ──────────────────────────────

  Widget _buildGroupedList(LibraryProvider library) {
    final grouped = library.songsByCategory;
    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final songs = grouped[cat]!;
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainer,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: _buildCategoryHeader(cat, songs.length),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              initiallyExpanded: false,
              collapsedIconColor: Theme.of(context).colorScheme.primary,
              iconColor: Theme.of(context).colorScheme.primary,
              children: songs.map((s) => SongCard(song: s, onTap: () => _openSong(context, s))).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(String name, int count) {
    return Row(
      children: [
        const Icon(Icons.folder_outlined, color: Color(0xFFF5A623), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Color(0xFFF5A623),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          '$count ${count == 1 ? "canción" : "canciones"}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
        ),
      ],
    );
  }

  void _openSong(BuildContext context, SongMetadata song) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SongViewScreen(metadata: song)));
  }
}
