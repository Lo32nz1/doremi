import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../parsers/chordpro_parser.dart';
import '../providers/library_provider.dart';
import '../providers/setlist_provider.dart';
import '../utils/chord_transposer.dart';
import '../utils/song_dialogs.dart';
import '../widgets/chord_line_widget.dart';

enum _ViewMode { normal, lyrics, edit }

class SongViewScreen extends StatefulWidget {
  final SongMetadata? metadata;
  final bool showBackButton;

  const SongViewScreen({super.key, this.metadata, this.showBackButton = true});

  @override
  State<SongViewScreen> createState() => _SongViewScreenState();
}

class _SongViewScreenState extends State<SongViewScreen> {
  SongMetadata? _currentMetadata;
  Song? _song;
  bool _isLoading = true;
  String? _error;
  double _fontSize = 16;
  _ViewMode _viewMode = _ViewMode.normal;
  bool _hasUnsavedChanges = false;
  int _transposeSteps = 0;
  bool _useFlats = false;
  
  Song? get _displaySong {
    if (_song == null) return null;
    if (_transposeSteps == 0 && !_useFlats && !_song!.metadata.key.contains('b')) return _song;
    return ChordTransposer.transposeSong(_song!, _transposeSteps, useFlats: _useFlats);
  }
  late TextEditingController _editController;
  double _initialFontSize = 16;

  static const double _maxContentWidth = 780;
  static const double _panelBreakpoint = 900;
  static const double _minPanelWidth = 160;
  static const double _maxPanelWidth = 420;
  double _panelWidth = 235;

  @override
  void initState() {
    super.initState();
    _currentMetadata = widget.metadata;
    _editController = TextEditingController();
    if (_currentMetadata != null) {
      _loadSong();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  // ─── Carga de canción ─────────────────────────────────────────────────────

  Future<void> _loadSong() async {
    if (_currentMetadata == null) return;
    try {
      final file = File(_currentMetadata!.filePath);
      final content = await file.readAsString();
      final song = await ChordProParser.parseFile(_currentMetadata!.filePath);
      _editController.text = content;
      setState(() {
        _song = song;
        _isLoading = false;
        _hasUnsavedChanges = false;
        _transposeSteps = 0;
        _useFlats = song.metadata.key.contains('b');
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _switchSong(SongMetadata song) {
    if (_currentMetadata?.filePath == song.filePath) return;
    setState(() {
      _currentMetadata = song;
      _song = null;
      _isLoading = true;
      _error = null;
    });
    _loadSong();
  }

  Future<void> _saveFile() async {
    if (_currentMetadata == null) return;
    try {
      await File(_currentMetadata!.filePath).writeAsString(_editController.text);
      final song = await ChordProParser.parseFile(_currentMetadata!.filePath);
      setState(() {
        _song = song;
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
               '✓ Archivo guardado',
               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF323232),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             content: Text('Error al guardar: $e', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             backgroundColor: Colors.redAccent,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _panelBreakpoint;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Guardar (solo en edición)
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (_viewMode == _ViewMode.edit && _hasUnsavedChanges) _saveFile();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          if (_viewMode == _ViewMode.edit && _hasUnsavedChanges) _saveFile();
        },
        // Zoom In (Ctrl + / Ctrl =)
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
            setState(() => _fontSize = (_fontSize + 1).clamp(10, 40)),
        const SingleActivator(LogicalKeyboardKey.add, control: true): () =>
            setState(() => _fontSize = (_fontSize + 1).clamp(10, 40)),
        const SingleActivator(LogicalKeyboardKey.equal, meta: true): () =>
            setState(() => _fontSize = (_fontSize + 1).clamp(10, 40)),
        // Zoom Out (Ctrl -)
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
            setState(() => _fontSize = (_fontSize - 1).clamp(10, 40)),
        const SingleActivator(LogicalKeyboardKey.minus, meta: true): () =>
            setState(() => _fontSize = (_fontSize - 1).clamp(10, 40)),
        // Reset Zoom (Ctrl 0)
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
            setState(() => _fontSize = 16),
        const SingleActivator(LogicalKeyboardKey.digit0, meta: true): () =>
            setState(() => _fontSize = 16),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            _SongListPanel(
                              width: _panelWidth,
                              currentFilePath: _currentMetadata?.filePath ?? '',
                              onSongSelected: _switchSong,
                            ),
                            _ResizableHandle(
                              onDrag: (delta) => setState(() {
                                _panelWidth = (_panelWidth + delta)
                                    .clamp(_minPanelWidth, _maxPanelWidth);
                              }),
                            ),
                            Expanded(child: _buildBody()),
                          ],
                        )
                      : _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Barra superior ───────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 850;
    
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Text(
              _currentMetadata?.displayTitle ?? '',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.circle, color: Theme.of(context).colorScheme.primary, size: 8),
            ),
          if (_currentMetadata != null) ...[
            if (!isCompact) _buildModeSelector(),
            if (!isCompact && _viewMode == _ViewMode.edit) _buildDeleteBtn(),
            if (!isCompact && _viewMode != _ViewMode.edit) _buildTransposeControls(),
            if (!isCompact && _viewMode != _ViewMode.edit)
              IconButton(
                icon: Icon(Icons.playlist_add, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 22),
                tooltip: 'Añadir a Setlist',
                onPressed: () => _showAddToSetlistModal(),
              ),
          ],
          if (!isCompact && _viewMode != _ViewMode.edit)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFF5A623), size: 24),
              tooltip: 'Nueva canción',
              onPressed: () => SongDialogs.showNewSongDialog(context, context.read<LibraryProvider>(), onSongCreated: _switchSong),
            ),
          if (!isCompact && _viewMode != _ViewMode.edit && _currentMetadata != null)
            _buildFontSizeBtn(),
            
          if (isCompact)
            IconButton(
              icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 22),
              tooltip: 'Buscar canción',
              onPressed: _showQuickSearch,
            ),
          if (isCompact) _buildCompactActions(),
        ],
      ),
    );
  }

  void _showQuickSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _SongListPanel(
                  width: double.infinity,
                  currentFilePath: _currentMetadata?.filePath ?? '',
                  onSongSelected: (song) {
                    Navigator.pop(ctx);
                    _switchSong(song);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBtn() {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
      tooltip: 'Eliminar canción',
      onPressed: _confirmDeleteSong,
    );
  }

  void _confirmDeleteSong() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Eliminar canción'),
        content: Text('¿Seguro que deseas eliminar "${_currentMetadata!.displayTitle}" permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Theme.of(context).colorScheme.onSurface),
            onPressed: () async {
              await context.read<LibraryProvider>().deleteSong(_currentMetadata!);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeBtn({bool asListTile = false}) {
    if (asListTile) {
      return ListTile(
        leading: Icon(Icons.format_size, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
        title: const Text('Tamaño de letra'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          _showFontSizePicker();
        },
      );
    }
    return PopupMenuButton<double>(
      icon: Icon(Icons.format_size, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
      tooltip: 'Tamaño de letra',
      onSelected: (s) => setState(() => _fontSize = s),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 13, child: Text('Pequeño')),
        PopupMenuItem(value: 16, child: Text('Normal')),
        PopupMenuItem(value: 19, child: Text('Grande')),
        PopupMenuItem(value: 22, child: Text('Muy grande')),
      ],
    );
  }

  void _showFontSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Tamaño de letra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...[13.0, 16.0, 19.0, 22.0].map((s) => ListTile(
            title: Text(s == 13 ? 'Pequeño' : s == 16 ? 'Normal' : s == 19 ? 'Grande' : 'Muy grande'),
            selected: _fontSize == s,
            onTap: () {
              setState(() => _fontSize = s);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildCompactActions() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
      onSelected: (val) {
        switch (val) {
          case 'mode': _showModeSwitcher(); break;
          case 'transpose': _showTransposePicker(); break;
          case 'setlist': _showAddToSetlistModal(); break;
          case 'new': SongDialogs.showNewSongDialog(context, context.read<LibraryProvider>(), onSongCreated: _switchSong); break;
          case 'fontsize': _showFontSizePicker(); break;
          case 'delete': _confirmDeleteSong(); break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'mode', child: ListTile(leading: Icon(Icons.visibility_outlined), title: Text('Modo de vista'), contentPadding: EdgeInsets.zero)),
        if (_viewMode != _ViewMode.edit)
          const PopupMenuItem(value: 'transpose', child: ListTile(leading: Icon(Icons.music_note_outlined), title: Text('Cambiar tono'), contentPadding: EdgeInsets.zero)),
        if (_viewMode != _ViewMode.edit)
          const PopupMenuItem(value: 'setlist', child: ListTile(leading: Icon(Icons.playlist_add), title: Text('Añadir a Setlist'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'fontsize', child: ListTile(leading: Icon(Icons.format_size), title: Text('Tamaño de letra'), contentPadding: EdgeInsets.zero)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'new', child: ListTile(leading: Icon(Icons.add, color: Color(0xFFF5A623)), title: Text('Nueva canción'), contentPadding: EdgeInsets.zero)),
        if (_viewMode == _ViewMode.edit)
          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.redAccent), title: Text('Eliminar'), contentPadding: EdgeInsets.zero)),
      ],
    );
  }

  void _showModeSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Modo de vista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text('Acordes + Letra'),
              selected: _viewMode == _ViewMode.normal,
              onTap: () { setState(() => _viewMode = _ViewMode.normal); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Solo Letra'),
              selected: _viewMode == _ViewMode.lyrics,
              onTap: () { setState(() => _viewMode = _ViewMode.lyrics); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar Archivo'),
              selected: _viewMode == _ViewMode.edit,
              onTap: () { setState(() => _viewMode = _ViewMode.edit); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showTransposePicker() {
     showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Cambiar tono', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: 12,
                itemBuilder: (context, i) {
                  final s = i - 5; // -5 to 6
                  final originalKey = _song?.metadata.key ?? '';
                  String label = s == 0 ? 'Original' : (s > 0 ? '+$s' : '$s');
                  if (originalKey.isNotEmpty) {
                    final k = ChordTransposer.transposeChord(originalKey, s, useFlats: _useFlats);
                    label = s == 0 ? '$k (Original)' : k;
                  }
                  return ListTile(
                    title: Text(label),
                    selected: _transposeSteps == s,
                    onTap: () {
                      setState(() => _transposeSteps = s);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SwitchListTile(
                title: const Text('Usar bemoles (♭)'),
                value: _useFlats,
                onChanged: (val) {
                  setState(() => _useFlats = val);
                  Navigator.pop(ctx);
                  _showTransposePicker();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToSetlistModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer<SetlistProvider>(
          builder: (context, provider, child) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Añadir a Setlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                  if (provider.setlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('No tienes setlists creados.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: provider.setlists.length,
                        itemBuilder: (context, index) {
                          final setlist = provider.setlists[index];
                          final bool hasSong = setlist.songPaths.contains(_currentMetadata!.filePath);
                          return ListTile(
                            leading: Icon(
                              Icons.queue_music,
                              color: hasSong ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38) : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(setlist.name, style: TextStyle(color: hasSong ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54) : Theme.of(context).colorScheme.onSurface)),
                            subtitle: Text('${setlist.songPaths.length} canciones', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
                            trailing: hasSong ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: hasSong ? null : () {
                              provider.addSongToSetlist(setlist.id, _currentMetadata!.filePath);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Añadido a ${setlist.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  backgroundColor: const Color(0xFF323232),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                  ListTile(
                    leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                    title: Text('Crear nuevo Setlist', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCreateSetlistDialog();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateSetlistDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Nuevo Setlist', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nombre del Setlist',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<SetlistProvider>().createSetlist(val.trim()).then((_) {
                 final newId = context.read<SetlistProvider>().setlists.last.id;
                 context.read<SetlistProvider>().addSongToSetlist(newId, _currentMetadata!.filePath);
                 Navigator.pop(ctx);
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<SetlistProvider>().createSetlist(controller.text.trim()).then((_) {
                   final newId = context.read<SetlistProvider>().setlists.last.id;
                   context.read<SetlistProvider>().addSongToSetlist(newId, _currentMetadata!.filePath);
                   Navigator.pop(ctx);
                });
              }
            },
            child: const Text('Crear y Añadir'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final borderColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModeBtn(_ViewMode.normal, Icons.music_note_outlined, 'Acordes + Letra'),
                Container(width: 1, color: borderColor),
                _buildModeBtn(_ViewMode.lyrics, Icons.text_fields, 'Solo Letra'),
                Container(width: 1, color: borderColor),
                _buildModeBtn(_ViewMode.edit, Icons.edit_outlined, 'Editar Archivo'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBtn(_ViewMode mode, IconData icon, String tooltip) {
    final isSelected = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          width: 44,
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }

  Widget _buildTransposeControls() {
    final borderColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _transposeSteps--),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Icon(Icons.remove, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70)),
                  ),
                ),
                Container(width: 1, color: borderColor),
                PopupMenuButton<int>(
                  initialValue: _transposeSteps,
                  tooltip: 'Elegir tono',
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12))),
                  onSelected: (steps) => setState(() => _transposeSteps = steps),
                  itemBuilder: (context) {
                    final originalKey = _song?.metadata.key ?? '';
                    final sortedSteps = [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6];
                    return sortedSteps.map((s) {
                      String label = s == 0 ? 'Original' : (s > 0 ? '+$s' : '$s');
                      if (originalKey.isNotEmpty) {
                        final k = ChordTransposer.transposeChord(originalKey, s, useFlats: _useFlats);
                        label = s == 0 ? '$k (Original)' : k;
                      }
                      return PopupMenuItem<int>(
                        value: s,
                        child: Text(
                          label,
                          style: TextStyle(color: s == _transposeSteps ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minWidth: 55),
                    child: Text(
                      (_song?.metadata.key.isNotEmpty == true && _displaySong?.metadata.key.isNotEmpty == true)
                          ? 'Tono: ${_displaySong!.metadata.key}'
                          : (_transposeSteps == 0 ? 'Tono original' : (_transposeSteps > 0 ? '+$_transposeSteps' : '$_transposeSteps')),
                      style: TextStyle(
                        color: _transposeSteps == 0 ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54) : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, color: borderColor),
                InkWell(
                  onTap: () => setState(() => _transposeSteps++),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70)),
                  ),
                ),
                Container(width: 1, color: borderColor),
                InkWell(
                  onTap: () => setState(() => _useFlats = !_useFlats),
                  child: Container(
                    width: 42,
                    alignment: Alignment.center,
                    child: Text(
                      _useFlats ? '♭' : '#',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Cuerpo ───────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_currentMetadata == null) {
      return Center(
        child: Text(
          'Selecciona una canción de la lista',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16),
        ),
      );
    }
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    return switch (_viewMode) {
      _ViewMode.normal => _buildSongView(showChords: true),
      _ViewMode.lyrics => _buildSongView(showChords: false),
      _ViewMode.edit => _buildEditView(),
    };
  }

  // ─── Vista canción ────────────────────────────────────────────────────────

  Widget _buildSongView({required bool showChords}) {
    if (_displaySong == null) return const SizedBox();
    final sections = _displaySong!.sections.where((s) {
      if (!s.hasContent) return false;
      if (!showChords) {
        bool hasLyrics = false;
        for (var line in s.lines) {
          if (line.chunks.any((c) => c.lyrics.trim().isNotEmpty)) {
            hasLyrics = true;
            break;
          }
        }
        if (!hasLyrics) return false;
      }
      return true;
    }).toList();
    final effectiveFontSize =
        _viewMode == _ViewMode.lyrics ? _fontSize + 3 : _fontSize;

    return GestureDetector(
      onScaleStart: (_) => _initialFontSize = _fontSize,
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          setState(() {
            _fontSize = (_initialFontSize * details.scale).clamp(10, 40);
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSongHeader(),
                const SizedBox(height: 36),
                ...sections.map((s) =>
                    _buildSection(s, showChords: showChords, fontSize: effectiveFontSize)),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Vista edición ────────────────────────────────────────────────────────

  Widget _buildEditView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentMetadata!.filePath.split('/').last,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12),
                  ),
                ),
                if (_hasUnsavedChanges)
                  Text('● Sin guardar',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Focus(
              autofocus: true,
              child: TextField(
                controller: _editController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) {
                  if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
                },
                style: GoogleFonts.sourceCodePro(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                  height: 1.65,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasUnsavedChanges ? _saveFile : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Encabezado canción ───────────────────────────────────────────────────

  Widget _buildSongHeader() {
    final meta = _displaySong!.metadata;
    final titleText = (meta.number != null && meta.number!.trim().isNotEmpty)
        ? '${meta.number!.trim()}. ${meta.displayTitle}'
        : meta.displayTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          titleText,
          style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, height: 1.2),
          textAlign: TextAlign.center,
        ),
        if (meta.displayArtist.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(meta.displayArtist,
              style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              textAlign: TextAlign.center),
        ],
        if (meta.key.isNotEmpty || meta.tempo != null) ...[
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              if (meta.key.isNotEmpty) _badge('TONO  ${meta.key}', Theme.of(context).colorScheme.primary),
              if (meta.tempo != null) _badge('♩ ${meta.tempo} BPM', Theme.of(context).colorScheme.onSurface, isMuted: true),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [Colors.transparent, Theme.of(context).colorScheme.primary]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.music_note,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), size: 16),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.transparent]),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _badge(String text, Color baseColor, {bool isMuted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isMuted ? baseColor.withValues(alpha: 0.54) : baseColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Sección ──────────────────────────────────────────────────────────────

  Widget _buildSection(SongSection section,
      {required bool showChords, required double fontSize}) {
    final (labelColor, borderColor, bgColor) = switch (section.type) {
      SectionType.chorus => (
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        ),
      SectionType.bridge => (
          const Color(0xFFE8845C),
          const Color(0xFFE8845C),
          const Color(0xFFE8845C).withValues(alpha: 0.05),
        ),
      SectionType.intro => (
          const Color(0xFF4DD0E1), // teal/cyan
          const Color(0xFF4DD0E1),
          const Color(0xFF4DD0E1).withValues(alpha: 0.05),
        ),
      SectionType.outro => (
          const Color(0xFFB39DDB), // lavanda/lila
          const Color(0xFFB39DDB),
          const Color(0xFFB39DDB).withValues(alpha: 0.05),
        ),
      _ => (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), Colors.transparent),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borde lateral de color (sin texto)
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Contenido centrado
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (section.type != SectionType.verse && section.type != SectionType.other)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 4),
                        child: Text(
                          section.name.toUpperCase(),
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ...section.lines.map((line) => ChordLineWidget(
                          line: line,
                          fontSize: fontSize,
                          showChords: showChords,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel lateral de canciones ───────────────────────────────────────────────

class _SongListPanel extends StatefulWidget {
  final double width;
  final String currentFilePath;
  final ValueChanged<SongMetadata> onSongSelected;

  const _SongListPanel({
    required this.width,
    required this.currentFilePath,
    required this.onSongSelected,
  });

  @override
  State<_SongListPanel> createState() => _SongListPanelState();
}

class _SongListPanelState extends State<_SongListPanel> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final Set<String> _collapsedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SongMetadata> _filter(List<SongMetadata> songs) {
    if (_searchQuery.isEmpty) return songs;
    final q = _searchQuery.toLowerCase();
    return songs
        .where((s) =>
            s.displayTitle.toLowerCase().contains(q) ||
            s.displayArtist.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<SongMetadata>> _group(List<SongMetadata> songs) {
    final result = <String, List<SongMetadata>>{};
    for (final s in songs) {
      result.putIfAbsent(s.category ?? 'General', () => []).add(s);
    }
    final sorted = result.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, _) {
        final filtered = _filter(library.songs);
        final grouped = _group(filtered);

        return Container(
          width: widget.width,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Column(
            children: [
              // ── Buscador ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) => setState(() => _searchQuery = q),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ── Contador ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} canciones',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11),
                    ),
                  ],
                ),
              ),

              // ── Lista agrupada ────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final category = grouped.keys.elementAt(i);
                    final songs = grouped[category]!;
                    final isCollapsed = _collapsedCategories.contains(category) && _searchQuery.isEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabecera de categoría
                        InkWell(
                          onTap: () {
                            if (_searchQuery.isNotEmpty) return;
                            setState(() {
                              if (_collapsedCategories.contains(category)) {
                                _collapsedCategories.remove(category);
                              } else {
                                _collapsedCategories.add(category);
                              }
                            });
                          },
                          splashColor: Colors.transparent,
                          highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 14, 14, 8),
                            child: Row(
                              children: [
                                Icon(isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
                                    color: Theme.of(context).colorScheme.primary, size: 16),
                                const SizedBox(width: 2),
                                Icon(isCollapsed ? Icons.folder_outlined : Icons.folder_open_outlined,
                                    color: Theme.of(context).colorScheme.primary, size: 13),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Canciones de la categoría
                        if (!isCollapsed)
                          ...songs.map((s) => _buildSongTile(context, s)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, SongMetadata song) {
    final isCurrent = song.filePath == widget.currentFilePath;

    return Material(
      color: isCurrent
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSongSelected(song),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              // Indicador canción actual
              SizedBox(
                width: 16,
                child: isCurrent
                    ? Icon(Icons.play_arrow,
                        color: Theme.of(context).colorScheme.primary, size: 14)
                    : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (song.number != null && song.number!.trim().isNotEmpty)
                          ? '${song.number!.trim()}. ${song.displayTitle}'
                          : song.displayTitle,
                      style: TextStyle(
                        color: isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.displayArtist.isNotEmpty)
                      Text(
                        song.displayArtist,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Badge de tono
              if (song.key.isNotEmpty)
                Text(
                  song.key,
                  style: TextStyle(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Handle para redimensionar el panel ───────────────────────────────────────

class _ResizableHandle extends StatefulWidget {
  final ValueChanged<double> onDrag;

  const _ResizableHandle({required this.onDrag});

  @override
  State<_ResizableHandle> createState() => _ResizableHandleState();
}

class _ResizableHandleState extends State<_ResizableHandle> {
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovering || _isDragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isActive ? 6 : 4,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isActive ? 2 : 1,
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
