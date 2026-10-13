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

  group('GATE-1 stubs', () {
    // The verdicts are implemented in GATE-3 / GATE-4; until then they throw,
    // so the frozen signatures compile while the behaviour is still pending.
    test('acceptanceDecision throws UnimplementedError', () {
      expect(
        () => acceptanceDecision(const ConformanceResult.empty()),
        throwsUnimplementedError,
      );
    });

    test('recordedLevel throws UnimplementedError', () {
      expect(
        () => recordedLevel(const ConformanceResult.empty()),
        throwsUnimplementedError,
      );
    });
  });
}
