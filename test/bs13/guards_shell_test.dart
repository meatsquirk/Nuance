// GUARD-1 shell smoke test — proves the bs-13 guard harness compiles, is
// importable, and the shared scan machinery works. The real rule behaviour
// (and its control-discrimination tests) lands at GUARD-2 in the acceptance
// suite; this only guards the scaffold.
//
// Runs on the host VM (`flutter test`), where the cwd is the repo root, so the
// `dart:io` source scans can read `lib/`.

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/bs13/guards/no_claimed_value_guard.dart';
import '../../integration_test/bs13/guards/no_lookup_table_guard.dart';
import '../../integration_test/bs13/guards/ratio_provenance_guard.dart';
import '../../integration_test/bs13/guards/source_scan.dart';

void main() {
  group('GUARD-1 stubs report "not yet enforced"', () {
    test('ratioProvenanceGuard', () {
      final offenders = ratioProvenanceGuard();
      expect(offenders, hasLength(1));
      expect(offenders.single.rule, ruleNotYetEnforced);
      expect(offenders.single.detail, contains('ratioProvenanceGuard'));
    });

    test('noLookupTableGuard', () {
      final offenders = noLookupTableGuard();
      expect(offenders, hasLength(1));
      expect(offenders.single.rule, ruleNotYetEnforced);
      expect(offenders.single.detail, contains('noLookupTableGuard'));
    });

    test('noClaimedValueGuard', () {
      final offenders = noClaimedValueGuard();
      expect(offenders, hasLength(1));
      expect(offenders.single.rule, ruleNotYetEnforced);
      expect(offenders.single.detail, contains('noClaimedValueGuard'));
    });
  });

  group('maskCommentsAndStrings blanks comments and strings', () {
    test('a token inside a line comment is not matched', () {
      const src = 'final x = 1; // partsFraction here\n';
      final masked = maskCommentsAndStrings(src);
      expect(masked.contains('partsFraction'), isFalse);
      // Newlines preserved so line numbers are unchanged.
      expect('\n'.allMatches(masked).length, '\n'.allMatches(src).length);
    });

    test('a token inside a string literal is not matched', () {
      const src = "final s = 'partsFraction';\n";
      expect(maskCommentsAndStrings(src).contains('partsFraction'), isFalse);
    });
  });

  group('scanDartSources reads lib/ and locates real code', () {
    test('finds a known declaration in lib/, with a real path and line', () {
      final matches = scanDartSources(
        patterns: [RegExp(r'\bclass SubtractiveMixingEngine\b')],
      );
      expect(matches, isNotEmpty);
      final hit = matches.first;
      expect(hit.path, 'lib/recipes/engine/subtractive_engine.dart');
      expect(hit.line, greaterThan(0));
      expect(hit.snippet, contains('SubtractiveMixingEngine'));
    });

    test('isAllowed exempts a file whole', () {
      final matches = scanDartSources(
        patterns: [RegExp(r'\bclass SubtractiveMixingEngine\b')],
        isAllowed: (p) => p.endsWith('subtractive_engine.dart'),
      );
      expect(matches, isEmpty);
    });

    test('a missing root is skipped, not an error', () {
      final matches = scanDartSources(
        roots: const ['no_such_dir_xyz'],
        patterns: [RegExp('anything')],
      );
      expect(matches, isEmpty);
    });
  });

  group('scanSchema targets the SEED definition file', () {
    test('finds a type the schema declares', () {
      final matches =
          scanSchema(fieldPatterns: [RegExp(r'\bclass CandidateMapping\b')]);
      expect(matches, isNotEmpty);
      expect(matches.first.path, 'lib/dataset/seed_dataset.dart');
    });

    test('a field the schema does not declare yields no match', () {
      // The seed schema carries no ratio / spectral-curve field (AC-3 / AC-4);
      // the real forbidden-pattern set lands at GUARD-2.
      final matches = scanSchema(fieldPatterns: [
        RegExp(r'\b(?:partsFraction|spectralCurve|spectralReflectance)\b'),
      ]);
      expect(matches, isEmpty);
    });
  });
}
