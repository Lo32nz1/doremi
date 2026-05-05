import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../models/song.dart';

class ChordProParser {
  /// Parsea un archivo completo y devuelve un Song
  static Future<Song> parseFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    return _parseContent(content, filePath);
  }

  /// Parsea solo los primeros renglones para obtener metadata (más rápido para listar)
  static Future<SongMetadata> quickParseMetadata(String filePath, {String? libraryPath}) async {
    String title = p.basenameWithoutExtension(filePath);
    String artist = '';
    String key = '';
    String? number;
    String? category;

    if (libraryPath != null) {
      final relative = p.relative(filePath, from: libraryPath);
      final parts = p.split(relative);
      if (parts.length > 1) category = parts[0];
    }

    try {
      final file = File(filePath);
      
      // Safety check: if file is larger than 2MB, don't parse content to avoid memory issues
      final size = await file.length();
      if (size < 2 * 1024 * 1024) {
        final lines = <String>[];
        final stream = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
        
        await for (final line in stream) {
          lines.add(line);
          if (lines.length >= 30) break;
        }

        for (final line in lines) {
          final d = _parseDirective(line);
          if (d == null) continue;
          switch (d.key.toLowerCase()) {
            case 'title':
            case 't':
              title = d.value;
            case 'artist':
            case 'a':
            case 'subtitle':
              artist = d.value;
            case 'key':
              key = d.value;
            case 'number':
            case 'num':
            case 'book':
              number = d.value;
          }
        }
      }
    } catch (_) {}
    return SongMetadata(title: title, artist: artist, key: key, number: number, filePath: filePath, category: category);
  }

  /// Método sincrónico usado dentro del Isolate para evitar paralizar la UI
  static List<SongMetadata> parseBatchMetadata(Map<String, dynamic> args) {
    final List<String> paths = args['paths'];
    final String libraryPath = args['libraryPath'];
    
    final results = <SongMetadata>[];
    for (final path in paths) {
      results.add(_quickParseMetadataSync(path, libraryPath));
    }
    return results;
  }

  static SongMetadata _quickParseMetadataSync(String filePath, String libraryPath) {
    String title = p.basenameWithoutExtension(filePath);
    String artist = '';
    String key = '';
    String? number;
    String? category;

    final relative = p.relative(filePath, from: libraryPath);
    final parts = p.split(relative);
    if (parts.length > 1) category = parts[0];

    try {
      final file = File(filePath);
      if (file.lengthSync() < 2 * 1024 * 1024) {
        final content = file.readAsStringSync();
        final lines = content.split('\n').take(30);
        for (final line in lines) {
          final d = _parseDirective(line);
          if (d == null) continue;
          switch (d.key.toLowerCase()) {
            case 'title':
            case 't':
              title = d.value;
            case 'artist':
            case 'a':
            case 'subtitle':
              artist = d.value;
            case 'key':
              key = d.value;
            case 'number':
            case 'num':
            case 'book':
              number = d.value;
          }
        }
      }
    } catch (_) {}
    return SongMetadata(title: title, artist: artist, key: key, number: number, filePath: filePath, category: category);
  }

  // ─── Parseo interno ────────────────────────────────────────────────────────

  static Song _parseContent(String content, String filePath) {
    String title = p.basenameWithoutExtension(filePath);
    String artist = '';
    String key = '';
    String? tempo;
    String? number;

    final sections = <SongSection>[];
    List<SongLine>? currentLines;
    String currentName = '';
    SectionType currentType = SectionType.other;

    void saveSection() {
      if (currentLines == null) return;
      // Quitar líneas vacías del final
      while (currentLines!.isNotEmpty && currentLines!.last.isEmpty) {
        currentLines!.removeLast();
      }
      if (currentLines!.isNotEmpty) {
        sections.add(SongSection(name: currentName, type: currentType, lines: currentLines!));
      }
      currentLines = null;
    }

    void startSection(String name, SectionType type) {
      saveSection();
      // Auto-detectar intro/outro por nombre aunque vengan como verse
      final nameLower = name.toLowerCase().trim();
      SectionType resolvedType = type;
      if (nameLower == 'intro' || nameLower.startsWith('introduc')) {
        resolvedType = SectionType.intro;
      } else if (nameLower == 'outro' || nameLower == 'final' || nameLower == 'coda') {
        resolvedType = SectionType.outro;
      }
      currentLines = [];
      currentName = name;
      currentType = resolvedType;
    }

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight();

      // ── Líneas tipo "# Intro" (comentario estilo markdown/ChordPro) ──────────
      if (line.trimLeft().startsWith('#')) {
        final commentText = line.trimLeft().substring(1).trim();
        if (commentText.isNotEmpty) {
          currentLines ??= [];
          currentLines!.add(SongLine(comment: commentText));
        }
        continue;
      }

      final d = _parseDirective(line);

      if (d != null) {
        switch (d.key.toLowerCase()) {
          case 'title':
          case 't':
            title = d.value;
          case 'artist':
          case 'a':
          case 'subtitle':
            artist = d.value;
          case 'key':
            key = d.value;
          case 'tempo':
            tempo = d.value;
          case 'number':
          case 'num':
          case 'book':
            number = d.value;
          // ── Secciones estándar ────────────────────────────────────────────
          case 'start_of_verse':
          case 'sov':
            startSection(d.value.isNotEmpty ? d.value : 'Verso', SectionType.verse);
          case 'end_of_verse':
          case 'eov':
            saveSection();
          case 'start_of_chorus':
          case 'soc':
            startSection(d.value.isNotEmpty ? d.value : 'Coro', SectionType.chorus);
          case 'end_of_chorus':
          case 'eoc':
            saveSection();
          case 'start_of_bridge':
          case 'sob':
            startSection(d.value.isNotEmpty ? d.value : 'Puente', SectionType.bridge);
          case 'end_of_bridge':
          case 'eob':
            saveSection();
          case 'start_of_intro':
          case 'soi':
            startSection(d.value.isNotEmpty ? d.value : 'Intro', SectionType.intro);
          case 'end_of_intro':
          case 'eoi':
            saveSection();
          case 'start_of_outro':
          case 'soo':
            startSection(d.value.isNotEmpty ? d.value : 'Outro', SectionType.outro);
          case 'end_of_outro':
            saveSection();
          // ── Comentarios / anotaciones ──────────────────────────────────────
          // {comment: Intro} {c: x2} {comment_italic: ...} {comment_box: ...}
          case 'comment':
          case 'c':
          case 'comment_italic':
          case 'ci':
          case 'comment_box':
          case 'cb':
            if (d.value.isNotEmpty) {
              currentLines ??= [];
              currentLines!.add(SongLine(comment: d.value));
            }
        }
        continue;
      }

      // Línea normal: extraer {c: } inline antes de parsear como letra
      final inlineComments = RegExp(
        r'\{c(?:omment)?(?:_italic|_box)?:\s*([^}]+)\}',
        caseSensitive: false,
      ).allMatches(line);

      if (inlineComments.isNotEmpty) {
        // Eliminar los {c: ...} del texto y parsear lo que queda como letra
        final cleanLine = line
            .replaceAll(RegExp(r'\{c(?:omment)?(?:_italic|_box)?:[^}]+\}', caseSensitive: false), '')
            .trim();
            
        final mergedComments = inlineComments.map((m) => m.group(1)!.trim()).join('  ');

        if (cleanLine.isNotEmpty) {
          final parsedLine = _parseLine(cleanLine);
          currentLines ??= [];
          currentLines!.add(SongLine(chunks: parsedLine.chunks, inlineRightComment: mergedComments));
        } else {
          currentLines ??= [];
          currentLines!.add(SongLine(comment: mergedComments));
        }
        continue;
      }

      // Línea normal (letra + acordes)
      final songLine = _parseLine(line);
      currentLines ??= [];
      currentLines!.add(songLine);
    }

    saveSection();

    return Song(
      metadata: SongMetadata(
        title: title,
        artist: artist,
        key: key,
        tempo: tempo,
        number: number,
        filePath: filePath,
      ),
      sections: sections,
    );
  }

  /// Detecta directivas como {title: Amazing Grace} o {soc}
  static MapEntry<String, String>? _parseDirective(String line) {
    final t = line.trim();
    if (!t.startsWith('{')) return null;
    final match = RegExp(r'^\{([^:}]+)(?::([^}]*))?\}').firstMatch(t);
    if (match == null) return null;
    return MapEntry(match.group(1)!.trim(), match.group(2)?.trim() ?? '');
  }

  /// Parsea una línea con acordes entre corchetes: [G]Amazing [D]grace
  static SongLine _parseLine(String line) {
    if (!line.contains('[')) {
      return SongLine(chunks: [SongChunk(lyrics: line)]);
    }

    final chunks = <SongChunk>[];
    int pos = 0;

    // Texto antes del primer acorde
    final first = line.indexOf('[');
    if (first > 0) {
      chunks.add(SongChunk(lyrics: line.substring(0, first)));
      pos = first;
    }

    while (pos < line.length) {
      if (line[pos] != '[') break;
      final close = line.indexOf(']', pos);
      if (close == -1) {
        chunks.add(SongChunk(lyrics: line.substring(pos)));
        break;
      }
      final chord = line.substring(pos + 1, close);
      pos = close + 1;
      final next = line.indexOf('[', pos);
      final lyrics = next == -1 ? line.substring(pos) : line.substring(pos, next);
      chunks.add(SongChunk(chord: chord, lyrics: lyrics));
      if (next == -1) break;
      pos = next;
    }

    return SongLine(chunks: chunks.isEmpty ? [SongChunk(lyrics: line)] : chunks);
  }
}
