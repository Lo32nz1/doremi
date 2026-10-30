import 'package:flutter/material.dart';

class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Base del medidor
                Container(
                  height: 150,
                  width: 300,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(150)),
                  ),
                ),
                // Aguja indicadora
                Transform.rotate(
                  angle: 0.2, // Cambia este valor para mover la aguja
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 140,
                    width: 4,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'E4',
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              '329.63 Hz',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Standard')),
                ElevatedButton(onPressed: () {}, child: const Text('Drop D')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
