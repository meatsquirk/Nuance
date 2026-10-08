import '../../compare/comparison_state.dart';
import 'confusion_check.dart';

/// Builds the single spoken utterance for the whole comparison (AC-9).
///
/// "Speak whole comparison" (wireframe S1.R1.E6) reads the entire reading as one
/// utterance: the overall difference and its plain verdict, the three LCh
/// decomposition lines (the relational statement), and — when the pair is
/// confusable for the painter's colour-vision profile — the confusion warning.
/// The spoken text reuses the exact strings the on-screen regions already show —
/// DIFF's [Comparison] fields (`verdict`, `deltaE00`, `lightness`, `saturation`,
/// `hue`) and the canonical [confusionWarningMessage] — so the heard comparison
/// never drifts from the seen one, and the warning constant has one author
/// (CVD-2) rather than a second copy here.
///
/// Returns null when there is no reading yet — either slot empty, so [state]'s
/// `comparison` is null (AC-12). There is nothing to speak, so the speak control
/// stays disabled and the action is inert.
String? comparisonSpeech(ComparisonState state) {
  final comparison = state.comparison;
  if (comparison == null) return null;
  return [
    'Overall difference: ${comparison.verdict}, '
        'delta-E00 ${comparison.deltaE00.toStringAsFixed(1)}.',
    '${comparison.lightness}.',
    '${comparison.saturation}.',
    '${comparison.hue}.',
    if (state.confusable) confusionWarningMessage,
  ].join(' ');
}
