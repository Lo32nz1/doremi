import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../screens/song_view_screen.dart';

class SongDialogs {
  static void showNewSongDialog(BuildContext context, LibraryProvider library, {void Function(SongMetadata)? onSongCreated}) {
    if (library.libraryPath == null) return;

    final titleController = TextEditingController();
    String selectedFolder = '/';
    String selectedExtension = '.chord';
    
    final List<String> folders = ['/'];
    final categories = library.songsByCategory.keys.where((k) => k != 'General').toList();
    folders.addAll(categories);
    folders.add('+ Nueva subcarpeta...');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('Nueva Canción'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Título de la canción',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF5A623))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Ubicación:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  DropdownButton<String>(
                    value: selectedFolder,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                    items: folders.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) {
                      if (val == '+ Nueva subcarpeta...') {
                        _askNewFolder(ctx).then((newFolder) {
                          if (newFolder != null && newFolder.isNotEmpty) {
                            setState(() {
                              folders.insert(folders.length - 1, newFolder);
                              selectedFolder = newFolder;
                            });
                          }
                        });
                      } else if (val != null) {
                        setState(() => selectedFolder = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Formato:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  DropdownButton<String>(
                    value: selectedExtension,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                    items: const [
                      DropdownMenuItem(value: '.chord', child: Text('.chord (Recomendado)')),
                      DropdownMenuItem(value: '.pro', child: Text('.pro (ChordPro clásico)')),
                      DropdownMenuItem(value: '.txt', child: Text('.txt (Texto plano)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedExtension = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    await _createNewSong(title, selectedFolder, selectedExtension, library, ctx, context, onSongCreated);
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        }
      ),
    );
  }

  static Future<String?> _askNewFolder(BuildContext context) {
    final cFilter = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Nueva subcarpeta', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: cFilter,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nombre de la carpeta',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A623), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, cFilter.text.trim()),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static Future<void> _createNewSong(String title, String folder, String extension, LibraryProvider library, BuildContext dialogContext, BuildContext originalContext, void Function(SongMetadata)? onSongCreated) async {
    if (library.libraryPath == null) return;
    
    Navigator.pop(dialogContext); // Close dialog

    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\u00C0-\u017F]'), '').replaceAll(RegExp(r'\s+'), '_');
    final filename = '$cleanTitle$extension';
    
    try {
      Directory targetDir;
      if (folder == '/' || folder == 'General') {
        targetDir = Directory(library.libraryPath!);
      } else {
        targetDir = Directory(p.join(library.libraryPath!, folder));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }
      
      final path = p.normalize(p.join(targetDir.path, filename));
      final file = File(path);
      
      if (!await file.exists()) {
        final initialContent = '{title: $title}\n{artist: }\n\n[Verse 1]\n';
        await file.writeAsString(initialContent);
        await library.refresh();
      }
      
      final newSongMeta = library.songs.where((s) => p.normalize(s.filePath) == path).firstOrNull;
      if (newSongMeta != null && originalContext.mounted) {
        if (onSongCreated != null) {
          onSongCreated(newSongMeta);
        } else {
          Navigator.push(
            originalContext,
            MaterialPageRoute(builder: (_) => SongViewScreen(metadata: newSongMeta)),
          );
        }
      }
    } catch (e) {
      if (originalContext.mounted) {
        final platformMsg = Platform.isAndroid 
            ? 'Android denegó el acceso. Asegurate de haber dado permisos de almacenamiento, y que la carpeta no tenga restricciones de sistema.'
            : 'El sistema canceló la orden por falta de permisos en el disco (solo lectura, etc).';

        showDialog(
          context: originalContext,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(originalContext).colorScheme.surface,
            title: const Text('Error al crear archivo'),
            content: Text(
              '$platformMsg\n\nError técnico: $e',
              style: TextStyle(color: Theme.of(originalContext).colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A623), foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    }
  }
}
