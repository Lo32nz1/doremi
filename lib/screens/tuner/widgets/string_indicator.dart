import 'package:flutter/material.dart';
import '../../../models/instrument.dart';
import '../../../services/tuner_service.dart';

/// Muestra las cuerdas del instrumento activo.
/// Resalta la cuerda más cercana a la frecuencia detectada.
/// Permite fijar una cuerda con tap (modo single-string).
class StringIndicator extends StatelessWidget {
  final Instrument instrument;
  final TunerResult currentResult;
  final InstrumentString? lockedString;
  final ValueChanged<InstrumentString?> onStringTapped;

  const StringIndicator({
    super.key,
    required this.instrument,
    required this.currentResult,
    required this.lockedString,
    required this.onStringTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (instrument.strings.isEmpty) {
      // Modo cromático — no hay cuerdas que mostrar
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final nearestString = currentResult.nearestString;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: instrument.strings.map((string) {
          final isNearest = nearestString?.name == string.name;
          final isLocked = lockedString?.name == string.name;
          final isHighlighted =
              isLocked || (!isLocked && lockedString == null && isNearest);

          return Tooltip(
            message: isLocked
                ? 'Desfijar cuerda ${string.name}'
                : 'Afinar cuerda ${string.name}',
            child: GestureDetector(
              onTap: () {
                if (isLocked) {
                  onStringTapped(null);
                } else {
                  onStringTapped(string);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isHighlighted ? 52 : 44,
                height: isHighlighted ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHighlighted
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainer,
                  border: Border.all(
                    color: isHighlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    width: isHighlighted ? 2.0 : 1.0,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      string.name.replaceAll(
                        RegExp(r'\d'),
                        '',
                      ), // Solo la letra
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isHighlighted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        fontWeight: isHighlighted
                            ? FontWeight.w800
                            : FontWeight.w500,
                        fontSize: isHighlighted ? 15 : 13,
                      ),
                    ),
                    Text(
                      string.name.replaceAll(
                        RegExp(r'[A-Z#]'),
                        '',
                      ), // Solo el número
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isHighlighted
                            ? theme.colorScheme.primary.withValues(alpha: 0.8)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
