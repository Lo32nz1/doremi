import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../widgets/chord_lyrics_viewer.dart';
import 'song_editor_screen.dart';

/// Vista de lectura de una canción con controles de transporte (-/+),
/// ajuste de tamaño de fuente, exportación .cho y acceso al editor.
class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Song _currentSong;
  int _transposeSemitones = 0;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
  }

  String get _effectiveKey =>
      ChordTransposer.transposeChord(_currentSong.baseKey, _transposeSemitones);

  Future<void> _openEditor() async {
    final updated = await Navigator.of(context).push<Song>(
      MaterialPageRoute(
        builder: (_) => SongEditorScreen(initialSong: _currentSong),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _currentSong = updated;
      });
    }
  }

  Future<void> _exportChoDialog() async {
    final exportedSong = _transposeSemitones == 0
        ? _currentSong
        : _currentSong.copyWith(
            baseKey: _effectiveKey,
            content: ChordTransposer.transposeChordProContent(
              _currentSong.content,
              _transposeSemitones,
            ),
          );

    final choContent = exportedSong.toChordPro();
    String? savedFilePath;
    try {
      savedFilePath =
          await SongRepository.instance.exportSongToFile(exportedSong);
    } catch (_) {
      savedFilePath = null;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exportar ${exportedSong.suggestedFileName}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (savedFilePath != null) ...[
                Text(
                  'Archivo .cho guardado en:',
                  style: Theme.of(ctx).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  savedFilePath,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  choContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await Clipboard.setData(ClipboardData(text: choContent));
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Contenido .cho de "${exportedSong.title}" copiado al portapapeles',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar .cho'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semitoneLabel = _transposeSemitones > 0
        ? '+$_transposeSemitones'
        : '$_transposeSemitones';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSong.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _currentSong.artist,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar archivo .cho (ChordPro)',
            icon: const Icon(Icons.ios_share),
            onPressed: _exportChoDialog,
          ),
          IconButton(
            tooltip: 'Editar canción',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEditor,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra superior de controles de escenario: Transporte (-/+) y Tamaño de fuente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                // Controles de Transporte de Tonalidad (- / +)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tono: $_effectiveKey ($semitoneLabel)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Bajar 1 semitono (-1)',
                      onPressed: () =>
                          setState(() => _transposeSemitones -= 1),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Subir 1 semitono (+1)',
                      onPressed: () =>
                          setState(() => _transposeSemitones += 1),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                    if (_transposeSemitones != 0)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Restablecer tono original',
                        onPressed: () =>
                            setState(() => _transposeSemitones = 0),
                        icon: const Icon(Icons.refresh, size: 18),
                      ),
                  ],
                ),

                // Control de Tamaño de Fuente (A- / A+)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_size,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Reducir letra',
                      onPressed: _fontSize > 12
                          ? () => setState(() => _fontSize -= 2)
                          : null,
                      icon: const Text(
                        'A-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Agrandar letra',
                      onPressed: _fontSize < 34
                          ? () => setState(() => _fontSize += 2)
                          : null,
                      icon: const Text(
                        'A+',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Visor principal de letra y acordes
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              child: SizedBox(
                width: double.infinity,
                child: ChordLyricsViewer(
                  content: _currentSong.content,
                  transposeSemitones: _transposeSemitones,
                  fontSize: _fontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
