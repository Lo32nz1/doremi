import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';

class SongCard extends StatelessWidget {
  final SongMetadata song;
  final VoidCallback onTap;

  const SongCard({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar con inicial
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: song.number != null
                        ? Text(
                            '#${song.number}',
                            style: const TextStyle(
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          )
                        : Text(
                            song.displayTitle.isNotEmpty
                                ? song.displayTitle[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Título y artista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.displayTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.displayArtist.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          song.displayArtist,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge de tono
                if (song.key.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      song.key,
                      style: const TextStyle(
                        color: Color(0xFFF5A623),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Eliminar canción'),
                        content: Text('¿Seguro que deseas eliminar "${song.displayTitle}" permanentemente? Este cambio no se puede deshacer.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                            onPressed: () {
                              context.read<LibraryProvider>().deleteSong(song);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
