import 'package:flutter/material.dart';

class MobileSongControls extends StatelessWidget {
  final String keyLabel;
  final int fontSize;
  final VoidCallback onTransposeDown;
  final VoidCallback onTransposeUp;
  final VoidCallback onFontSizeDown;
  final VoidCallback onFontSizeUp;

  const MobileSongControls({
    super.key,
    required this.keyLabel,
    required this.fontSize,
    required this.onTransposeDown,
    required this.onTransposeUp,
    required this.onFontSizeDown,
    required this.onFontSizeUp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Stepper(
                  label: 'Tono',
                  value: keyLabel,
                  decreaseTooltip: 'Bajar un semitono',
                  increaseTooltip: 'Subir un semitono',
                  onDecrease: onTransposeDown,
                  onIncrease: onTransposeUp,
                ),
              ),
              VerticalDivider(
                width: 1,
                indent: 12,
                endIndent: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _Stepper(
                  label: 'Letra',
                  value: '$fontSize px',
                  decreaseTooltip: 'Disminuir tamaño de letra',
                  increaseTooltip: 'Aumentar tamaño de letra',
                  onDecrease: onFontSizeDown,
                  onIncrease: onFontSizeUp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final String value;
  final String decreaseTooltip;
  final String increaseTooltip;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _Stepper({
    required this.label,
    required this.value,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        IconButton(
          tooltip: decreaseTooltip,
          onPressed: onDecrease,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 48),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove, size: 20),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.54),
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: increaseTooltip,
          onPressed: onIncrease,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 48),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.add, size: 20),
        ),
      ],
    );
  }
}
