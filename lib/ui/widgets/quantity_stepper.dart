import 'package:flutter/material.dart';

/// A touch-first quantity stepper widget designed for fast mobile and kiosk
/// use without needing the on-screen keyboard.
///
/// Features large tap targets, tactile buttons, and optional quick-increment
/// chips (+1, +5, +10).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.showPresets = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final bool showPresets;

  void _decrement([int step = 1]) {
    final next = (value - step).clamp(min, max ?? 999999);
    onChanged(next);
  }

  void _increment([int step = 1]) {
    final next = (value + step).clamp(min, max ?? 999999);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrement = value > min;
    final canIncrement = max == null || value < max!;

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease',
          iconSize: 20,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(
            backgroundColor: canDecrement
                ? theme.colorScheme.surfaceContainerHighest
                : theme.disabledColor.withValues(alpha: 0.08),
            foregroundColor: canDecrement
                ? theme.colorScheme.onSurfaceVariant
                : theme.disabledColor,
          ),
          icon: const Icon(Icons.remove),
          onPressed: canDecrement ? () => _decrement(1) : null,
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: value > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Increase',
          iconSize: 20,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(
            backgroundColor: canIncrement
                ? theme.colorScheme.primaryContainer
                : theme.disabledColor.withValues(alpha: 0.08),
            foregroundColor: canIncrement
                ? theme.colorScheme.onPrimaryContainer
                : theme.disabledColor,
          ),
          icon: const Icon(Icons.add),
          onPressed: canIncrement ? () => _increment(1) : null,
        ),
      ],
    );

    if (!showPresets) return controls;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        controls,
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PresetChip(label: '+1', onTap: () => _increment(1)),
            _PresetChip(label: '+5', onTap: () => _increment(5)),
            _PresetChip(label: '+10', onTap: () => _increment(10)),
            if (value > 0)
              _PresetChip(
                label: 'Clear',
                isDestructive: true,
                onTap: () => onChanged(min),
              ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isDestructive
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDestructive
                  ? theme.colorScheme.error.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
