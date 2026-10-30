import 'package:flutter/material.dart';

class SongBookScreen extends StatelessWidget {
    const SongBookScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Cancionero'),
                backgroundColor: Colors.blue,
            ),
        );
    }
}

