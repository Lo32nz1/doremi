import 'dart:convert';

/// Modelo de datos para una lista de reproducción (Setlist).
class Setlist {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> songPaths;

  Setlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.songPaths,
  });

  /// Crea un Setlist a partir de un JSON (Map).
  factory Setlist.fromJson(Map<String, dynamic> json) {
    return Setlist(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      songPaths: List<String>.from(json['songPaths'] ?? []),
    );
  }

  /// Convierte este Setlist en un JSON (Map).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'songPaths': songPaths,
    };
  }
}
