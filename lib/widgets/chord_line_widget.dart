import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/song.dart';

/// Un fragmento contiguo dentro de una misma palabra (sin espacios),
/// con un acorde opcional alineado al inicio de [text].
class ChordLyricSegment {
  final String? chord;
  final String text;

  const ChordLyricSegment({this.chord, required this.text});
}

/// Unidad atómica de salto de línea: una palabra completa (que puede contener
/// uno o más acordes en el medio) o un acorde suelto, más los espacios
/// posteriores que la separan del siguiente token.
class ChordWordToken {
  final List<ChordLyricSegment> segments;
  final String trailingSpace;

  const ChordWordToken({required this.segments, this.trailingSpace = ''});

  bool get hasChords =>
      segments.any((s) => s.chord != null && s.chord!.isNotEmpty);

  String get lyrics => segments.map((s) => s.text).join();

  bool get hasLyrics => segments.any((s) => s.text.isNotEmpty);
}

/// Agrupa los [SongChunk] de una línea en tokens por palabra completa.
///
/// Así, un acorde en medio de una palabra (ej. `ap[G]pear`, `cora[G]zón`,
/// `[G]Alaba[D]ré`) queda dentro de un único [ChordWordToken] y nunca se corta
/// la palabra al hacer salto de línea.
List<ChordWordToken> tokenizeSongLine(List<SongChunk> chunks) {
  final tokens = <ChordWordToken>[];
  var currentSegments = <ChordLyricSegment>[];

  void flushCurrentWord({String trailingSpace = ''}) {
    if (currentSegments.isNotEmpty) {
      tokens.add(
        ChordWordToken(
          segments: List<ChordLyricSegment>.unmodifiable(currentSegments),
          trailingSpace: trailingSpace,
        ),
      );
      currentSegments = <ChordLyricSegment>[];
    } else if (trailingSpace.isNotEmpty) {
      tokens.add(
        ChordWordToken(segments: const [], trailingSpace: trailingSpace),
      );
    }
  }

  final partPattern = RegExp(r' +|[^ ]+');

  for (final chunk in chunks) {
    String? pendingChord =
        (chunk.chord != null && chunk.chord!.isNotEmpty) ? chunk.chord : null;
    final rawLyrics = chunk.lyrics.replaceAll('\t', '  ');

    if (rawLyrics.isEmpty) {
      if (pendingChord == null) continue;
      if (currentSegments.isNotEmpty) {
        currentSegments.add(ChordLyricSegment(chord: pendingChord, text: ''));
      } else {
        tokens.add(
          ChordWordToken(
            segments: [ChordLyricSegment(chord: pendingChord, text: '')],
          ),
        );
      }
      continue;
    }

    for (final match in partPattern.allMatches(rawLyrics)) {
      final part = match.group(0)!;
      final isSpace = part.startsWith(' ');

      if (isSpace) {
        if (pendingChord != null) {
          if (currentSegments.isNotEmpty) {
            flushCurrentWord();
          }
          tokens.add(
            ChordWordToken(
              segments: [ChordLyricSegment(chord: pendingChord, text: '')],
              trailingSpace: part,
            ),
          );
          pendingChord = null;
        } else {
          flushCurrentWord(trailingSpace: part);
        }
      } else {
        currentSegments.add(ChordLyricSegment(chord: pendingChord, text: part));
        pendingChord = null;
      }
    }
  }

  flushCurrentWord();
  return tokens;
}

/// Acorde ya posicionado dentro de una fila visual.
class PlacedChord {
  final String text;
  final double x;
  final double width;

  const PlacedChord({required this.text, required this.x, required this.width});
}

/// Palabra (o fragmento de palabra muy larga) ya posicionada en una fila visual.
class PlacedLyric {
  final String text;
  final double x;
  final double width;

  const PlacedLyric({required this.text, required this.x, required this.width});
}

/// Fila visual resultante después de aplicar el ajuste de línea por palabras.
class ChordVisualRow {
  final List<PlacedChord> chords;
  final List<PlacedLyric> lyrics;
  final double chordY;
  final double lyricY;
  final double width;
  final double height;

  const ChordVisualRow({
    required this.chords,
    required this.lyrics,
    required this.chordY,
    required this.lyricY,
    required this.width,
    required this.height,
  });

  String get lyricText => lyrics.map((l) => l.text).join(' ');
}

/// Resultado completo del layout de una línea con acordes.
class ChordLineLayoutResult {
  final List<ChordVisualRow> rows;
  final double width;
  final double height;

  const ChordLineLayoutResult({
    required this.rows,
    required this.width,
    required this.height,
  });
}

/// Calcula las filas visuales y coordenadas exactas de acordes y letra
/// respetando palabras completas y evitando superposición o recortes.
ChordLineLayoutResult computeChordLineLayout({
  required List<ChordWordToken> tokens,
  required double maxWidth,
  required TextStyle chordStyle,
  required TextStyle lyricStyle,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required double wrappedRowSpacing,
}) {
  if (tokens.isEmpty) {
    return const ChordLineLayoutResult(rows: [], width: 0, height: 0);
  }

  final chordMetricsCache = <String, Size>{};
  final lyricMetricsCache = <String, Size>{};

  Size measure(String text, TextStyle style, Map<String, Size> cache) {
    final cached = cache[text];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final size = painter.size;
    painter.dispose();
    cache[text] = size;
    return size;
  }

  final spaceSize = measure(' ', lyricStyle, lyricMetricsCache);
  final chordLineHeight = measure('A', chordStyle, chordMetricsCache).height;
  final lyricLineHeight = spaceSize.height;
  final chordGap = math.max(spaceSize.width * 0.75, 4.0);

  _MeasuredToken measureToken(ChordWordToken token) {
    final lyricsBuffer = StringBuffer();
    final chords = <_MeasuredChord>[];
    double? prevChordEnd;

    for (final seg in token.segments) {
      final prefixWidth = lyricsBuffer.isEmpty
          ? 0.0
          : measure(
              lyricsBuffer.toString(),
              lyricStyle,
              lyricMetricsCache,
            ).width;
      if (seg.chord != null && seg.chord!.isNotEmpty) {
        final relX = prevChordEnd == null
            ? prefixWidth
            : math.max(prefixWidth, prevChordEnd + chordGap);
        final chordWidth = measure(
          seg.chord!,
          chordStyle,
          chordMetricsCache,
        ).width;
        chords.add(
          _MeasuredChord(text: seg.chord!, relX: relX, width: chordWidth),
        );
        prevChordEnd = relX + chordWidth;
      }
      lyricsBuffer.write(seg.text);
    }

    final lyrics = lyricsBuffer.toString();
    final lyricWidth = lyrics.isEmpty
        ? 0.0
        : measure(lyrics, lyricStyle, lyricMetricsCache).width;
    final trailingSpaceWidth = token.trailingSpace.isEmpty
        ? 0.0
        : measure(token.trailingSpace, lyricStyle, lyricMetricsCache).width;
    final maxChordEnd = chords.isEmpty
        ? 0.0
        : chords.last.relX + chords.last.width;
    final contentWidth = math.max(lyricWidth, maxChordEnd);

    return _MeasuredToken(
      lyrics: lyrics,
      chords: chords,
      lyricWidth: lyricWidth,
      trailingSpaceWidth: trailingSpaceWidth,
      contentWidth: contentWidth,
    );
  }

  List<ChordWordToken> splitOversizedToken(
    ChordWordToken token,
    double availableWidth,
  ) {
    final chars = <String>[];
    final chordsAt = <int, List<String>>{};

    for (final seg in token.segments) {
      if (seg.chord != null && seg.chord!.isNotEmpty) {
        (chordsAt[chars.length] ??= <String>[]).add(seg.chord!);
      }
      for (final grapheme in seg.text.characters) {
        chars.add(grapheme);
      }
    }

    if (chars.isEmpty) return [token];

    ChordWordToken sliceToken(int start, int end) {
      final segments = <ChordLyricSegment>[];
      final textBuffer = StringBuffer();
      String? activeChord;

      void flushSegment() {
        if (activeChord != null || textBuffer.isNotEmpty) {
          segments.add(
            ChordLyricSegment(chord: activeChord, text: textBuffer.toString()),
          );
          textBuffer.clear();
          activeChord = null;
        }
      }

      for (var i = start; i < end; i++) {
        final chordsHere = chordsAt[i];
        if (chordsHere != null && chordsHere.isNotEmpty) {
          flushSegment();
          for (var c = 0; c < chordsHere.length - 1; c++) {
            segments.add(ChordLyricSegment(chord: chordsHere[c], text: ''));
          }
          activeChord = chordsHere.last;
        }
        textBuffer.write(chars[i]);
      }
      flushSegment();

      if (end == chars.length) {
        final trailingChords = chordsAt[chars.length];
        if (trailingChords != null) {
          for (final chord in trailingChords) {
            segments.add(ChordLyricSegment(chord: chord, text: ''));
          }
        }
      }

      return ChordWordToken(
        segments: segments,
        trailingSpace: end == chars.length ? token.trailingSpace : '',
      );
    }

    final pieces = <ChordWordToken>[];
    var start = 0;
    while (start < chars.length) {
      var low = start + 1;
      var high = chars.length;
      var bestEnd = start + 1;

      while (low <= high) {
        final mid = (low + high) >> 1;
        final candidate = sliceToken(start, mid);
        final measuredCandidate = measureToken(candidate);
        if (measuredCandidate.contentWidth <= availableWidth + 0.01) {
          bestEnd = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      pieces.add(sliceToken(start, bestEnd));
      start = bestEnd;
    }

    return pieces;
  }

  final builtRows = <_VisualRowBuilder>[];
  var currentRow = _VisualRowBuilder();

  void commitCurrentRow() {
    if (currentRow.hasItems) {
      builtRows.add(currentRow);
      currentRow = _VisualRowBuilder();
    }
  }

  void placeToken(_MeasuredToken measured) {
    final tokenX = currentRow.nextTokenX(measured, chordGap);
    if (measured.lyrics.isNotEmpty) {
      currentRow.lyrics.add(
        PlacedLyric(
          text: measured.lyrics,
          x: tokenX,
          width: measured.lyricWidth,
        ),
      );
    }
    for (final chord in measured.chords) {
      final placedX = tokenX + chord.relX;
      currentRow.chords.add(
        PlacedChord(text: chord.text, x: placedX, width: chord.width),
      );
      currentRow.chordEndX = placedX + chord.width;
    }
    currentRow.width = math.max(
      currentRow.width,
      tokenX + measured.contentWidth,
    );
    currentRow.lyricX =
        tokenX + measured.lyricWidth + measured.trailingSpaceWidth;
    currentRow.hasItems = true;
  }

  for (final token in tokens) {
    // Espacios iniciales de sangría al comienzo de la línea
    if (token.segments.isEmpty && token.trailingSpace.isNotEmpty) {
      if (!currentRow.hasItems && builtRows.isEmpty) {
        final indentWidth = measure(
          token.trailingSpace,
          lyricStyle,
          lyricMetricsCache,
        ).width;
        if (!maxWidth.isFinite || indentWidth < maxWidth) {
          currentRow.lyricX = indentWidth;
        }
      }
      continue;
    }

    final measured = measureToken(token);
    final candidateX = currentRow.nextTokenX(measured, chordGap);
    final candidateRight = candidateX + measured.contentWidth;

    if (currentRow.hasItems &&
        maxWidth.isFinite &&
        candidateRight > maxWidth + 0.01) {
      commitCurrentRow();
    }

    // Solo si una palabra individual excede por sí sola el ancho disponible,
    // la dividimos en fragmentos seguros para que nunca se corte fuera de pantalla.
    if (maxWidth.isFinite &&
        measured.contentWidth > maxWidth + 0.01 &&
        token.hasLyrics) {
      if (currentRow.hasItems) {
        commitCurrentRow();
      }
      final pieces = splitOversizedToken(token, maxWidth);
      for (var i = 0; i < pieces.length; i++) {
        if (i > 0) {
          commitCurrentRow();
        }
        placeToken(measureToken(pieces[i]));
      }
      continue;
    }

    placeToken(measured);
  }

  commitCurrentRow();

  final rows = <ChordVisualRow>[];
  var currentY = 0.0;
  var maxRowWidth = 0.0;

  for (var i = 0; i < builtRows.length; i++) {
    final row = builtRows[i];
    final hasChords = row.chords.isNotEmpty;
    final hasLyrics = row.lyrics.isNotEmpty;

    if (i > 0 && hasChords) {
      currentY += wrappedRowSpacing;
    }

    final chordY = currentY;
    final lyricY = hasChords ? currentY + chordLineHeight : currentY;

    var rowHeight = 0.0;
    if (hasChords) rowHeight += chordLineHeight;
    if (hasLyrics) rowHeight += lyricLineHeight;
    if (rowHeight == 0) rowHeight = lyricLineHeight;

    rows.add(
      ChordVisualRow(
        chords: List<PlacedChord>.unmodifiable(row.chords),
        lyrics: List<PlacedLyric>.unmodifiable(row.lyrics),
        chordY: chordY,
        lyricY: lyricY,
        width: row.width,
        height: rowHeight,
      ),
    );

    currentY += rowHeight;
    if (row.width > maxRowWidth) {
      maxRowWidth = row.width;
    }
  }

  return ChordLineLayoutResult(
    rows: rows,
    width: maxRowWidth,
    height: currentY,
  );
}

class _MeasuredChord {
  final String text;
  final double relX;
  final double width;

  const _MeasuredChord({
    required this.text,
    required this.relX,
    required this.width,
  });
}

class _MeasuredToken {
  final String lyrics;
  final List<_MeasuredChord> chords;
  final double lyricWidth;
  final double trailingSpaceWidth;
  final double contentWidth;

  const _MeasuredToken({
    required this.lyrics,
    required this.chords,
    required this.lyricWidth,
    required this.trailingSpaceWidth,
    required this.contentWidth,
  });
}

class _VisualRowBuilder {
  final List<PlacedChord> chords = [];
  final List<PlacedLyric> lyrics = [];
  double lyricX = 0;
  double? chordEndX;
  double width = 0;
  bool hasItems = false;

  double nextTokenX(_MeasuredToken token, double chordGap) {
    if (!hasItems || token.chords.isEmpty || chordEndX == null) {
      return lyricX;
    }
    final minXForChord = chordEndX! + chordGap - token.chords.first.relX;
    return math.max(lyricX, minXForChord);
  }
}

/// Renderiza una línea de la canción.
/// Para líneas con acordes, agrupa por palabras completas para que los acordes
/// sigan con precisión a su sílaba y las palabras nunca se corten al agrandar
/// la letra.
class ChordLineWidget extends StatelessWidget {
  final SongLine line;
  final double fontSize;
  final bool showChords;

  const ChordLineWidget({
    super.key,
    required this.line,
    this.fontSize = 16,
    this.showChords = true,
  });

  @override
  Widget build(BuildContext context) {
    // ── Línea de anotación / comentario ──────────────────────────────────────
    if (line.isComment) {
      if (!showChords) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
          child: _buildBadge(context, line.comment!),
        ),
      );
    }

    // ── Línea vacía → espacio vertical ───────────────────────────────────────
    if (line.isEmpty) {
      return !showChords
          ? const SizedBox(height: 6)
          : const SizedBox(height: 12);
    }

    final lyricText = line.chunks.map((c) => c.lyrics).join();
    if (!showChords && lyricText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Sin acordes, o acordes ocultos → solo texto de letra
    Widget content;
    if (!line.hasChords || !showChords) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(lyricText, style: _lyricStyle(context)),
      );
    } else {
      final tokens = tokenizeSongLine(line.chunks);
      final topPadding = (fontSize * 0.55).clamp(8.0, 18.0);
      final wrappedRowSpacing = (fontSize * 0.30).clamp(5.0, 12.0);
      content = Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: 2),
        child: _ChordLineCanvas(
          tokens: tokens,
          chordStyle: _chordStyle(context),
          lyricStyle: _lyricStyle(context),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          wrappedRowSpacing: wrappedRowSpacing,
          semanticsLabel: lyricText.trim().isNotEmpty
              ? lyricText
              : line.chunks
                    .map((c) => c.chord ?? '')
                    .where((c) => c.isNotEmpty)
                    .join(' '),
        ),
      );
    }

    if (line.inlineRightComment != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 14,
        runSpacing: 8,
        children: [
          content,
          if (showChords)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _buildBadge(context, line.inlineRightComment!),
            ),
        ],
      );
    }

    return content;
  }

  Widget _buildBadge(BuildContext context, String text) {
    final badgeFontSize = (fontSize * 0.72).clamp(11.0, 20.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: badgeFontSize,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.70),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  TextStyle _chordStyle(BuildContext context) => GoogleFonts.sourceCodePro(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.primary,
    height: 1.2,
    letterSpacing: 0,
  );

  TextStyle _lyricStyle(BuildContext context) => GoogleFonts.sourceCodePro(
    fontSize: fontSize,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92),
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
}

class _ChordLineCanvas extends LeafRenderObjectWidget {
  final List<ChordWordToken> tokens;
  final TextStyle chordStyle;
  final TextStyle lyricStyle;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final double wrappedRowSpacing;
  final String semanticsLabel;

  const _ChordLineCanvas({
    required this.tokens,
    required this.chordStyle,
    required this.lyricStyle,
    required this.textDirection,
    required this.textScaler,
    required this.wrappedRowSpacing,
    required this.semanticsLabel,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderChordLine(
      tokens: tokens,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      wrappedRowSpacing: wrappedRowSpacing,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderChordLine renderObject,
  ) {
    renderObject
      ..tokens = tokens
      ..chordStyle = chordStyle
      ..lyricStyle = lyricStyle
      ..textDirection = textDirection
      ..textScaler = textScaler
      ..wrappedRowSpacing = wrappedRowSpacing
      ..semanticsLabel = semanticsLabel;
  }
}

class _PaintedSpan {
  final TextPainter painter;
  final Offset offset;

  const _PaintedSpan(this.painter, this.offset);
}

class _RenderChordLine extends RenderBox {
  List<ChordWordToken> _tokens;
  TextStyle _chordStyle;
  TextStyle _lyricStyle;
  TextDirection _textDirection;
  TextScaler _textScaler;
  double _wrappedRowSpacing;
  String _semanticsLabel;

  ChordLineLayoutResult? _layout;
  final List<_PaintedSpan> _paintedSpans = [];

  _RenderChordLine({
    required List<ChordWordToken> tokens,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required double wrappedRowSpacing,
    required String semanticsLabel,
  }) : _tokens = tokens,
       _chordStyle = chordStyle,
       _lyricStyle = lyricStyle,
       _textDirection = textDirection,
       _textScaler = textScaler,
       _wrappedRowSpacing = wrappedRowSpacing,
       _semanticsLabel = semanticsLabel;

  set tokens(List<ChordWordToken> value) {
    if (identical(_tokens, value)) return;
    _tokens = value;
    _clearCache();
    markNeedsLayout();
  }

  set chordStyle(TextStyle value) {
    if (_chordStyle == value) return;
    _chordStyle = value;
    _clearCache();
    markNeedsLayout();
  }

  set lyricStyle(TextStyle value) {
    if (_lyricStyle == value) return;
    _lyricStyle = value;
    _clearCache();
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _clearCache();
    markNeedsLayout();
  }

  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    _clearCache();
    markNeedsLayout();
  }

  set wrappedRowSpacing(double value) {
    if (_wrappedRowSpacing == value) return;
    _wrappedRowSpacing = value;
    _clearCache();
    markNeedsLayout();
  }

  set semanticsLabel(String value) {
    if (_semanticsLabel == value) return;
    _semanticsLabel = value;
    markNeedsSemanticsUpdate();
  }

  void _clearCache() {
    for (final span in _paintedSpans) {
      span.painter.dispose();
    }
    _paintedSpans.clear();
    _layout = null;
  }

  @override
  void dispose() {
    _clearCache();
    super.dispose();
  }

  ChordLineLayoutResult _computeLayout(double maxWidth) {
    return computeChordLineLayout(
      tokens: _tokens,
      maxWidth: maxWidth,
      chordStyle: _chordStyle,
      lyricStyle: _lyricStyle,
      textDirection: _textDirection,
      textScaler: _textScaler,
      wrappedRowSpacing: _wrappedRowSpacing,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var maxTokenWidth = 0.0;
    for (final token in _tokens) {
      if (token.segments.isEmpty) continue;
      final single = computeChordLineLayout(
        tokens: [token],
        maxWidth: double.infinity,
        chordStyle: _chordStyle,
        lyricStyle: _lyricStyle,
        textDirection: _textDirection,
        textScaler: _textScaler,
        wrappedRowSpacing: _wrappedRowSpacing,
      );
      if (single.width > maxTokenWidth) {
        maxTokenWidth = single.width;
      }
    }
    return maxTokenWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeLayout(double.infinity).width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeLayout(width).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeLayout(width).height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final result = _computeLayout(constraints.maxWidth);
    return constraints.constrain(Size(result.width, result.height));
  }

  @override
  void performLayout() {
    _clearCache();
    final result = _computeLayout(constraints.maxWidth);
    _layout = result;

    for (final row in result.rows) {
      for (final chord in row.chords) {
        final painter = TextPainter(
          text: TextSpan(text: chord.text, style: _chordStyle),
          textDirection: _textDirection,
          textScaler: _textScaler,
          maxLines: 1,
        )..layout();
        _paintedSpans.add(_PaintedSpan(painter, Offset(chord.x, row.chordY)));
      }
      for (final lyric in row.lyrics) {
        final painter = TextPainter(
          text: TextSpan(text: lyric.text, style: _lyricStyle),
          textDirection: _textDirection,
          textScaler: _textScaler,
          maxLines: 1,
        )..layout();
        _paintedSpans.add(_PaintedSpan(painter, Offset(lyric.x, row.lyricY)));
      }
    }

    size = constraints.constrain(Size(result.width, result.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_layout == null) return;
    for (final span in _paintedSpans) {
      span.painter.paint(context.canvas, offset + span.offset);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isReadOnly = true
      ..label = _semanticsLabel
      ..textDirection = _textDirection;
  }
}
