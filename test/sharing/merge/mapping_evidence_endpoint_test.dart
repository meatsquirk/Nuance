import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/merge/mapping_evidence_endpoint.dart';

const _value = ColorCoordinates(lightness: 50, a: 10, b: -5);

EvidencePoint _peer(String source) => EvidencePoint(
      coordinates: const ColorCoordinates(lightness: 42, a: 3, b: -2),
      source: source,
      kind: EvidenceKind.peerContributed,
    );

MappingEvidenceView _view({List<EvidencePoint>? evidence}) =>
    MappingEvidenceView(value: _value, evidence: evidence ?? [_peer('peer-1')]);

void main() {
  group('MappingEvidenceView', () {
    test('defaults to an Estimated, not-yet-verified empty view', () {
      final view = MappingEvidenceView(value: _value);
      expect(view.value, _value);
      expect(view.evidence, isEmpty);
      expect(view.tier, ProvenanceTier.estimated);
      expect(view.label, 'Estimated — not yet verified');
    });

    test('is value-equal and hashes by all fields', () {
      final a = _view();
      final sameAsA = _view();
      final evidenceChanged = _view(evidence: [_peer('peer-2')]);
      final tierChanged = MappingEvidenceView(
        value: _value,
        evidence: [_peer('peer-1')],
        tier: ProvenanceTier.confirmed,
      );
      final labelChanged = MappingEvidenceView(
        value: _value,
        evidence: [_peer('peer-1')],
        label: 'changed',
      );
      expect(a, sameAsA);
      expect(a.hashCode, sameAsA.hashCode);
      expect(a, isNot(evidenceChanged));
      expect(a, isNot(tierChanged));
      expect(a, isNot(labelChanged));
      expect(a, isNot('not a MappingEvidenceView'));
    });

    test('toString names the value, evidence count and label', () {
      final view = _view();
      expect(view.toString(), startsWith('MappingEvidenceView('));
      expect(view.toString(), contains('1 evidence'));
      expect(view.toString(), contains('Estimated'));
    });
  });

  group('MappingEvidenceEndpoint (shell)', () {
    testWidgets('is empty in the shell — no observed view', (tester) async {
      await tester.pumpWidget(
        const MappingEvidenceEndpoint(child: SizedBox()),
      );
      final seen = tester.widget<MappingEvidenceEndpoint>(
        find.byType(MappingEvidenceEndpoint),
      );
      expect(seen.view, isNull);
    });

    testWidgets('exposes the observed view to a descendant', (tester) async {
      final view = _view();
      await tester.pumpWidget(
        MappingEvidenceEndpoint(view: view, child: const SizedBox()),
      );
      final seen = tester.widget<MappingEvidenceEndpoint>(
        find.byType(MappingEvidenceEndpoint),
      );
      expect(seen.view, view);
    });

    testWidgets('of() returns the endpoint and maybeOf is null when absent',
        (tester) async {
      final seenOf = <MappingEvidenceEndpoint>[];
      final seenMaybe = <MappingEvidenceEndpoint?>[];
      await tester.pumpWidget(
        MappingEvidenceEndpoint(
          view: _view(),
          child: Builder(
            builder: (context) {
              seenOf.add(MappingEvidenceEndpoint.of(context));
              seenMaybe.add(MappingEvidenceEndpoint.maybeOf(context));
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seenMaybe.add(MappingEvidenceEndpoint.maybeOf(context));
            return const SizedBox();
          },
        ),
      );
      expect(seenOf.single.view, isNotNull);
      expect(seenMaybe[0], isNotNull);
      expect(seenMaybe[1], isNull);
    });

    testWidgets('is findable by its stable endpoint key', (tester) async {
      await tester.pumpWidget(
        const MappingEvidenceEndpoint(
          key: MappingEvidenceEndpoint.endpointKey,
          child: SizedBox(),
        ),
      );
      expect(find.byKey(MappingEvidenceEndpoint.endpointKey), findsOneWidget);
    });

    test('updateShouldNotify tracks the observed view', () {
      final a = MappingEvidenceEndpoint(view: _view(), child: const SizedBox());
      final sameAsA =
          MappingEvidenceEndpoint(view: _view(), child: const SizedBox());
      final changed = MappingEvidenceEndpoint(
        view: _view(evidence: [_peer('peer-2')]),
        child: const SizedBox(),
      );
      expect(a.updateShouldNotify(sameAsA), isFalse);
      expect(a.updateShouldNotify(changed), isTrue);
    });
  });
}
