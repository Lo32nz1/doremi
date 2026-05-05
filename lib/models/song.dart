/// Metadata rápida de una canción (para listarla sin parsear todo el archivo)
class SongMetadata {
  final String title;
  final String artist;
  final String key;
  final String? tempo;
  final String? number; // Número en el cancionero de la iglesia
  final String filePath;
  final String? category;

  const SongMetadata({
    required this.title,
    required this.artist,
    required this.key,
    this.tempo,
    this.number,
    required this.filePath,
    this.category,
  });

  String get displayTitle => title.isNotEmpty ? title : filePath.split('/').last;
  String get displayArtist => artist.isNotEmpty ? artist : '';
  String get extension => filePath.split('.').last.toLowerCase();
  /// Texto para buscar: incluye título, artista Y número de cancionero
  String get searchText => '$displayTitle $displayArtist ${number ?? ''}'.toLowerCase();
}

/// Canción completamente parseada
class Song {
  final SongMetadata metadata;
  final List<SongSection> sections;

  const Song({required this.metadata, required this.sections});
}

/// Sección de la canción (verso, coro, puente, etc.)
class SongSection {
  final String name;
  final SectionType type;
  final List<SongLine> lines;

  const SongSection({
    required this.name,
    required this.type,
    required this.lines,
  });

  bool get isChorus => type == SectionType.chorus;
  bool get hasContent =>
      lines.any((l) => l.isComment || l.chunks.any((c) => c.lyrics.trim().isNotEmpty || c.chord != null));
}

enum SectionType { verse, chorus, bridge, intro, outro, other }

/// Una línea de la canción (puede tener acordes o ser una anotación)
class SongLine {
  final List<SongChunk> chunks;
  final String? comment; // Anotación única en la línea (tipo "Intro", "x2")
  final String? inlineRightComment; // Anotación al lado de los acordes o letra

  const SongLine({this.chunks = const [], this.comment, this.inlineRightComment});

  bool get isComment => comment != null;
  bool get hasChords => chunks.any((c) => c.chord != null && c.chord!.isNotEmpty);
  bool get isEmpty =>
      !isComment && chunks.every((c) => c.lyrics.trim().isEmpty && c.chord == null) && inlineRightComment == null;
}

/// Un fragmento de texto con un acorde opcional encima
class SongChunk {
  final String? chord;
  final String lyrics;

  const SongChunk({this.chord, required this.lyrics});
}
