// bs-13 guard smoke test — proves the guard harness compiles, is importable,
// and (since GUARD-2) that the three integrity guards enforce their real rule:
// zero offenders over the shipped `lib/` + seed schema, and the planted control
// listed. The full AC-1/AC-3/AC-4 acceptance assertions live in the bs-13
// integration suite; this mirrors them at the unit grain and exercises both
// guard branches (the shipped pass and the control) in the host `flutter test`
// run.
//
// Runs on the host VM (`flutter test`), where the cwd is the repo root, so the
// `dart:io` source scans can read `lib/` and the planted control fixtures.

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/bs13/guards/no_claimed_value_guard.dart';
import '../../integration_test/bs13/guards/no_lookup_table_guard.dart';
import '../../integration_test/bs13/guards/ratio_provenance_guard.dart';
import '../../integration_test/bs13/guards/source_scan.dart';

/// The planted control source files (repo-relative), mirrored from the bs-13
/// harness so this host unit test needs no `package:flutter`-heavy import.
const _controlLlmRatio = <String>[
  'integration_test/bs13/guards/fixtures/control_llm_ratio.dart',
];
const _controlLookupTable = <String>[
  'integration_test/bs13/guards/fixtures/control_lookup_table.dart',
];
const _controlClaimedSpectral = <String>[
  'integration_test/bs13/guards/fixtures/control_claimed_spectral.dart',
];

void main() {
  group('the integrity guards pass over the shipped code and flag the control', () {
    test('ratioProvenanceGuard: clean over lib/, flags the planted llm ratio', () {
      expect(ratioProvenanceGuard(), isEmpty,
          reason: 'only the solver (and the project reload authority) produces '
              'a ratio, and the seed schema carries none');
      final control = ratioProvenanceGuard(
        roots: _controlLlmRatio,
        schemaFiles: _controlLlmRatio,
      );
      expect(control, isNotEmpty);
      expect(control.any((o) => (o.path ?? '').endsWith('control_llm_ratio.dart')),
          isTrue);
    });

    test('noLookupTableGuard: clean over the seed schema, flags the planted table', () {
      expect(noLookupTableGuard(), isEmpty,
          reason: 'the seed carries no target→recipe answer mapping');
      final control = noLookupTableGuard(schemaFiles: _controlLookupTable);
      expect(control, isNotEmpty);
      expect(
          control.any((o) => (o.path ?? '').endsWith('control_lookup_table.dart')),
          isTrue);
    });

    test('noClaimedValueGuard: clean over the seed schema, flags the planted field', () {
      expect(noClaimedValueGuard(), isEmpty,
          reason: 'no stored seed entry carries a claimed spectral/ratio field');
      final control = noClaimedValueGuard(schemaFiles: _controlClaimedSpectral);
      expect(control, isNotEmpty);
      expect(
          control.any((o) => (o.path ?? '').endsWith('control_claimed_spectral.dart')),
          isTrue);
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
