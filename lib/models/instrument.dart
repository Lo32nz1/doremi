import 'package:flutter/material.dart';

/// Una cuerda/nota objetivo de un instrumento.
class InstrumentString {
  final String name; // Ej: "E2", "A2", "D3"
  final double frequency; // Frecuencia de referencia en Hz

  const InstrumentString({required this.name, required this.frequency});
}

/// Definición completa de un instrumento con su afinación estándar.
class Instrument {
  final String id;
  final String displayName;
  final IconData icon;
  final List<InstrumentString> strings;

  const Instrument({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.strings,
  });
}

/// Catálogo de instrumentos disponibles en el afinador.
class InstrumentCatalog {
  static const List<Instrument> all = [
    _chromatic,
    _guitarStandard,
    _bass,
    _ukulele,
    _violin,
  ];

  /// Modo cromático: detecta cualquier nota sin importar el instrumento.
  static const Instrument _chromatic = Instrument(
    id: 'chromatic',
    displayName: 'Cromático',
    icon: Icons.graphic_eq,
    strings: [], // Sin cuerdas fijas; el afinador muestra la nota más cercana
  );

  /// Guitarra en afinación estándar, de la sexta cuerda a la primera.
  static const Instrument _guitarStandard = Instrument(
    id: 'guitar_standard',
    displayName: 'Guitarra',
    icon: Icons.music_note,
    strings: [
      InstrumentString(name: 'E2', frequency: 82.41),
      InstrumentString(name: 'A2', frequency: 110.00),
      InstrumentString(name: 'D3', frequency: 146.83),
      InstrumentString(name: 'G3', frequency: 196.00),
      InstrumentString(name: 'B3', frequency: 246.94),
      InstrumentString(name: 'E4', frequency: 329.63),
    ],
  );

  /// Bajo eléctrico estándar, de la cuarta cuerda a la primera.
  static const Instrument _bass = Instrument(
    id: 'bass',
    displayName: 'Bajo',
    icon: Icons.queue_music,
    strings: [
      InstrumentString(name: 'E1', frequency: 41.20),
      InstrumentString(name: 'A1', frequency: 55.00),
      InstrumentString(name: 'D2', frequency: 73.42),
      InstrumentString(name: 'G2', frequency: 98.00),
    ],
  );

  /// Ukelele con afinación reentrante G C E A.
  static const Instrument _ukulele = Instrument(
    id: 'ukulele',
    displayName: 'Ukulele',
    icon: Icons.music_note,
    strings: [
      InstrumentString(name: 'G4', frequency: 392.00),
      InstrumentString(name: 'C4', frequency: 261.63),
      InstrumentString(name: 'E4', frequency: 329.63),
      InstrumentString(name: 'A4', frequency: 440.00),
    ],
  );

  /// Violín estándar, de la cuarta cuerda a la primera.
  static const Instrument _violin = Instrument(
    id: 'violin',
    displayName: 'Violín',
    icon: Icons.music_note,
    strings: [
      InstrumentString(name: 'G3', frequency: 196.00),
      InstrumentString(name: 'D4', frequency: 293.66),
      InstrumentString(name: 'A4', frequency: 440.00),
      InstrumentString(name: 'E5', frequency: 659.26),
    ],
  );
}
