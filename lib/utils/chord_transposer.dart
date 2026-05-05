import '../models/song.dart';

class ChordTransposer {
  static const _sharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _flats = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  static String transposeChord(String chord, int steps, {bool useFlats = false}) {
    if (chord.trim().isEmpty || chord.toUpperCase() == 'N.C.') return chord;

    final scale = useFlats ? _flats : _sharps;
    final regex = RegExp(r'^([A-G][b#]?)(.*)$', caseSensitive: false);

    String processRoot(String note) {
      // Normalizar nota a mayúscula inicial (ej: c# -> C#, bb -> Bb)
      final normalized = note.length == 2 
          ? '${note[0].toUpperCase()}${note[1].toLowerCase()}' 
          : note.toUpperCase();

      int index = _sharps.indexOf(normalized);
      if (index == -1) index = _flats.indexOf(normalized);
      
      // Si no es una nota válida (ej: 'H' en alemán, etc), retornamos la base
      if (index == -1) return note;

      int newIndex = (index + steps) % 12;
      if (newIndex < 0) newIndex += 12;
      return scale[newIndex];
    }

    final parts = chord.split('/');
    final transposedParts = parts.map((part) {
      final match = regex.firstMatch(part);
      if (match != null) {
        final root = match.group(1)!;
        final mod = match.group(2)!;
        return processRoot(root) + mod;
      }
      return part;
    }).toList();

    return transposedParts.join('/');
  }

  static Song transposeSong(Song song, int steps, {bool useFlats = false}) {
    // Si steps = 0, igual pasamos por la transposición para forzar sharps/flats si es necesario
    
    final newSections = song.sections.map((sec) {
      final newLines = sec.lines.map((line) {
        final newChunks = line.chunks.map((chk) {
          if (chk.chord != null && chk.chord!.isNotEmpty) {
            return SongChunk(
              lyrics: chk.lyrics,
              chord: transposeChord(chk.chord!, steps, useFlats: useFlats),
            );
          }
          return chk;
        }).toList();
        return SongLine(
          chunks: newChunks, 
          comment: line.comment, 
          inlineRightComment: line.inlineRightComment,
        );
      }).toList();
      return SongSection(name: sec.name, type: sec.type, lines: newLines);
    }).toList();

    String newKey = song.metadata.key;
    if (newKey.isNotEmpty) {
      // La clave principal "Key: G" o similar, la transponemos igual
      newKey = transposeChord(newKey, steps, useFlats: useFlats);
    }

    return Song(
      metadata: SongMetadata(
        title: song.metadata.title,
        artist: song.metadata.artist,
        key: newKey,
        tempo: song.metadata.tempo,
        number: song.metadata.number,
        filePath: song.metadata.filePath,
        category: song.metadata.category,
      ),
      sections: newSections,
    );
  }
}
