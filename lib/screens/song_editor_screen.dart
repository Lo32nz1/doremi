import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/chord_lyrics_viewer.dart';

/// Pantalla para crear o editar una canción con barra de acordes rápidos sobre el teclado.
class SongEditorScreen extends StatefulWidget {
  final Song? initialSong;

  const SongEditorScreen({super.key, this.initialSong});

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _baseKeyController;
  late final TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();

  bool _showPreview = false;

  static const List<String> _quickChords = [
    'Do',
    'Re',
    'Mi',
    'Fa',
    'Sol',
    'La',
    'Si',
    'La m',
    'Mi m',
    'Re m',
    'Si m',
    'Fa# m',
    'Do# m',
    'Sol7',
  ];

  @override
  void initState() {
    super.initState();
    final song = widget.initialSong;
    _titleController = TextEditingController(text: song?.title ?? '');
    _artistController = TextEditingController(text: song?.artist ?? '');
    _baseKeyController = TextEditingController(text: song?.baseKey ?? 'Do');
    _contentController = TextEditingController(text: song?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _baseKeyController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  /// Inserta el acorde entre corchetes `[Acorde]` en la posición actual del cursor.
  void _insertChordAtCursor(String chord) {
    final tag = '[$chord]';
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!_contentFocusNode.hasFocus) {
      _contentFocusNode.requestFocus();
    }

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, tag);
    final newCursorPosition = start + tag.length;

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
    setState(() {});
  }

  void _saveSong() {
    if (!_formKey.currentState!.validate()) return;

    final repository = SongRepository.instance;
    final isEditing = widget.initialSong != null;

    final song = Song(
      id: widget.initialSong?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      baseKey: _baseKeyController.text.trim().isEmpty
          ? 'Do'
          : _baseKeyController.text.trim(),
      content: _contentController.text.trimRight(),
    );

    if (isEditing) {
      repository.updateSong(song);
    } else {
      repository.addSong(song);
    }

    Navigator.of(context).pop(song);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSong != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar canción' : 'Nueva canción'),
        actions: [
          IconButton(
            tooltip: _showPreview ? 'Volver al editor' : 'Vista previa',
            icon: Icon(_showPreview ? Icons.edit_note : Icons.visibility),
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              onPressed: _saveSong,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Título de la canción',
                            prefixIcon: Icon(Icons.music_note),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Ingresa un título'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _baseKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Tonalidad',
                            hintText: 'Ej: Do, La m',
                            prefixIcon: Icon(Icons.tune),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      labelText: 'Artista / Banda',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Ingresa el artista'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  if (_showPreview)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vista previa en vivo',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 20),
                          ChordLyricsViewer(
                            content: _contentController.text.isEmpty
                                ? '[Do]Escribe la [La m]letra con [Fa]acordes [Sol]aquí...'
                                : _contentController.text,
                            fontSize: 18,
                          ),
                        ],
                      ),
                    )
                  else
                    TextFormField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: 14,
                      minLines: 10,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Letra y acordes (Formato ChordPro)',
                        hintText:
                            'Ejemplo:\n[Do]De la Sierra Mo[La m]rena,\ncielito [Re m]lindo, vienen ba[Sol]jando...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Escribe la letra de la canción'
                              : null,
                    ),
                ],
              ),
            ),
          ),
          // Barra de acordes rápidos pegada sobre el teclado
          if (!_showPreview)
            Material(
              elevation: 8,
              color: theme.colorScheme.surfaceContainerHigh,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Insertar acorde en el cursor:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        itemCount: _quickChords.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final chord = _quickChords[index];
                          return ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '[$chord]',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            onPressed: () => _insertChordAtCursor(chord),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

