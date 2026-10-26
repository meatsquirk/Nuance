import 'package:flutter/material.dart';

/// The 0–10 Munsell value scale: an 11-step strip (0..10) with the sample's
/// Munsell value marked on it (AC-2).
///
/// The scale renders the eleven whole steps 0..10 as labelled cells, left
/// (darkest, 0) to right (lightest, 10), and marks the step nearest the
/// sample's Munsell [value]. The marked step is distinguished *without relying
/// on colour* — a filled, bordered cell with a bold label and a caret pointing
/// to it — and carries a `Semantics(selected: true)` so a screen reader (and
/// the acceptance test) can tell which step is the sample's.
///
/// READOUT-2 introduced the findable [scaleKey] anchor as an empty shell;
/// READOUT-5 (here) renders the labelled steps and marks the sample's value.
class ValueScale extends StatelessWidget {
  /// Creates the scale marking [value] (the sample's Munsell value, 0..10).
  const ValueScale({required this.value, super.key});

  /// Stable anchor for the 0–10 value scale (AC-2).
  static const Key scaleKey = ValueKey('readout-value-scale');

  /// Lowest and highest step the Munsell value scale runs over.
  static const int minStep = 0;
  static const int maxStep = 10;

  /// The sample's Munsell value (0..10); the nearest whole step is marked.
  final double value;

  @override
  Widget build(BuildContext context) {
    // The sample's value rounded to the nearest whole step on the 0..10 scale,
    // clamped so an out-of-range reading still marks an end step rather than
    // nothing.
    final markedStep = value.round().clamp(minStep, maxStep);
    return Semantics(
      key: scaleKey,
      container: true,
      label: 'Munsell value scale, 0 (darkest) to 10 (lightest)',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var n = minStep; n <= maxStep; n++)
            Expanded(child: _step(context, n, marked: n == markedStep)),
        ],
      ),
    );
  }

  /// One step of the scale: its number [n], marked when it is the sample's step.
  Widget _step(BuildContext context, int n, {required bool marked}) {
    final theme = Theme.of(context);
    final label = Text(
      '$n',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: marked ? FontWeight.bold : FontWeight.normal,
        color: marked ? theme.colorScheme.onPrimary : null,
      ),
    );
    final cell = Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: marked
          ? BoxDecoration(
              color: theme.colorScheme.primary,
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(4),
            )
          : BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
      child: label,
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A caret above the marked step, so "which step" reads without colour
        // (the sample's value, the SI accessibility concern).
        SizedBox(
          height: 10,
          child: marked
              ? Icon(Icons.arrow_drop_down,
                  size: 20, color: theme.colorScheme.primary)
              : null,
        ),
        cell,
      ],
    );
    if (!marked) return column;
    // The marked step carries the sample's value for assistive tech (and the
    // AC-2 Then, which asserts exactly one selected step bearing the value).
    return Semantics(
      selected: true,
      label: 'Value $n, this sample',
      child: column,
    );
  }
}
