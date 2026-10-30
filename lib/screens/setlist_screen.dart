import 'package:flutter/material.dart';

class SetlistScreen extends StatefulWidget {
  const SetlistScreen({super.key});

  @override
  State<SetlistScreen> createState() => _SetlistScreenState();
}

class _SetlistScreenState extends State<SetlistScreen> {
  final List<String> _canciones = ['Intro', 'Tema Principal', 'Solo de guitarra', 'Outro'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlist de Ensayo'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _canciones.removeAt(oldIndex);
            _canciones.insert(newIndex, item);
          });
        },
        children: [
          for (int index = 0; index < _canciones.length; index += 1)
            Card(
              key: Key('$index'),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(_canciones[index]),
                subtitle: const Text('Afinación: Drop D'),
                trailing: const Icon(Icons.drag_handle),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Tiempo total estimado:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('18:45 min'),
            ],
          ),
        ),
      ),
    );
  }
}
