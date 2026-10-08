import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/comparison_speech.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/compare/comparison_state.dart';
import 'package:paint_color_assistant/compare/difference.dart';

const _comparison = Comparison(
  deltaE00: 13.05,
  verdict: 'clearly different',
  lightness: 'Lighter by 12',
  saturation: 'Less saturated by 9',
  hue: 'Hue shifted 18 degrees toward yellow',
);

void main() {
  group('comparisonSpeech', () {
    test('returns null when there is no reading (either slot empty, AC-12)', () {
      // No comparison ⇒ nothing to speak, so the speak action stays inert.
      expect(comparisonSpeech(const ComparisonState()), isNull);
      expect(
        comparisonSpeech(const ComparisonState(comparison: null, confusable: true)),
        isNull,
        reason: 'a stray confusable flag with no reading still speaks nothing',
      );
    });

    test('states the overall difference and all three LCh lines (AC-9)', () {
      const state = ComparisonState(comparison: _comparison);
      final spoken = comparisonSpeech(state)!;

      // The whole comparison: the overall verdict + ΔE00, then each relational
      // line, reusing DIFF's exact strings (rejects dropping a dimension).
      expect(spoken, contains('clearly different'));
      expect(spoken, contains('delta-E00 13.1'));
      expect(spoken, contains('Lighter by 12'));
      expect(spoken, contains('Less saturated by 9'));
      expect(spoken, contains('Hue shifted 18 degrees toward yellow'));
    });

    test('appends the confusion warning only when the pair is confusable '
        '(AC-7/AC-9)', () {
      const confusable = ComparisonState(comparison: _comparison, confusable: true);
      const distinct = ComparisonState(comparison: _comparison, confusable: false);

      // Confusable ⇒ the canonical warning is spoken as part of the utterance...
      expect(comparisonSpeech(confusable), contains(confusionWarningMessage));
      // ...and a distinct pair's spoken comparison carries no warning (rejects a
      // builder that always appends it).
      expect(comparisonSpeech(distinct), isNot(contains('identical')));
      // The relational statement is spoken either way.
      expect(comparisonSpeech(distinct), contains('Hue shifted 18 degrees '
          'toward yellow'));
    });
  });
}
