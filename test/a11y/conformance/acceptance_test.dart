import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/acceptance.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

void main() {
  group('AcceptanceDecision / WcagLevel enums', () {
    test('expose the expected values', () {
      expect(AcceptanceDecision.values, [
        AcceptanceDecision.accepted,
        AcceptanceDecision.notAccepted,
      ]);
      expect(WcagLevel.values, [WcagLevel.below, WcagLevel.aa22]);
    });
  });

  group('acceptanceDecision (GATE-3, AC-9)', () {
    // A fully-passing result: every rule id present and passing.
    final fullyPassing = ConformanceResult({
      for (final id in ConformanceRuleId.values)
        id: const ConformanceRuleOutcome.ok(),
    });

    test('accepts a fully-passing result', () {
      expect(fullyPassing.passed, isTrue);
      expect(acceptanceDecision(fullyPassing), AcceptanceDecision.accepted);
    });

    test('does not accept a result with a failing rule', () {
      final partial = ConformanceResult({
        for (final id in ConformanceRuleId.values)
          id: const ConformanceRuleOutcome.ok(),
        // One rule fails ⇒ the whole result is not accepted.
        ConformanceRuleId.tapTarget48:
            const ConformanceRuleOutcome.fail('24dp target'),
      });
      expect(partial.passed, isFalse);
      expect(acceptanceDecision(partial), AcceptanceDecision.notAccepted);
    });

    test('does not accept a partial result (not every rule ran)', () {
      // A result missing an id is not `passed`, so it is not accepted — the
      // gate never accepts an incomplete run.
      final incomplete = ConformanceResult({
        ConformanceRuleId.contrastAA: const ConformanceRuleOutcome.ok(),
      });
      expect(incomplete.passed, isFalse);
      expect(acceptanceDecision(incomplete), AcceptanceDecision.notAccepted);
    });

    test('does not accept the empty result', () {
      expect(
        acceptanceDecision(const ConformanceResult.empty()),
        AcceptanceDecision.notAccepted,
      );
    });
  });

  group('recordedLevel (GATE-4, AC-11)', () {
    // A fully-passing result: every rule id present and passing.
    final fullyPassing = ConformanceResult({
      for (final id in ConformanceRuleId.values)
        id: const ConformanceRuleOutcome.ok(),
    });

    test('records WCAG 2.2 AA for a fully-passing result', () {
      expect(fullyPassing.passed, isTrue);
      expect(recordedLevel(fullyPassing), WcagLevel.aa22);
    });

    test('records below AA when a rule fails', () {
      final failing = ConformanceResult({
        for (final id in ConformanceRuleId.values)
          id: const ConformanceRuleOutcome.ok(),
        ConformanceRuleId.contrastAA:
            const ConformanceRuleOutcome.fail('3.1:1 text'),
      });
      expect(failing.passed, isFalse);
      expect(recordedLevel(failing), WcagLevel.below);
    });

    test('records below AA for a partial result (not every rule ran)', () {
      final incomplete = ConformanceResult({
        ConformanceRuleId.contrastAA: const ConformanceRuleOutcome.ok(),
      });
      expect(incomplete.passed, isFalse);
      expect(recordedLevel(incomplete), WcagLevel.below);
    });

    test('records below AA for the empty result', () {
      expect(recordedLevel(const ConformanceResult.empty()), WcagLevel.below);
    });
  });

  group('WcagThresholds (GATE-4, AC-11, D-5)', () {
    // The pinned WCAG 2.2 AA numeric floor the `aa22` level names. The AC-11
    // acceptance test additionally pins Flutter's contrast/tap-target
    // guidelines (which the check rules delegate to) equal to these values;
    // here we fix the constants themselves so a silent edit cannot lower them.
    test('carry exactly the WCAG 2.2 AA values', () {
      expect(WcagThresholds.minTextContrastRatioNormalText, 4.5);
      expect(WcagThresholds.minTextContrastRatioLargeText, 3.0);
      expect(WcagThresholds.minTapTargetDip, 48.0);
      expect(WcagThresholds.minSupportedTextScale, 2.0);
    });
  });
}
