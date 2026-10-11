import 'correction_state.dart';
import 'engine/correction_engine.dart';

/// Builds the single spoken utterance for the Correction screen (bs-05 AC-7).
///
/// "Speak correction" (wireframe S1.R1.E27) reads the whole check back as one
/// utterance: the difference (its plain verdict and the value-leading
/// decomposition) and the concrete correction (each paint to add and its
/// amount). The spoken text reuses the exact strings the difference and
/// correction regions already show — the [Difference]'s `verdict` /
/// `valueReading` / `hueReading` and each [CorrectionAddition]'s `paint.name`
/// rendered with bs-04's "a touch of" / "add about N parts" idiom — so the heard
/// correction never drifts from the seen one, mirroring bs-03's
/// `comparisonSpeech` and bs-04's `recipeSpeech`.
///
/// A mix already within tolerance (AC-6) has an empty [Correction] but still a
/// difference ("very close"): the utterance states the verdict and that there is
/// nothing to add, so the painter hears the good news rather than silence.
///
/// Returns null when the mix has not been checked yet ([CorrectionState.difference]
/// null) — there is nothing to speak, so the speak control stays disabled and the
/// action is inert.
String? correctionSpeech(CorrectionState state) {
  final difference = state.difference;
  if (difference == null) return null;
  final correction = state.correction;
  return [
    // The difference: verdict + distance, then the value-leading decomposition
    // (value first for a CVD painter, hue second), matching DifferenceRegion.
    'Difference: ${difference.verdict}, '
        'delta-E00 ${difference.deltaE00.toStringAsFixed(1)}.',
    '${difference.valueReading}.',
    '${difference.hueReading}.',
    // The correction: each paint to add, or the no-correction state (AC-6).
    if (correction == null || correction.isEmpty)
      'No paints to add.'
    else ...[
      'Add to your mix:',
      for (final addition in correction.additions) _additionPhrase(addition),
    ],
  ].join(' ');
}

/// One addition spoken: `a touch of <paint>` for a trace (AC-5) or
/// `add about N parts of <paint>` for a measured amount (AC-4) — the spoken
/// counterpart of `CorrectionRegion`'s line for the same addition.
String _additionPhrase(CorrectionAddition addition) {
  if (addition.isTrace) return 'a touch of ${addition.paint.name}.';
  return 'add about ${_parts(addition.parts)} of ${addition.paint.name}.';
}

/// The addition amount as painter-facing parts by volume (illustrative,
/// G-4(a)): one decimal place, pluralised — matching `CorrectionRegion._parts`.
String _parts(double parts) {
  final text = parts.toStringAsFixed(1);
  return text == '1.0' ? '1 part' : '$text parts';
}
