import 'package:flutter/material.dart';
import '../../../models/instrument.dart';

/// Selector horizontal de instrumentos con chips animados.
class InstrumentSelector extends StatefulWidget {
  final Instrument selectedInstrument;
  final ValueChanged<Instrument> onSelected;

  const InstrumentSelector({
    super.key,
    required this.selectedInstrument,
    required this.onSelected,
  });

  @override
  State<InstrumentSelector> createState() => _InstrumentSelectorState();
}

class _InstrumentSelectorState extends State<InstrumentSelector> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instruments = InstrumentCatalog.all;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: instruments.length,
        separatorBuilder: (context, idx) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final instrument = instruments[index];
          final isSelected = instrument.id == widget.selectedInstrument.id;

          return AnimatedScale(
            scale: isSelected ? 1.07 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: () => widget.onSelected(instrument),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      instrument.icon,
                      size: 14,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      instrument.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
