import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late double _fontSize;
  late bool _showChords;
  late bool _isDarkMode;
  final SharedPreferences _prefs;

  double get fontSize => _fontSize;
  bool get showChords => _showChords;
  bool get isDarkMode => _isDarkMode;

  SettingsProvider(this._prefs) {
    _fontSize = _prefs.getDouble('font_size') ?? 16;
    _showChords = _prefs.getBool('show_chords') ?? true;
    _isDarkMode = _prefs.getBool('is_dark_mode') ?? true;
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    await _prefs.setDouble('font_size', size);
  }

  Future<void> setShowChords(bool value) async {
    _showChords = value;
    notifyListeners();
    await _prefs.setBool('show_chords', value);
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _prefs.setBool('is_dark_mode', _isDarkMode);
  }
}
