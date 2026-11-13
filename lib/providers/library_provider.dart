import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../parsers/chordpro_parser.dart';

class LibraryProvider extends ChangeNotifier {
  static const _recentSongPathsKey = 'recent_song_paths';
  static const _songOpenCountKey = 'song_open_count';
  static const _appOpenCountKey = 'app_open_count';

  String? _libraryPath;
  List<SongMetadata> _songs = [];
  bool _isLoading = false;
  String? _error;
  List<String> _recentSongPaths = [];
  int _songOpenCount = 0;
  int _appOpenCount = 0;
  late final Future<void> _savedStateLoad;

  String? get libraryPath => _libraryPath;
  List<SongMetadata> get songs => _songs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLibrary => _libraryPath != null;
  int get songOpenCount => _songOpenCount;
  int get appOpenCount => _appOpenCount;
  List<SongMetadata> get recentSongs {
    final songsByPath = {for (final song in _songs) song.filePath: song};
    return _recentSongPaths
        .map((path) => songsByPath[path])
        .whereType<SongMetadata>()
        .take(5)
        .toList();
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Canciones filtradas por el texto de búsqueda
  List<SongMetadata> get filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    final q = _searchQuery.toLowerCase();
    return _songs.where((s) => s.searchText.contains(q)).toList();
  }

  /// Canciones agrupadas por categoría (carpeta)
  Map<String, List<SongMetadata>> get songsByCategory {
    final result = <String, List<SongMetadata>>{};
    for (final song in filteredSongs) {
      final cat = song.category ?? 'General';
      result.putIfAbsent(cat, () => []).add(song);
    }
    final sorted = result.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sorted);
  }

  LibraryProvider() {
    _savedStateLoad = _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSongPaths = prefs.getStringList(_recentSongPathsKey) ?? [];
    _songOpenCount = prefs.getInt(_songOpenCountKey) ?? 0;
    _appOpenCount = (prefs.getInt(_appOpenCountKey) ?? 0) + 1;
    await prefs.setInt(_appOpenCountKey, _appOpenCount);
    final path = prefs.getString('library_path');
    if (path != null && Directory(path).existsSync()) {
      _libraryPath = path;
      unawaited(_scanLibrary());
    } else {
      notifyListeners();
    }
  }

  Future<void> recordSongOpened(SongMetadata song) async {
    await _savedStateLoad;
    _recentSongPaths
      ..remove(song.filePath)
      ..insert(0, song.filePath);
    if (_recentSongPaths.length > 5) {
      _recentSongPaths = _recentSongPaths.take(5).toList();
    }
    _songOpenCount++;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSongPathsKey, _recentSongPaths);
    await prefs.setInt(_songOpenCountKey, _songOpenCount);
  }

  /// Abre el diálogo para elegir una carpeta
  Future<void> pickLibraryFolder() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }

      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Elegí la carpeta de canciones',
      );
      if (result != null) {
        _libraryPath = result;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('library_path', result);
        await _scanLibrary();
      }
    } catch (e) {
      _error = 'No se pudo abrir el selector de carpetas: $e';
      notifyListeners();
    }
  }

  /// Escanea la carpeta buscando archivos de canciones
  Future<void> _scanLibrary() async {
    if (_libraryPath == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dir = Directory(_libraryPath!);
      final extensions = {'chord', 'pro', 'chopro', 'chordpro', 'txt'};

      final songFiles = <File>[];
      int entitiesScanned = 0;

      // Usamos stream en vez de toList() para no desbordar RAM si la carpeta es gigante (e.g. disco C: o /)
      final stream = dir.list(recursive: true).handleError((e) => null);

      await for (final entity in stream) {
        entitiesScanned++;
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (extensions.contains(ext)) {
            songFiles.add(entity);
            if (songFiles.length >= 2000) {
              _error =
                  'Límite de 2000 canciones alcanzado. Recomendamos elegir una carpeta más específica.';
              break;
            }
          }
        }
        // Prevención de cuelgues (por ej. si alguien selecciona /home o C:\ entero)
        if (entitiesScanned > 50000) {
          _error =
              'Carpeta demasiado grande. Mostrando las primeras 2000 canciones encontradas.';
          break;
        }
      }

      final paths = songFiles.map((f) => f.path).toList();
      _songs = await compute(ChordProParser.parseBatchMetadata, {
        'paths': paths,
        'libraryPath': _libraryPath,
      });
      _songs.sort(
        (a, b) => a.displayTitle.toLowerCase().compareTo(
          b.displayTitle.toLowerCase(),
        ),
      );
    } catch (e) {
      _error = 'Error al leer la carpeta: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _scanLibrary();

  Future<void> deleteSong(SongMetadata song) async {
    try {
      final file = File(song.filePath);
      if (await file.exists()) {
        await file.delete();
        await refresh();
      }
    } catch (e) {
      _error = 'Error al borrar archivo: $e';
      notifyListeners();
    }
  }
}
