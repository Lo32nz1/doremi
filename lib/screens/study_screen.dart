import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../utils/song_dialogs.dart';
import '../widgets/song_card.dart';
import 'song_view_screen.dart';

class StudyScreen extends StatefulWidget {
  final ValueChanged<bool>? onReaderVisibilityChanged;

  const StudyScreen({super.key, this.onReaderVisibilityChanged});

  @override
  State<StudyScreen> createState() => StudyScreenState();
}

class StudyScreenState extends State<StudyScreen> {
  static const _phoneShortestSide = 600.0;
  static const _tabletLandscapeMaxWidth = 1400.0;

  final _pageController = PageController();
  late final TextEditingController _searchController;
  SongMetadata? _selectedSong;
  bool _isShowingReader = false;

  bool get _usesPages {
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.shortestSide < _phoneShortestSide;
    final isTabletLandscape =
        size.shortestSide >= _phoneShortestSide &&
        size.width > size.height &&
        size.width < _tabletLandscapeMaxWidth;
    return isPhone || isTabletLandscape;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<LibraryProvider>().searchQuery,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void openSong(SongMetadata song) {
    setState(() => _selectedSong = song);
    if (_usesPages) {
      _showReader();
    }
  }

  void _selectSong(SongMetadata song) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedSong = song);
    _showReader();
  }

  void _showReader() {
    if (!_usesPages) return;
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSongList() {
    if (!_usesPages) return;
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void showSongList() => _showSongList();

  void _onPageChanged(int page) {
    final isShowingReader = page == 1;
    if (_isShowingReader == isShowingReader) return;
    _isShowingReader = isShowingReader;
    widget.onReaderVisibilityChanged?.call(isShowingReader);
  }

  @override
  Widget build(BuildContext context) {
    if (!_usesPages) {
      return SongViewScreen(
        key: ValueKey(_selectedSong?.filePath),
        metadata: _selectedSong,
        showBackButton: false,
        hideSongPanel: false,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildSongListPage(),
          SongViewScreen(
            key: ValueKey(_selectedSong?.filePath),
            metadata: _selectedSong,
            mobilePortrait: true,
            hideSongPanel: true,
            onBackToSongList: _showSongList,
          ),
        ],
      ),
    );
  }

  Widget _buildSongListPage() {
    return Consumer<LibraryProvider>(
      builder: (context, library, _) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Estudio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (library.hasLibrary)
                      IconButton(
                        tooltip: 'Actualizar canciones',
                        onPressed: library.refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    IconButton(
                      tooltip: library.hasLibrary
                          ? 'Nueva canción'
                          : 'Elegir carpeta de canciones',
                      onPressed: library.hasLibrary
                          ? () => SongDialogs.showNewSongDialog(
                              context,
                              library,
                              onSongCreated: openSong,
                            )
                          : library.pickLibraryFolder,
                      icon: Icon(
                        library.hasLibrary ? Icons.add : Icons.folder_open,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (library.hasLibrary) _buildSearchBar(library),
              if (library.hasLibrary && !library.isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${library.filteredSongs.length} canciones',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              Expanded(child: _buildSongList(library)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(LibraryProvider library) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: library.setSearchQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar canciones o artistas...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _searchController.clear();
                    library.setSearchQuery('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSongList(LibraryProvider library) {
    if (library.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!library.hasLibrary) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Elegí la carpeta de tus canciones para empezar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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
    if (library.songs.isEmpty) {
      return const Center(
        child: Text('No se encontraron canciones en esta carpeta.'),
      );
    }
    if (library.filteredSongs.isEmpty) {
      return const Center(child: Text('No hay canciones que coincidan.'));
    }

    final categories = library.songsByCategory.entries.toList();
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        for (final category in categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.key == 'General' ? 'Canciones' : category.key,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${category.value.length}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          for (final song in category.value)
            SongCard(
              key: ValueKey(song.filePath),
              song: song,
              onTap: () => _selectSong(song),
            ),
        ],
      ],
    );
  }
}
