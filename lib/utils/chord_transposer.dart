import '../models/song.dart';

/// Sistema de notación para mostrar acordes y tonalidades.
enum ChordNotation {
  /// Cifrado americano: C, D, E, F, G, A, B
  american,

  /// Cifrado latino: Do, Re, Mi, Fa, Sol, La, Si
  latin,
}

class ChordTransposer {
  static const _americanSharps = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  static const _americanFlats = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  static const _latinSharps = [
    'Do',
    'Do#',
    'Re',
    'Re#',
    'Mi',
    'Fa',
    'Fa#',
    'Sol',
    'Sol#',
    'La',
    'La#',
    'Si',
  ];
  static const _latinFlats = [
    'Do',
    'Reb',
    'Re',
    'Mib',
    'Mi',
    'Fa',
    'Solb',
    'Sol',
    'Lab',
    'La',
    'Sib',
    'Si',
  ];

  static const Map<String, int> _noteToSemitone = {
    'C': 0,
    'B#': 0,
    'DO': 0,
    'SI#': 0,
    'C#': 1,
    'DB': 1,
    'DO#': 1,
    'REB': 1,
    'D': 2,
    'RE': 2,
    'D#': 3,
    'EB': 3,
    'RE#': 3,
    'MIB': 3,
    'E': 4,
    'FB': 4,
    'MI': 4,
    'FAB': 4,
    'F': 5,
    'E#': 5,
    'FA': 5,
    'MI#': 5,
    'F#': 6,
    'GB': 6,
    'FA#': 6,
    'SOLB': 6,
    'G': 7,
    'SOL': 7,
    'G#': 8,
    'AB': 8,
    'SOL#': 8,
    'LAB': 8,
    'A': 9,
    'LA': 9,
    'A#': 10,
    'BB': 10,
    'LA#': 10,
    'SIB': 10,
    'B': 11,
    'CB': 11,
    'SI': 11,
    'DOB': 11,
  };

  /// Reconoce raíces en cifrado latino (Do, Re, Mi, Fa, Sol, La, Si) o
  /// americano (A-G), con alteración opcional (#, b, ♯, ♭) y paréntesis inicial
  /// opcional. El lookahead en `Fa` evita confundir `Fadd9`, `Faug` o `Falt`
  /// (acordes de F americano) con `Fa` latino.
  static final RegExp _chordPartRegex = RegExp(
    r'^(\s*\(?)(Sol|Do|Re|Mi|Fa(?!dd|ug|lt)|La|Si|[A-G])([#b♯♭]?)(.*)$',
    caseSensitive: false,
  );

  /// Indica si una tonalidad o acorde usa bemol en su raíz (ej. `Bb`, `Sib`, `Ebm`).
  static bool usesFlatNotation(String chord) {
    final match = _chordPartRegex.firstMatch(chord);
    if (match == null) return false;
    final accidental = match.group(3)!;
    return accidental == 'b' || accidental == 'B' || accidental == '♭';
  }

  /// Convierte un acorde o tonalidad a la [notation] indicada sin transponerlo,
  /// respetando sostenidos y bemoles originales.
  static String formatChord(
    String chord, {
    ChordNotation notation = ChordNotation.american,
  }) {
    return transposeChord(
      chord,
      0,
      notation: notation,
      preserveAccidentals: true,
    );
  }

  static List<String> _scaleFor({
    required bool useFlats,
    required ChordNotation notation,
  }) {
    return switch (notation) {
      ChordNotation.american => useFlats ? _americanFlats : _americanSharps,
      ChordNotation.latin => useFlats ? _latinFlats : _latinSharps,
    };
  }

  /// Transpone un acorde (escrito en cifrado americano o latino) y lo formatea
  /// en la [notation] elegida.
  static String transposeChord(
    String chord,
    int steps, {
    bool useFlats = false,
    ChordNotation notation = ChordNotation.american,
    bool preserveAccidentals = false,
  }) {
    final trimmed = chord.trim();
    if (trimmed.isEmpty ||
        trimmed.toUpperCase() == 'N.C.' ||
        trimmed.toUpperCase() == 'NC') {
      return chord;
    }

    String processPart(String part) {
      final match = _chordPartRegex.firstMatch(part);
      if (match == null) return part;

      final prefix = match.group(1)!;
      final rawRoot = match.group(2)!;
      final rawAccidental = match.group(3)!;
      final mod = match.group(4)!;

      final normalizedAccidental = switch (rawAccidental) {
        '#' || '♯' => '#',
        'b' || 'B' || '♭' => 'B',
        _ => '',
      };

      final lookupKey = '${rawRoot.toUpperCase()}$normalizedAccidental';
      final index = _noteToSemitone[lookupKey];
      if (index == null) return part;

      var newIndex = (index + steps) % 12;
      if (newIndex < 0) newIndex += 12;

      final partUseFlats = preserveAccidentals && steps == 0
          ? normalizedAccidental == 'B'
          : useFlats;
      final scale = _scaleFor(useFlats: partUseFlats, notation: notation);

      return '$prefix${scale[newIndex]}$mod';
    }

    return chord.split('/').map(processPart).join('/');
  }

  static Song transposeSong(
    Song song,
    int steps, {
    bool useFlats = false,
    ChordNotation notation = ChordNotation.american,
    bool preserveAccidentals = false,
  }) {
    final newSections = song.sections.map((sec) {
      final newLines = sec.lines.map((line) {
        final newChunks = line.chunks.map((chk) {
          if (chk.chord != null && chk.chord!.isNotEmpty) {
            return SongChunk(
              lyrics: chk.lyrics,
              chord: transposeChord(
                chk.chord!,
                steps,
                useFlats: useFlats,
                notation: notation,
                preserveAccidentals: preserveAccidentals,
              ),
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

    var newKey = song.metadata.key;
    if (newKey.isNotEmpty) {
      newKey = transposeChord(
        newKey,
        steps,
        useFlats: useFlats,
        notation: notation,
        preserveAccidentals: preserveAccidentals,
      );
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
