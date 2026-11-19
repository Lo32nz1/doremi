import 'dart:io';
import 'package:flutter/foundation.dart';

/// Modelo principal de una canción con soporte para formato ChordPro (.cho).
class Song {
  final String id;
  final String title;
  final String artist;
  final String baseKey;
  final String content;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.baseKey,
    required this.content,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? baseKey,
    String? content,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      baseKey: baseKey ?? this.baseKey,
      content: content ?? this.content,
    );
  }

  /// Convierte la canción a texto con formato estándar ChordPro (.cho).
  String toChordPro() {
    final buffer = StringBuffer()
      ..writeln('{title: $title}')
      ..writeln('{artist: $artist}')
      ..writeln('{key: $baseKey}')
      ..writeln()
      ..write(content.trim());
    return buffer.toString();
  }

  /// Nombre de archivo sugerido con extensión .cho.
  String get suggestedFileName {
    final sanitized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${sanitized.isEmpty ? 'cancion' : sanitized}.cho';
  }

  /// Crea una instancia de [Song] a partir del contenido de un archivo .cho (ChordPro).
  factory Song.fromChordPro(String rawContent, {String? customId}) {
    String title = 'Canción importada';
    String artist = 'Artista desconocido';
    String baseKey = 'Do';
    final contentLines = <String>[];

    final directiveRegex = RegExp(r'^\s*\{\s*([a-zA-Z_]+)\s*:\s*(.+?)\s*\}\s*$');

    for (final line in rawContent.split(RegExp(r'\r?\n'))) {
      final match = directiveRegex.firstMatch(line);
      if (match != null) {
        final key = match.group(1)!.toLowerCase();
        final value = match.group(2)!.trim();
        if (key == 'title' || key == 't') {
          title = value;
        } else if (key == 'artist' || key == 'subtitle' || key == 'st') {
          artist = value;
        } else if (key == 'key' || key == 'k') {
          baseKey = value;
        }
      } else {
        contentLines.add(line);
      }
    }

    return Song(
      id: customId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      baseKey: baseKey,
      content: contentLines.join('\n').trim(),
    );
  }
}

/// Repositorio y servicio en memoria para gestionar el cancionero y exportar/importar .cho.
class SongRepository extends ChangeNotifier {
  SongRepository._internal();

  static final SongRepository instance = SongRepository._internal();

  final List<Song> _songs = [
    const Song(
      id: 'song-1',
      title: 'De Música Ligera',
      artist: 'Soda Stereo',
      baseKey: 'Si m',
      content: '''[Si m]Ella durmió [Sol]al calor de las [Re]masas [La]
[Si m]Y yo desperté [Sol]queriendo soñar[Re]la [La]
[Si m]Algún tiempo a[Sol]trás pensé en escri[Re]birle [La]
[Si m]Que nunca sor[Sol]tió las trampas del [Re]amor [La]

[Si m]De aquel amor [Sol]de música li[Re]gera [La]
[Si m]Nada nos libra, [Sol]nada más que[Re]da [La]''',
    ),
    const Song(
      id: 'song-2',
      title: 'Flaca',
      artist: 'Andrés Calamaro',
      baseKey: 'Sol',
      content: '''[Sol]Flaca, [Si]no me claves
[Mi m]tus puñales [Do]por la espalda
[Sol]tan profundo, [Re]no me duelen,
[Sol]no me hacen [Re]mal.

[Sol]Lejos, [Si]en el centro
[Mi m]de la tierra, [Do]las raíces
[Sol]del amor, [Re]donde estaban
[Sol]quedarán. [Re]''',
    ),
    const Song(
      id: 'song-3',
      title: 'Cielito Lindo',
      artist: 'Tradicional',
      baseKey: 'Do',
      content: '''[Do]De la Sierra Mo[La m]rena,
cielito [Re m]lindo, vienen ba[Sol]jando,
un par de ojitos [Do]negros,
cielito [Fa]lindo, de contra[Sol]bando. [Do]

[Fa]Ay, ay, ay, [Sol]ay,
[Do]canta y no [La m]llores,
porque can[Re m]tando se alegran,
cielito [Sol]lindo, los cora[Do]zones.''',
    ),
  ];

  List<Song> get songs => List.unmodifiable(_songs);

  Song? findById(String id) {
    for (final song in _songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  void addSong(Song song) {
    _songs.insert(0, song);
    notifyListeners();
  }

  void updateSong(Song updated) {
    final index = _songs.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _songs[index] = updated;
      notifyListeners();
    }
  }

  void deleteSong(String id) {
    _songs.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Importa una canción desde contenido en texto formato ChordPro (.cho).
  Song importFromChordProContent(String choContent) {
    final song = Song.fromChordPro(choContent);
    addSong(song);
    return song;
  }

  /// Exporta una canción a un archivo físico `.cho` en el directorio temporal del sistema
  /// (o en la ruta indicada) y devuelve la ruta generada.
  Future<String> exportSongToFile(Song song, {String? customDirectoryPath}) async {
    final directoryPath = customDirectoryPath ?? Directory.systemTemp.path;
    final filePath =
        '$directoryPath${Platform.pathSeparator}${song.suggestedFileName}';
    final file = File(filePath);
    await file.writeAsString(song.toChordPro());
    return file.path;
  }

  /// Importa una canción leyendo un archivo `.cho` desde una ruta local.
  Future<Song> importSongFromFile(String filePath) async {
    final file = File(filePath);
    final raw = await file.readAsString();
    return importFromChordProContent(raw);
  }
}

