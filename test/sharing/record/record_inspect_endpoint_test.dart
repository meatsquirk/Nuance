import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';
import 'package:paint_color_assistant/sharing/record/record_inspect_endpoint.dart';

MixAccuracyRecord _record(String id) => MixAccuracyRecord(
      paintCombination: PaintCombination.of([id]),
      declaredPalette: const DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil'),
      measuredColour: const MeasuredColour(
        lab: ColorCoordinates(lightness: 50, a: 10, b: -5),
        lch: CielchCoordinates(lightness: 50, chroma: 11.18, hue: 333.4),
      ),
      tier: MeasurementTier.instrument,
    );

void main() {
  testWidgets('is empty in the shell — no prepared record, empty share-set',
      (tester) async {
    await tester.pumpWidget(
      const RecordInspectEndpoint(child: SizedBox()),
    );
    final seen = tester.widget<RecordInspectEndpoint>(
      find.byType(RecordInspectEndpoint),
    );
    expect(seen.prepared, isNull);
    expect(seen.shareSet, isEmpty);
  });

  testWidgets('exposes the prepared record and share-set to a descendant',
      (tester) async {
    final prepared = _record('a');
    await tester.pumpWidget(
      RecordInspectEndpoint(
        prepared: prepared,
        shareSet: [prepared],
        child: const SizedBox(),
      ),
    );
    final seen = tester.widget<RecordInspectEndpoint>(
      find.byType(RecordInspectEndpoint),
    );
    expect(seen.prepared, prepared);
    expect(seen.shareSet, [prepared]);
  });

  testWidgets('of() returns the endpoint and maybeOf is null when absent',
      (tester) async {
    final seenOf = <RecordInspectEndpoint>[];
    final seenMaybe = <RecordInspectEndpoint?>[];
    await tester.pumpWidget(
      RecordInspectEndpoint(
        prepared: _record('a'),
        child: Builder(
          builder: (context) {
            seenOf.add(RecordInspectEndpoint.of(context));
            seenMaybe.add(RecordInspectEndpoint.maybeOf(context));
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seenMaybe.add(RecordInspectEndpoint.maybeOf(context));
          return const SizedBox();
        },
      ),
    );
    expect(seenOf.single.prepared, isNotNull);
    expect(seenMaybe[0], isNotNull);
    expect(seenMaybe[1], isNull);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      const RecordInspectEndpoint(
        key: RecordInspectEndpoint.endpointKey,
        child: SizedBox(),
      ),
    );
    expect(find.byKey(RecordInspectEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks the prepared record and the share-set', () {
    final a = RecordInspectEndpoint(
      prepared: _record('a'),
      shareSet: [_record('a')],
      child: const SizedBox(),
    );
    final sameAsA = RecordInspectEndpoint(
      prepared: _record('a'),
      shareSet: [_record('a')],
      child: const SizedBox(),
    );
    final preparedChanged = RecordInspectEndpoint(
      prepared: _record('b'),
      shareSet: [_record('a')],
      child: const SizedBox(),
    );
    final shareSetChanged = RecordInspectEndpoint(
      prepared: _record('a'),
      shareSet: [_record('a'), _record('b')],
      child: const SizedBox(),
    );
    expect(a.updateShouldNotify(sameAsA), isFalse);
    expect(a.updateShouldNotify(preparedChanged), isTrue);
    expect(a.updateShouldNotify(shareSetChanged), isTrue);
  });
}
