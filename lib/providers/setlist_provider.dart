import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setlist.dart';

class SetlistProvider with ChangeNotifier {
  static const String _storageKey = 'cancionero_setlists';
  List<Setlist> _setlists = [];

  List<Setlist> get setlists => _setlists;

  /// Carga los setlists desde SharedPreferences.
  Future<void> loadSetlists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _setlists = decoded.map((item) => Setlist.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando setlists: $e');
    }
    notifyListeners();
  }

  /// Guarda los setlists actuales en SharedPreferences.
  Future<void> _saveSetlists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(_setlists.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error guardando setlists: $e');
    }
  }

  /// Crea un nuevo Setlist.
  Future<void> createSetlist(String name) async {
    final newSetlist = Setlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      songPaths: [],
    );
    _setlists.add(newSetlist);
    notifyListeners();
    await _saveSetlists();
  }

  /// Elimina un Setlist.
  Future<void> deleteSetlist(String id) async {
    _setlists.removeWhere((s) => s.id == id);
    notifyListeners();
    await _saveSetlists();
  }

  /// Añade una canción a un Setlist.
  Future<void> addSongToSetlist(String setlistId, String songPath) async {
    final index = _setlists.indexWhere((s) => s.id == setlistId);
    if (index >= 0) {
      final setlist = _setlists[index];
      if (!setlist.songPaths.contains(songPath)) {
        setlist.songPaths.add(songPath);
        notifyListeners();
        await _saveSetlists();
      }
    }
  }

  /// Remueve una canción de un Setlist.
  Future<void> removeSongFromSetlist(String setlistId, String songPath) async {
    final index = _setlists.indexWhere((s) => s.id == setlistId);
    if (index >= 0) {
      final setlist = _setlists[index];
      if (setlist.songPaths.contains(songPath)) {
        setlist.songPaths.remove(songPath);
        notifyListeners();
        await _saveSetlists();
      }
    }
  }

  /// Reordena canciones dentro de un Setlist.
  Future<void> reorderSongs(String setlistId, int oldIndex, int newIndex) async {
    final listIndex = _setlists.indexWhere((s) => s.id == setlistId);
    if (listIndex >= 0) {
      final setlist = _setlists[listIndex];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String item = setlist.songPaths.removeAt(oldIndex);
      setlist.songPaths.insert(newIndex, item);
      notifyListeners();
      await _saveSetlists();
    }
  }
}
