import 'package:flutter/material.dart';

/// A numeric reading always paired with its plain-language word.
///
/// e.g. the lightness "58" shown with "middle value" (AC-1, AC-2). A number is
/// never shown alone — [word] is required and must be non-empty — so the reading
/// is meaningful without interpreting the figure (SI Accessibility). The
/// optional [numberStyle] lets the readout size the figure prominently (AC-1);
/// both parts are folded into a single semantics announcement.
class ValueReading extends StatelessWidget {
  const ValueReading({
    required this.number,
    required this.word,
    this.numberStyle,
    super.key,
  }) : assert(
          word != '',
          'ValueReading requires a plain-language word; a number alone conveys '
          'no meaning (SI Accessibility).',
        );

  /// The numeric reading, already formatted for display (e.g. "58").
  final String number;

  /// The plain-language word for the number (e.g. "middle value").
  final String word;

  /// Optional text style for the number, so callers can size it prominently.
  final TextStyle? numberStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$number, $word',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(number, style: numberStyle),
          const SizedBox(width: 8),
          Text(word),
        ],
      ),
    );
  }
}
