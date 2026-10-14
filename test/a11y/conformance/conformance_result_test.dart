import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// A result with every rule passing — the fully-conformant reference GATE-3
/// grades `accepted` against.
ConformanceResult _allPass() => ConformanceResult({
  for (final id in ConformanceRuleId.values) id: const ConformanceRuleOutcome.ok(),
});

/// Builds a [ConformanceRuleOutcome] at runtime (parameters are not
/// compile-time constants), so the default constructor registers line coverage.
ConformanceRuleOutcome _runtimeOutcome(bool pass, String detail) =>
    ConformanceRuleOutcome(pass: pass, detail: detail);

void main() {
  group('ConformanceRuleOutcome', () {
    test('ok() is a passing outcome with empty detail', () {
      const o = ConformanceRuleOutcome.ok();
      expect(o.pass, isTrue);
      expect(o.detail, isEmpty);
    });

    test('fail() carries the detail and does not pass', () {
      const o = ConformanceRuleOutcome.fail('swatch has no label');
      expect(o.pass, isFalse);
      expect(o.detail, 'swatch has no label');
    });

    test('default constructor keeps the given pass and default detail', () {
      const o = ConformanceRuleOutcome(pass: true);
      expect(o.pass, isTrue);
      expect(o.detail, isEmpty);
    });

    test('const constructors are invocable at runtime', () {
      // The three constructors are const, so the tests above invoke them only
      // in const contexts — folded at compile time, they never register line
      // coverage (the coverage artifact earlier phases carried as a re-run
      // flake). Exercise each once at runtime (non-const args / an explicit
      // runtime call) so the lines are genuinely covered. A11Y-2 closes this.
      final def = _runtimeOutcome(true, 'x'); // default ctor, runtime args
      final fail =
          ConformanceRuleOutcome.fail(def.detail); // .fail with a runtime arg
      // .ok() takes no args, so it is always const-eligible; call it at runtime
      // explicitly for coverage.
      // ignore: prefer_const_constructors
      final ok = ConformanceRuleOutcome.ok();
      expect(def, const ConformanceRuleOutcome(pass: true, detail: 'x'));
      expect(fail.pass, isFalse);
      expect(fail.detail, 'x');
      expect(ok.pass, isTrue);
      expect(ok.detail, isEmpty);
    });

    test('value equality by pass + detail', () {
      expect(
        const ConformanceRuleOutcome(pass: true, detail: 'x'),
        const ConformanceRuleOutcome(pass: true, detail: 'x'),
      );
      expect(
        const ConformanceRuleOutcome(pass: true, detail: 'x').hashCode,
        const ConformanceRuleOutcome(pass: true, detail: 'x').hashCode,
      );
      expect(
        const ConformanceRuleOutcome(pass: true, detail: 'x'),
        isNot(const ConformanceRuleOutcome(pass: false, detail: 'x')),
      );
      expect(
        const ConformanceRuleOutcome(pass: true, detail: 'x'),
        isNot(const ConformanceRuleOutcome(pass: true, detail: 'y')),
      );
      expect(
        // ignore: unrelated_type_equality_checks
        const ConformanceRuleOutcome.ok() == Object(),
        isFalse,
      );
    });

    test('toString names the verdict and detail', () {
      expect(
        const ConformanceRuleOutcome.fail('bad').toString(),
        'ConformanceRuleOutcome(fail, "bad")',
      );
      expect(
        const ConformanceRuleOutcome.ok().toString(),
        'ConformanceRuleOutcome(pass, "")',
      );
    });
  });

  group('ConformanceResult', () {
    test('empty() has no outcomes and is not passed', () {
      const r = ConformanceResult.empty();
      expect(r.passed, isFalse);
      for (final id in ConformanceRuleId.values) {
        expect(r.outcomeFor(id), isNull);
      }
      expect(r.failing, isEmpty);
      // `.empty()` takes no arguments, so every use above is const-folded and
      // its body line never registers coverage — the carried const-constructor
      // flake that A11Y-2 closed for the ConformanceRuleOutcome ctors and that
      // turned deterministic here for this ctor (line 108). Invoke it once at
      // runtime so the line is genuinely covered.
      // ignore: prefer_const_constructors
      final runtimeEmpty = ConformanceResult.empty();
      expect(runtimeEmpty.passed, isFalse);
      expect(runtimeEmpty, const ConformanceResult.empty());
    });

    test('passed is true iff every rule is present and passes', () {
      expect(_allPass().passed, isTrue);
    });

    test('a missing rule means not passed', () {
      final partial = ConformanceResult({
        for (final id in ConformanceRuleId.values)
          if (id != ConformanceRuleId.contrastAA)
            id: const ConformanceRuleOutcome.ok(),
      });
      expect(partial.passed, isFalse);
      expect(partial.failing, isEmpty); // absent != failing
      expect(partial.outcomeFor(ConformanceRuleId.contrastAA), isNull);
    });

    test('a failing rule means not passed and is reported by failing', () {
      final r = ConformanceResult({
        for (final id in ConformanceRuleId.values) id: const ConformanceRuleOutcome.ok(),
        ConformanceRuleId.tapTarget48: const ConformanceRuleOutcome.fail('28dp'),
      });
      expect(r.passed, isFalse);
      expect(r.failing, [ConformanceRuleId.tapTarget48]);
      expect(r.outcomeFor(ConformanceRuleId.tapTarget48)!.detail, '28dp');
    });

    test('the backing map is unmodifiable', () {
      final source = {
        ConformanceRuleId.colourCue: const ConformanceRuleOutcome.ok(),
      };
      final r = ConformanceResult(source);
      // Mutating the source after construction does not affect the result.
      source[ConformanceRuleId.noBareDot] = const ConformanceRuleOutcome.ok();
      expect(r.outcomeFor(ConformanceRuleId.noBareDot), isNull);
    });

    test('value equality by content, order-independent', () {
      expect(_allPass(), _allPass());
      expect(_allPass().hashCode, _allPass().hashCode);
      expect(const ConformanceResult.empty(), const ConformanceResult.empty());
    });

    test('differs when an outcome differs or the length differs', () {
      final failTap = ConformanceResult({
        for (final id in ConformanceRuleId.values) id: const ConformanceRuleOutcome.ok(),
        ConformanceRuleId.tapTarget48: const ConformanceRuleOutcome.fail('28dp'),
      });
      expect(_allPass(), isNot(failTap));
      expect(_allPass(), isNot(const ConformanceResult.empty()));
      // Same keys, same length, one differing value already covered above;
      // here a different length.
      expect(
        ConformanceResult({
          ConformanceRuleId.colourCue: const ConformanceRuleOutcome.ok(),
        }),
        isNot(const ConformanceResult.empty()),
      );
      // ignore: unrelated_type_equality_checks
      expect(const ConformanceResult.empty() == Object(), isFalse);
    });

    test('toString includes the outcomes', () {
      expect(const ConformanceResult.empty().toString(), 'ConformanceResult({})');
    });
  });
}
