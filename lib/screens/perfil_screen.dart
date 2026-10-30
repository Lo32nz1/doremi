import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
    const PerfilScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                            Text('Contenido de Perfil', style: TextStyle(fontSize: 24)),
                            Text('Contenido de Perfil', style: TextStyle(fontSize: 24)),
                        ],
                    ),
                    const SizedBox(height: 20), // Espaciador opcional
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                            Text('Contenido de Perfil', style: TextStyle(fontSize: 24)),
                            Text('Contenido de Perfil', style: TextStyle(fontSize: 24)),
                        ],
                    ),
                ],
            )
        );
    }
}
