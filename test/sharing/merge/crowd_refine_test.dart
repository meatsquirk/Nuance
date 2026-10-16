import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/merge/crowd_refine.dart';

EvidencePoint _peerAt(ColorCoordinates lab, {String source = 'peer'}) =>
    EvidencePoint(
      coordinates: lab,
      source: source,
      kind: EvidenceKind.peerContributed,
    );

double _dist(ColorCoordinates x, ColorCoordinates y) {
  final dl = x.lightness - y.lightness;
  final da = x.a - y.a;
  final db = x.b - y.b;
  return math.sqrt(dl * dl + da * da + db * db);
}

void main() {
  group('RefineResult', () {
    const value = ColorCoordinates(lightness: 50, a: 10, b: -5);

    test('carries its value and tier', () {
      final result =
          RefineResult(value: value, tier: ProvenanceTier.estimated);
      expect(result.value, value);
      expect(result.tier, ProvenanceTier.estimated);
    });

    test('is value-equal and hashes by value and tier', () {
      final a = RefineResult(value: value, tier: ProvenanceTier.estimated);
      final sameAsA =
          RefineResult(value: value, tier: ProvenanceTier.estimated);
      final tierChanged =
          RefineResult(value: value, tier: ProvenanceTier.confirmed);
      final valueChanged = RefineResult(
        value: const ColorCoordinates(lightness: 1, a: 1, b: 1),
        tier: ProvenanceTier.estimated,
      );
      expect(a, sameAsA);
      expect(a.hashCode, sameAsA.hashCode);
      expect(a, isNot(tierChanged));
      expect(a, isNot(valueChanged));
      expect(a, isNot('not a RefineResult'));
    });

    test('toString names its value and tier', () {
      final result =
          RefineResult(value: value, tier: ProvenanceTier.estimated);
      expect(result.toString(), startsWith('RefineResult('));
      expect(result.toString(), contains('estimated'));
    });
  });

  group('CrowdRefine — robust central estimate (AC-8/AC-11)', () {
    const current = ColorCoordinates(lightness: 55, a: 4, b: 7);
    const refine = CrowdRefine();

    test('with no peer-contributed evidence the stored value stands', () {
      // An empty log, and a log whose only point is a non-peer origin, both
      // leave the stored value untouched — there is no crowd to refine from.
      final empty = refine.refine(current, const <EvidencePoint>[]);
      expect(empty.value, current);

      final seedOnly = refine.refine(current, const <EvidencePoint>[
        EvidencePoint(
          coordinates: ColorCoordinates(lightness: 1, a: 2, b: 3),
          source: 'llm',
          kind: EvidenceKind.llmSeed,
        ),
      ]);
      expect(seedOnly.value, current,
          reason: 'only peer-contributed evidence feeds the estimate');
    });

    test('empty evidence keeps the explicit fallback tier', () {
      final result = refine.refine(
        current,
        const <EvidencePoint>[],
        fallback: ProvenanceTier.calculated,
      );
      expect(result.tier, ProvenanceTier.calculated);
    });

    test('peer-contributed evidence never promotes the tier (stays estimated)',
        () {
      final result = refine.refine(current, <EvidencePoint>[
        _peerAt(const ColorCoordinates(lightness: 42, a: 3, b: -2)),
      ]);
      expect(result.tier, ProvenanceTier.estimated);
      expect(refine.derivation, isNotNull);
    });

    test('a single peer record becomes the value', () {
      const lab = ColorCoordinates(lightness: 42, a: 3, b: -2);
      final result = refine.refine(current, <EvidencePoint>[_peerAt(lab)]);
      expect(result.value, lab);
    });

    test('two peer records average (too few to single out an outlier)', () {
      const p1 = ColorCoordinates(lightness: 40, a: 2, b: -4);
      const p2 = ColorCoordinates(lightness: 50, a: 6, b: 0);
      final result =
          refine.refine(current, <EvidencePoint>[_peerAt(p1), _peerAt(p2)]);
      expect(result.value.lightness, closeTo(45, 1e-9));
      expect(result.value.a, closeTo(4, 1e-9));
      expect(result.value.b, closeTo(-2, 1e-9));
    });

    test('a small odd cluster with no outlier means all its points', () {
      // Three near points, none an outlier: every one survives, so the estimate
      // is their plain mean (exercises the odd-count median path).
      const a = ColorCoordinates(lightness: 49, a: -1, b: 1);
      const b = ColorCoordinates(lightness: 50, a: 0, b: 0);
      const c = ColorCoordinates(lightness: 51, a: 1, b: -1);
      final result = refine
          .refine(current, <EvidencePoint>[_peerAt(a), _peerAt(b), _peerAt(c)]);
      expect(result.value.lightness, closeTo(50, 1e-9));
      expect(result.value.a, closeTo(0, 1e-9));
      expect(result.value.b, closeTo(0, 1e-9));
    });

    test('identical records collapse to that value (zero spread, MAD 0)', () {
      const lab = ColorCoordinates(lightness: 60, a: 2, b: 6);
      final result = refine.refine(current, <EvidencePoint>[
        _peerAt(lab),
        _peerAt(lab),
        _peerAt(lab),
        _peerAt(lab),
      ]);
      expect(result.value, lab);
    });

    test(
        'a far statistical outlier is discarded, not averaged into the estimate',
        () {
      // Seven records symmetric about the centre + one far outlier (an even
      // count, exercising the even-count median path). The robust estimate must
      // land on the cluster centroid, far from the plain mean of all eight.
      const ColorCoordinates centre =
          ColorCoordinates(lightness: 50, a: 0, b: 0);
      final List<EvidencePoint> evidence = <EvidencePoint>[];
      for (var i = 0; i < 7; i++) {
        final double o = (i - 3) * 0.4;
        evidence.add(_peerAt(ColorCoordinates(
          lightness: centre.lightness + o,
          a: centre.a + o * 0.5,
          b: centre.b - o * 0.5,
        )));
      }
      const ColorCoordinates outlier =
          ColorCoordinates(lightness: 10, a: 30, b: -30);
      evidence.add(_peerAt(outlier));

      // The plain mean of all eight is pulled well off the cluster by the
      // outlier — the discriminator between "discard it" and "average it in".
      const ColorCoordinates plainMeanOfAll =
          ColorCoordinates(lightness: 45, a: 3.75, b: -3.75);

      final result = refine.refine(current, evidence);

      // Lands on the cluster centroid (the 7 symmetric points centre on
      // `centre`), outlier discarded.
      expect(result.value.lightness, closeTo(centre.lightness, 1e-9));
      expect(result.value.a, closeTo(centre.a, 1e-9));
      expect(result.value.b, closeTo(centre.b, 1e-9));
      // And it is NOT the plain mean of everything (the outlier was not
      // averaged in) and NOT the stale stored value (the crowd was not ignored).
      expect(_dist(result.value, plainMeanOfAll), greaterThan(1.5));
      expect(_dist(result.value, current), greaterThan(1.5));
    });
  });
}
