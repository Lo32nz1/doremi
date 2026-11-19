/// Modelo de Repertorio (Setlist) para presentaciones en vivo o ensayos.
/// Diseñado como base extensible para el Módulo 2.
class Setlist {
  final String id;
  final String title;
  final String subtitle;
  final List<String> orderedSongs;

  const Setlist({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.orderedSongs,
  });

  /// Datos iniciales de ejemplo para visualizar secuencias ordenadas de canciones.
  static const List<Setlist> sampleSetlists = [
    Setlist(
      id: 'setlist-1',
      title: 'Show Acústico - Viernes',
      subtitle: 'Apertura y bloque clásico (4 canciones)',
      orderedSongs: [
        'De Música Ligera',
        'Flaca',
        'Cielito Lindo',
        'Persiana Americana',
      ],
    ),
    Setlist(
      id: 'setlist-2',
      title: 'Ensayo General Banda',
      subtitle: 'Repertorio de prueba de sonido',
      orderedSongs: [
        'Canción 1',
        'Canción 2',
        'Canción 3',
        'Canción 4',
      ],
    ),
  ];
}

