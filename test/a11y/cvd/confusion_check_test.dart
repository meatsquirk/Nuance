import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/compare/difference.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  group('NoopConfusionCheck', () {
    // Constructed at runtime (not `const`) so the inert default's constructor is
    // actually exercised now that every production use of it is compile-time.
    final check = NoopConfusionCheck();
    const profile = CvdProfile(type: CvdType.deutan);

    test('is a ConfusionCheck', () {
      expect(check, isA<ConfusionCheck>());
    });

    test('never flags a pair as confusable (inert)', () {
      const a = ColorCoordinates(lightness: 58, a: 24, b: 30);
      const b = ColorCoordinates(lightness: 70, a: 12, b: 24);
      expect(check.confusable(a, b, profile), isFalse);
      // Even identical coordinates are not flagged by the inert default.
      expect(check.confusable(a, a, profile), isFalse);
    });
  });

  group('confusionWarningMessage', () {
    test('states look-identical-to-you but different-to-others (AC-7)', () {
      expect(confusionWarningMessage, contains('identical'));
      expect(confusionWarningMessage, contains('different'));
    });
  });

  group('DichromatConfusionCheck', () {
    const check = DichromatConfusionCheck();
    const deutan = CvdProfile(type: CvdType.deutan);

    // The bs-03 deutan confusion pair (same L, opposite a*, near-equal b*):
    // clearly different to normal vision, collapsed under the deutan projection.
    const umber = ColorCoordinates(lightness: 40, a: 18, b: 16);
    const terre = ColorCoordinates(lightness: 40, a: -10, b: 18);
    // The off-line control: terracotta vs sienna, distinct to a deuteranope.
    const terracotta = ColorCoordinates(lightness: 58, a: 25.27, b: 22.75);
    const sienna = ColorCoordinates(lightness: 70, a: 12.5, b: 21.65);

    test('is a ConfusionCheck', () {
      expect(check, isA<ConfusionCheck>());
    });

    test('flags a deutan confusion-line pair (AC-7)', () {
      // Both conditions hold: clearly different normally, collapsed projected.
      expect(deltaE00(umber, terre), greaterThan(10),
          reason: 'the pair is clearly different to normal vision');
      expect(
        deltaE00(
          projectDichromat(umber, deutan),
          projectDichromat(terre, deutan),
        ),
        lessThan(3),
        reason: 'a deuteranope cannot tell them apart',
      );
      expect(check.confusable(umber, terre, deutan), isTrue);
    });

    test('does not flag an off-line pair that stays distinct projected (AC-8)',
        () {
      // Clearly different normally, but still distinct after the projection, so
      // the second condition fails — not confusable.
      expect(deltaE00(terracotta, sienna), greaterThan(10));
      expect(
        deltaE00(
          projectDichromat(terracotta, deutan),
          projectDichromat(sienna, deutan),
        ),
        greaterThan(3),
      );
      expect(check.confusable(terracotta, sienna, deutan), isFalse);
    });

    test('does not flag a pair that is not clearly different to normal vision',
        () {
      // Near-identical colours: the first condition (clear normal difference)
      // fails, so the detector returns before even projecting.
      const a = ColorCoordinates(lightness: 50, a: 10, b: 10);
      const b = ColorCoordinates(lightness: 50, a: 10.4, b: 10);
      expect(deltaE00(a, b), lessThan(10),
          reason: 'others can barely tell them apart either');
      expect(check.confusable(a, b, deutan), isFalse);
    });

    test('is symmetric in its two colours', () {
      expect(
        check.confusable(umber, terre, deutan),
        check.confusable(terre, umber, deutan),
      );
    });
  });

  group('projectDichromat', () {
    const umber = ColorCoordinates(lightness: 40, a: 18, b: 16);

    test('fixes the achromatic axis for every type (neutral grey unchanged)',
        () {
      const grey = ColorCoordinates(lightness: 40, a: 0, b: 0);
      for (final type in CvdType.values) {
        final p = projectDichromat(grey, CvdProfile(type: type));
        expect(p.lightness, closeTo(40, 0.5), reason: '$type keeps L');
        expect(p.a, closeTo(0, 0.5), reason: '$type keeps a*');
        expect(p.b, closeTo(0, 0.5), reason: '$type keeps b*');
      }
    });

    test('is idempotent — projecting a projected colour changes nothing more',
        () {
      // A projection onto a plane: applying it twice equals applying it once.
      for (final type in CvdType.values) {
        final once = projectDichromat(umber, CvdProfile(type: type));
        final twice = projectDichromat(once, CvdProfile(type: type));
        expect(twice.lightness, closeTo(once.lightness, 1e-6));
        expect(twice.a, closeTo(once.a, 1e-6));
        expect(twice.b, closeTo(once.b, 1e-6));
      }
    });

    test('each type collapses a chromatic colour differently', () {
      // The three planes are distinct, so a red-leaning colour lands at three
      // different places (exercises each _planeFor branch).
      final protan = projectDichromat(umber, const CvdProfile(type: CvdType.protan));
      final deutan = projectDichromat(umber, const CvdProfile(type: CvdType.deutan));
      final tritan = projectDichromat(umber, const CvdProfile(type: CvdType.tritan));
      expect(protan.a, isNot(closeTo(deutan.a, 0.5)));
      expect(deutan.a, isNot(closeTo(tritan.a, 0.5)));
    });

    test('severity 0 leaves the colour unchanged; 1 fully projects it', () {
      const none = CvdProfile(type: CvdType.deutan, severity: 0);
      final unaffected = projectDichromat(umber, none);
      expect(unaffected.lightness, closeTo(umber.lightness, 1e-6));
      expect(unaffected.a, closeTo(umber.a, 1e-6));
      expect(unaffected.b, closeTo(umber.b, 1e-6));

      // Full severity moves a chromatic colour (the red↔green a* collapses).
      final full = projectDichromat(umber, const CvdProfile(type: CvdType.deutan));
      expect(full.a, isNot(closeTo(umber.a, 1)));
    });

    test('a partial severity lands between no projection and full', () {
      const half = CvdProfile(type: CvdType.deutan, severity: 0.5);
      final partial = projectDichromat(umber, half);
      final full = projectDichromat(umber, const CvdProfile(type: CvdType.deutan));
      // Between the original a* (18) and the fully-projected a*.
      final lo = full.a < umber.a ? full.a : umber.a;
      final hi = full.a < umber.a ? umber.a : full.a;
      expect(partial.a, greaterThan(lo));
      expect(partial.a, lessThan(hi));
    });
  });
}
