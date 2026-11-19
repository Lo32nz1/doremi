import 'package:flutter/material.dart';

/// Utilidad de teoría musical para transportar acordes por semitonos (+1 / -1).
/// Soporta notación latina (Do, Re, Mi, Fa, Sol, La, Si) y americana (C, D, E, F, G, A, B),
/// acordes menores (m), sostenidos (#), bemoles (b) y acordes con bajo invertido (/).
class ChordTransposer {
  static const List<String> _latinScale = [
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

  static const List<String> _americanScale = [
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

  /// Mapa de notas latinas (ordenadas de mayor a menor longitud para evitar falsos prefijos como Sol vs Si).
  static const Map<String, int> _latinNoteToSemitone = {
    'Sol#': 8,
    'Solb': 6,
    'Sol': 7,
    'Do#': 1,
    'Dob': 11,
    'Do': 0,
    'Re#': 3,
    'Reb': 1,
    'Re': 2,
    'Mi#': 5,
    'Mib': 3,
    'Mi': 4,
    'Fa#': 6,
    'Fab': 4,
    'Fa': 5,
    'La#': 10,
    'Lab': 8,
    'La': 9,
    'Si#': 0,
    'Sib': 10,
    'Si': 11,
  };

  /// Mapa de notas americanas (ordenadas de mayor a menor longitud).
  static const Map<String, int> _americanNoteToSemitone = {
    'C#': 1,
    'Cb': 11,
    'C': 0,
    'D#': 3,
    'Db': 1,
    'D': 2,
    'E#': 5,
    'Eb': 3,
    'E': 4,
    'F#': 6,
    'Fb': 4,
    'F': 5,
    'G#': 8,
    'Gb': 6,
    'G': 7,
    'A#': 10,
    'Ab': 8,
    'A': 9,
    'B#': 0,
    'Bb': 10,
    'B': 11,
  };

  /// Transporta un acorde completo (incluyendo acordes compuestos con `/`)
  /// la cantidad de [semitones] indicada.
  static String transposeChord(String chord, int semitones) {
    final trimmed = chord.trim();
    if (trimmed.isEmpty || semitones == 0) return trimmed;

    if (trimmed.contains('/')) {
      return trimmed
          .split('/')
          .map((part) => _transposeSingleChord(part.trim(), semitones))
          .join('/');
    }

    return _transposeSingleChord(trimmed, semitones);
  }

  static String _transposeSingleChord(String chord, int semitones) {
    // 1. Intentar coincidencia con notación latina (insensible a mayúsculas/minúsculas al inicio)
    for (final entry in _latinNoteToSemitone.entries) {
      if (chord.toLowerCase().startsWith(entry.key.toLowerCase())) {
        final suffix = chord.substring(entry.key.length);
        final newIndex = ((entry.value + semitones) % 12 + 12) % 12;
        return '${_latinScale[newIndex]}$suffix';
      }
    }

    // 2. Intentar coincidencia con notación americana
    for (final entry in _americanNoteToSemitone.entries) {
      if (chord.startsWith(entry.key)) {
        final suffix = chord.substring(entry.key.length);
        final newIndex = ((entry.value + semitones) % 12 + 12) % 12;
        return '${_americanScale[newIndex]}$suffix';
      }
    }

    // Si no coincide con ninguna nota conocida, devolver el acorde original
    return chord;
  }

  /// Devuelve el texto completo en formato ChordPro con todos sus acordes transportados.
  static String transposeChordProContent(String content, int semitones) {
    if (semitones == 0) return content;
    return content.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (match) {
      final originalChord = match.group(1) ?? '';
      return '[${transposeChord(originalChord, semitones)}]';
    });
  }
}

/// Par interno de (acorde opcional, sílaba/fragmento de letra).
class _ChordLyricPair {
  final String? chord;
  final String lyric;

  const _ChordLyricPair({this.chord, required this.lyric});
}

/// Representa una palabra (o bloque inseparable) compuesta por uno o más pares acorde-sílaba.
class _WordChunk {
  final List<_ChordLyricPair> pairs;

  const _WordChunk(this.pairs);
}

/// Widget que parsea texto en formato ChordPro (`[Acorde]letra`) y dibuja cada acorde
/// exactamente arriba de la sílaba correspondiente sin desacomodarse al cambiar el tamaño de fuente.
class ChordLyricsViewer extends StatelessWidget {
  final String content;
  final int transposeSemitones;
  final double fontSize;
  final Color? chordColor;
  final Color? lyricColor;

  const ChordLyricsViewer({
    super.key,
    required this.content,
    this.transposeSemitones = 0,
    this.fontSize = 18.0,
    this.chordColor,
    this.lyricColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveChordColor = chordColor ?? theme.colorScheme.primary;
    final effectiveLyricColor = lyricColor ?? theme.colorScheme.onSurface;

    final chordTextStyle = TextStyle(
      fontSize: fontSize * 0.88,
      fontWeight: FontWeight.w800,
      color: effectiveChordColor,
      height: 1.15,
    );

    final lyricTextStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: effectiveLyricColor,
      height: 1.25,
    );

    final lines = content.split(RegExp(r'\r?\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          _buildLine(
            line: line,
            chordStyle: chordTextStyle,
            lyricStyle: lyricTextStyle,
          ),
      ],
    );
  }

  Widget _buildLine({
    required String line,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
  }) {
    if (line.trim().isEmpty) {
      return SizedBox(height: fontSize * 0.9);
    }

    final pairs = _parseLineToPairs(line);
    final hasAnyChord = pairs.any((p) => p.chord != null && p.chord!.isNotEmpty);

    // Si la línea no tiene acordes, renderizar texto directo para fluidez óptima
    if (!hasAnyChord) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(line, style: lyricStyle),
      );
    }

    final wordChunks = _groupPairsIntoWordChunks(pairs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        runSpacing: 6.0,
        children: [
          for (final chunk in wordChunks)
            _buildWordChunk(
              chunk: chunk,
              chordStyle: chordStyle,
              lyricStyle: lyricStyle,
            ),
        ],
      ),
    );
  }

  Widget _buildWordChunk({
    required _WordChunk chunk,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < chunk.pairs.length; i++)
          _buildSyllableColumn(
            pair: chunk.pairs[i],
            hasNextInSameWord:
                i + 1 < chunk.pairs.length && chunk.pairs[i + 1].chord != null,
            chordStyle: chordStyle,
            lyricStyle: lyricStyle,
          ),
      ],
    );
  }

  Widget _buildSyllableColumn({
    required _ChordLyricPair pair,
    required bool hasNextInSameWord,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
  }) {
    final transposed = pair.chord != null
        ? ChordTransposer.transposeChord(pair.chord!, transposeSemitones)
        : '';

    // Si hay otro acorde inmediatamente después en la misma palabra, agregamos un pequeño margen
    // al acorde superior para que dos acordes consecutivos nunca se peguen visualmente.
    final chordDisplay = transposed.isNotEmpty
        ? (hasNextInSameWord ? '$transposed ' : transposed)
        : ' ';

    // Si un acorde está solo al final de la línea sin sílaba debajo, damos espacio mínimo
    final lyricDisplay =
        pair.lyric.isEmpty && transposed.isNotEmpty ? '   ' : pair.lyric;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chordDisplay,
          style: chordStyle,
        ),
        Text(
          lyricDisplay,
          style: lyricStyle,
        ),
      ],
    );
  }

  /// Parsea una línea con etiquetas `[Acorde]` en una lista secuencial de pares `(acorde, texto)`.
  List<_ChordLyricPair> _parseLineToPairs(String line) {
    final regex = RegExp(r'\[([^\]]+)\]');
    final matches = regex.allMatches(line).toList();

    if (matches.isEmpty) {
      return [_ChordLyricPair(lyric: line)];
    }

    final result = <_ChordLyricPair>[];

    // Texto previo al primer acorde
    if (matches.first.start > 0) {
      result.add(
        _ChordLyricPair(lyric: line.substring(0, matches.first.start)),
      );
    }

    for (int i = 0; i < matches.length; i++) {
      final currentMatch = matches[i];
      final chord = currentMatch.group(1)?.trim();
      final lyricStart = currentMatch.end;
      final lyricEnd =
          (i + 1 < matches.length) ? matches[i + 1].start : line.length;
      final lyric = line.substring(lyricStart, lyricEnd);

      result.add(_ChordLyricPair(chord: chord, lyric: lyric));
    }

    return result;
  }

  /// Agrupa los pares `(acorde, sílaba)` por palabras completas para que un salto de línea
  /// automático (`Wrap`) nunca parta una palabra a la mitad cuando el usuario agranda la letra.
  List<_WordChunk> _groupPairsIntoWordChunks(List<_ChordLyricPair> pairs) {
    final chunks = <_WordChunk>[];
    var currentWordPairs = <_ChordLyricPair>[];

    for (final pair in pairs) {
      final text = pair.lyric;

      if (text.isEmpty) {
        // Acorde sin texto inmediato (ej. al final de línea o dos acordes seguidos)
        currentWordPairs.add(pair);
        continue;
      }

      // Dividimos el fragmento conservando los espacios al final de cada palabra
      final tokenMatches = RegExp(r'\S+\s*|\s+').allMatches(text).toList();
      for (int i = 0; i < tokenMatches.length; i++) {
        final token = tokenMatches[i].group(0)!;
        final chordForToken = (i == 0) ? pair.chord : null;

        currentWordPairs.add(
          _ChordLyricPair(chord: chordForToken, lyric: token),
        );

        // Si el token termina en espacio, cerramos la palabra actual para permitir wrap limpio
        if (token.endsWith(' ')) {
          chunks.add(_WordChunk(currentWordPairs));
          currentWordPairs = <_ChordLyricPair>[];
        }
      }
    }

    if (currentWordPairs.isNotEmpty) {
      chunks.add(_WordChunk(currentWordPairs));
    }

    return chunks;
  }
}

