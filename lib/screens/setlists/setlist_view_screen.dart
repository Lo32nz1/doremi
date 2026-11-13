import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/setlist_provider.dart';
import '../song_view_screen.dart';

class SetlistViewScreen extends StatefulWidget {
  final String setlistId;

  const SetlistViewScreen({super.key, required this.setlistId});

  @override
  State<SetlistViewScreen> createState() => _SetlistViewScreenState();
}

class _SetlistViewScreenState extends State<SetlistViewScreen> {
  String? _selectedSongPath;

  SongMetadata _metadataForPath(String path, LibraryProvider library) {
    return library.songs.where((song) => song.filePath == path).firstOrNull ??
        SongMetadata(
          title: path.split(Platform.pathSeparator).last,
          artist: '',
          key: '',
          filePath: path,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SetlistProvider, LibraryProvider>(
      builder: (context, setlistProvider, libraryProvider, _) {
        final matchingSetlists = setlistProvider.setlists.where(
          (setlist) => setlist.id == widget.setlistId,
        );
        if (matchingSetlists.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Setlist no encontrado')),
            body: const Center(child: Text('Este setlist ya no existe.')),
          );
        }

        final setlist = matchingSetlists.first;
        if (_selectedSongPath case final selectedPath?
            when setlist.songPaths.contains(selectedPath)) {
          final index = setlist.songPaths.indexOf(selectedPath);
          final song = _metadataForPath(selectedPath, libraryProvider);

          return SongViewScreen(
            key: ValueKey(selectedPath),
            metadata: song,
            showBackButton: false,
            mobilePortrait: true,
            hideSongPanel: true,
            backButtonTooltip: 'Volver a ${setlist.name}',
            onBackToSongList: () => setState(() => _selectedSongPath = null),
            onPreviousSong: index > 0
                ? () => setState(
                    () => _selectedSongPath = setlist.songPaths[index - 1],
                  )
                : null,
            onNextSong: index < setlist.songPaths.length - 1
                ? () => setState(
                    () => _selectedSongPath = setlist.songPaths[index + 1],
                  )
                : null,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.queue_music,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    setlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          body: setlist.songPaths.isEmpty
              ? Center(
                  child: Text(
                    'Setlist vacío.\nAñade canciones desde el Estudio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                      fontSize: 16,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: setlist.songPaths.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setlistProvider.reorderSongs(
                      setlist.id,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final songPath = setlist.songPaths[index];
                    final song = _metadataForPath(songPath, libraryProvider);
                    final colorScheme = Theme.of(context).colorScheme;

                    return Padding(
                      key: ValueKey(songPath),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Material(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.drag_handle,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                              ),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                          trailing: IconButton(
                            tooltip: 'Quitar del setlist',
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.48,
                              ),
                            ),
                            onPressed: () {
                              setlistProvider.removeSongFromSetlist(
                                setlist.id,
                                songPath,
                              );
                            },
                          ),
                          onTap: () =>
                              setState(() => _selectedSongPath = songPath),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
