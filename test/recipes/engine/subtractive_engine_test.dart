import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';

const _white = Paint(
  id: 'tw',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);
const _target = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -8.65, b: 26.63),
  provenance: Provenance(ProvenanceTier.measured),
);

void main() {
  const engine = SubtractiveMixingEngine();

  test('is a MixingEngine and const-canonicalises', () {
    expect(engine, isA<MixingEngine>());
    expect(identical(engine, const SubtractiveMixingEngine()), isTrue);
  });

  group('shell stubs (ENGINE-1 — no behaviour yet)', () {
    test('forward throws UnimplementedError (wet)', () {
      expect(
        () => engine.forward({_white: 1.0}),
        throwsUnimplementedError,
      );
    });

    test('forward throws UnimplementedError (dry)', () {
      expect(
        () => engine.forward({_white: 1.0}, dry: true),
        throwsUnimplementedError,
      );
    });

    test('inverse returns no recipes', () {
      const palette = PaintPalette(name: 'My paints', paints: [_white]);
      expect(engine.inverse(_target, palette, const MixOptions()), isEmpty);
    });
  });
}
