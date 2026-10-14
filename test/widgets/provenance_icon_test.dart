import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/cvd/daltonize.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_scope.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/widgets/provenance_icon.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

Icon _icon(WidgetTester tester) =>
    tester.widget<Icon>(find.byType(Icon));

void main() {
  group('iconFor / tintFor', () {
    test('every tier maps to a distinct glyph (shape, not colour)', () {
      final glyphs = ProvenanceTier.values.map(ProvenanceIcon.iconFor).toSet();
      expect(glyphs, hasLength(ProvenanceTier.values.length),
          reason: 'each tier reads from its own shape');
    });

    test('every tier maps to a distinct base tint', () {
      final tints = ProvenanceTier.values.map(ProvenanceIcon.tintFor).toSet();
      expect(tints, hasLength(ProvenanceTier.values.length));
    });
  });

  testWidgets('standalone: renders the tier glyph at the identity tint',
      (tester) async {
    for (final tier in ProvenanceTier.values) {
      await _pump(tester, ProvenanceIcon(tier: tier));
      final icon = _icon(tester);
      expect(icon.icon, ProvenanceIcon.iconFor(tier));
      // No DisplayScope / AppScope above it: display views are off, so the tint
      // is the identity of the base tint (the fallback profile never alters it).
      expect(icon.color, ProvenanceIcon.tintFor(tier));
    }
  });

  testWidgets('with daltonization on (no AppScope): tint remapped for the '
      'fallback deutan profile', (tester) async {
    final controller = DisplayController()..setDaltonization(true);
    addTearDown(controller.dispose);
    await _pump(
      tester,
      DisplayScope(
        controller: controller,
        child: const ProvenanceIcon(tier: ProvenanceTier.measured),
      ),
    );
    final base = ProvenanceIcon.tintFor(ProvenanceTier.measured);
    final icon = _icon(tester);
    expect(icon.icon, ProvenanceIcon.iconFor(ProvenanceTier.measured),
        reason: 'the glyph is unchanged by the remap');
    expect(icon.color,
        daltonizeColor(base, const CvdProfile(type: CvdType.deutan)),
        reason: 'the tint is remapped through the chokepoint for the fallback '
            'deutan profile');
    expect(icon.color, isNot(base), reason: 'the remap moved the tint');
  });

  testWidgets('with daltonization on and an AppScope profile: tint remapped for '
      'the stored profile', (tester) async {
    final controller = DisplayController()..setDaltonization(true);
    addTearDown(controller.dispose);
    const protan = CvdProfile(type: CvdType.protan, severity: 0.8);
    await _pump(
      tester,
      AppScope(
        dependencies: const AppDependencies(
          colorScience: ColorScienceImpl(),
          speech: NoopSpeech(),
          haptics: NoopHaptics(),
          cvdProfile: protan,
        ),
        child: DisplayScope(
          controller: controller,
          child: const ProvenanceIcon(tier: ProvenanceTier.confirmed),
        ),
      ),
    );
    final base = ProvenanceIcon.tintFor(ProvenanceTier.confirmed);
    final icon = _icon(tester);
    expect(icon.color, daltonizeColor(base, protan),
        reason: 'the tint uses the AppScope profile, not the deutan fallback');
  });
}
