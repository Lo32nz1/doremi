import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/setlist_provider.dart';
import '../../providers/library_provider.dart';
import '../../models/song.dart';
import '../song_view_screen.dart';

class SetlistViewScreen extends StatelessWidget {
  final String setlistId;

  const SetlistViewScreen({super.key, required this.setlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SetlistProvider, LibraryProvider>(
      builder: (context, setlistProvider, libraryProvider, child) {
        final setlists = setlistProvider.setlists.where((s) => s.id == setlistId);
        if (setlists.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Setlist no encontrado')),
            body: const Center(child: Text('Este setlist ya no existe.')),
          );
        }

        final setlist = setlists.first;

        return Scaffold(
          appBar: AppBar(
            title: Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: setlist.songPaths.isEmpty
              ? Center(
                  child: Text(
                    'Setlist vacío.\nAñade canciones desde la vista de canciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: setlist.songPaths.length,
                  onReorder: (oldIndex, newIndex) {
                    setlistProvider.reorderSongs(setlist.id, oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final songPath = setlist.songPaths[index];
                    final songMetadata = libraryProvider.songs.where((s) => s.filePath == songPath).firstOrNull;

                    return ListTile(
                      key: ValueKey(songPath),
                      leading: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                      title: Text(
                        songMetadata?.displayTitle ?? songPath.split(Platform.pathSeparator).last,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: songMetadata?.artist != null
                          ? Text(songMetadata!.artist!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)))
                          : null,
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        onPressed: () {
                          setlistProvider.removeSongFromSetlist(setlist.id, songPath);
                        },
                      ),
                      onTap: () {
                        final meta = songMetadata ?? SongMetadata(
                          title: songPath.split(Platform.pathSeparator).last,
                          artist: '',
                          key: '',
                          filePath: songPath,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongViewScreen(metadata: meta),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
