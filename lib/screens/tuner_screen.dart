import 'package:flutter/material.dart';

/// Modelo base de una cuerda de guitarra estándar.
class GuitarStringNote {
  final int stringNumber;
  final String latinName;
  final String americanName;
  final double frequencyHz;

  const GuitarStringNote({
    required this.stringNumber,
    required this.latinName,
    required this.americanName,
    required this.frequencyHz,
  });
}

/// Pantalla base del Módulo 3 (Afinador de Guitarra).
/// Cuenta con indicador de nota central, medidor visual de afinación y selector
/// de las 6 cuerdas (Mi, La, Re, Sol, Si, Mi), lista para conectar el micrófono.
class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  static const List<GuitarStringNote> _guitarStrings = [
    GuitarStringNote(
      stringNumber: 6,
      latinName: 'Mi',
      americanName: 'E2',
      frequencyHz: 82.41,
    ),
    GuitarStringNote(
      stringNumber: 5,
      latinName: 'La',
      americanName: 'A2',
      frequencyHz: 110.00,
    ),
    GuitarStringNote(
      stringNumber: 4,
      latinName: 'Re',
      americanName: 'D3',
      frequencyHz: 146.83,
    ),
    GuitarStringNote(
      stringNumber: 3,
      latinName: 'Sol',
      americanName: 'G3',
      frequencyHz: 196.00,
    ),
    GuitarStringNote(
      stringNumber: 2,
      latinName: 'Si',
      americanName: 'B3',
      frequencyHz: 246.94,
    ),
    GuitarStringNote(
      stringNumber: 1,
      latinName: 'Mi',
      americanName: 'E4',
      frequencyHz: 329.63,
    ),
  ];

  int _selectedIndex = 0;
  double _centsDeviation = 0.0; // Rango de -50 a +50 cents para prueba visual
  bool _isMicListening = false;

  GuitarStringNote get _selectedString => _guitarStrings[_selectedIndex];

  bool get _isInTune => _centsDeviation.abs() <= 5.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _isInTune
        ? Colors.greenAccent.shade400
        : (_centsDeviation < 0 ? Colors.amberAccent : Colors.redAccent);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Afinador de Guitarra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _isMicListening ? 'Detener micrófono' : 'Activar micrófono',
            icon: Icon(_isMicListening ? Icons.mic : Icons.mic_none),
            color: _isMicListening ? theme.colorScheme.primary : null,
            onPressed: () {
              setState(() => _isMicListening = !_isMicListening);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isMicListening
                        ? 'Simulación activa (Listo para conectar captura de audio en Módulo 3)'
                        : 'Micrófono en pausa',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Indicador de nota central
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHigh,
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.85),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_selectedString.stringNumber}ª Cuerda',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedString.latinName,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    '${_selectedString.americanName} • ${_selectedString.frequencyHz.toStringAsFixed(2)} Hz',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Medidor visual de afinación (-50 a +50 cents)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '♭ Bajo (-50)',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        _isInTune
                            ? 'AFINADO'
                            : (_centsDeviation < 0
                                ? 'Subir tensión'
                                : 'Bajar tensión'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const Text(
                        'Alto (+50) ♯',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Barra de aguja visual
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final normalized =
                          ((_centsDeviation + 50) / 100).clamp(0.0, 1.0);
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 12,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.amber,
                                  Colors.greenAccent,
                                  Colors.redAccent,
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 3,
                              height: 22,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            left: (constraints.maxWidth - 16) * normalized,
                            child: Container(
                              width: 16,
                              height: 24,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _centsDeviation,
                    min: -50,
                    max: 50,
                    divisions: 100,
                    label: '${_centsDeviation.round()} cents',
                    onChanged: (value) {
                      setState(() => _centsDeviation = value);
                    },
                  ),
                  Text(
                    'Desviación simulada: ${_centsDeviation > 0 ? '+' : ''}${_centsDeviation.round()} cents',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Selector de las 6 cuerdas de la guitarra (Mi, La, Re, Sol, Si, Mi)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cuerdas de la guitarra (6ª a 1ª):',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _guitarStrings.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final item = _guitarStrings[index];
                final isSelected = index == _selectedIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                      _centsDeviation = 0;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${item.stringNumber}ª • ${item.latinName}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.americanName} (${item.frequencyHz.toInt()} Hz)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

