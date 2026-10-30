import 'package:flutter/material.dart';
import 'package:doremi/screens/songBook_screen.dart';
import 'package:doremi/screens/album_screen.dart';
import 'package:doremi/screens/setlist_screen.dart';
import 'package:doremi/screens/tuner_screen.dart';
import 'package:doremi/screens/config_screen.dart';

void main() {
  runApp(const MaterialApp(home: CarcasaBase()));
}

class CarcasaBase extends StatefulWidget {
  const CarcasaBase({super.key});

  @override
  State<CarcasaBase> createState() => _CarcasaBaseState();
}

class _CarcasaBaseState extends State<CarcasaBase> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = [
    const InicioScreen(),
    const AlbumScreen(),
    const SetlistScreen(),
    const TunerScreen(),
    const ConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicación Doremi'),
        backgroundColor: Colors.blue,
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual,
        onTap: (int nuevoIndice) {
          setState(() {
            _indiceActual = nuevoIndice;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Album'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listas'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Afinador'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}
