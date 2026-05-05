import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/setlist_provider.dart';
import 'setlist_view_screen.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mis Setlists', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SetlistProvider>(
        builder: (context, provider, child) {
          if (provider.setlists.isEmpty) {
            return Center(
              child: Text(
                'No tienes Setlists.\nToca + para crear uno.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16, height: 1.5),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.setlists.length,
            itemBuilder: (context, index) {
              final setlist = provider.setlists[index];
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.queue_music, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${setlist.songPaths.length} canciones', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Eliminar Setlist'),
                        content: Text('¿Seguro que deseas eliminar "${setlist.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteSetlist(setlist.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetlistViewScreen(setlistId: setlist.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Nuevo Setlist'),
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
              context.read<SetlistProvider>().createSetlist(val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<SetlistProvider>().createSetlist(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
