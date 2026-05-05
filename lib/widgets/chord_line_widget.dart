import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song.dart';

/// Renderiza una línea de la canción.
/// Para líneas con acordes, muestra DOS filas: acordes arriba, letra abajo,
/// alineados usando relleno de espacios (funciona con fuente monoespaciada).
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
      return !showChords ? const SizedBox(height: 6) : const SizedBox(height: 12);
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
        child: Text(
          lyricText,
          style: _lyricStyle(context),
        ),
      );
    } else {
      // Con acordes: Usamos Wrap para que los acordes sigan a su letra al romper línea
      content = Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          alignment: WrapAlignment.start,
          children: line.chunks.map((c) => _buildChunk(context, c)).toList(),
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

  Widget _buildChunk(BuildContext context, SongChunk chunk) {
    final hasChord = chunk.chord != null && chunk.chord!.isNotEmpty;
    
    // Si no hay letra pero hay acorde (ej: intro), añadimos un espacio para que el Wrap 
    // lo trate como un elemento con ancho mínimo.
    final chordText = hasChord ? chunk.chord! : '';
    final lyricsText = chunk.lyrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila de acordes
        Text(
          hasChord ? chordText : ' ', // Espacio para mantener altura de la línea de acordes
          style: _chordStyle(context),
        ),
        // Fila de letras
        Text(
          lyricsText.isNotEmpty ? lyricsText : (hasChord ? ' ' : ''),
          style: _lyricStyle(context),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: fontSize * 0.80,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  TextStyle _chordStyle(BuildContext context) => GoogleFonts.sourceCodePro(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        height: 1.2, // Ajustamos la altura para pegarlos un poquito más
        letterSpacing: 0,
      );

  TextStyle _lyricStyle(BuildContext context) => GoogleFonts.sourceCodePro(
        fontSize: fontSize,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92),
        height: 1.4, // Altura más compacta para que el acorde no quede volando
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );
}
