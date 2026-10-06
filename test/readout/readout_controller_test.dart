import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';

const _coords = ColorCoordinates(lightness: 58, a: 36, b: 34);
const _provenance = Provenance(ProvenanceTier.measured);

ReadoutController _controllerFor(Sample sample, {AppRouter? router}) =>
    ReadoutController(
      sample: sample,
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: router ?? const AppRouter(),
    );

/// An [AppRouter] that records the arguments each navigation handoff is built
/// with, so the controller's route calls can be asserted without a widget tree.
class _RecordingRouter extends AppRouter {
  Sample? comparisonSample;
  ComparisonSlot? comparisonSlot;
  Sample? recipesTarget;
  Route<void>? lastRoute;

  @override
  Route<void> toComparison(Sample sample, ComparisonSlot slot) {
    comparisonSample = sample;
    comparisonSlot = slot;
    return lastRoute = super.toComparison(sample, slot);
  }

  @override
  Route<void> toRecipes(Sample target) {
    recipesTarget = target;
    return lastRoute = super.toRecipes(target);
  }
}

void main() {
  group('ReadoutController', () {
    test('holds the sample and the injected services', () {
      const sample = Sample(coordinates: _coords, provenance: _provenance);
      const colorScience = ColorScienceImpl();
      const speech = NoopSpeech();
      const haptics = NoopHaptics();
      const router = AppRouter();
      final controller = ReadoutController(
        sample: sample,
        colorScience: colorScience,
        speech: speech,
        haptics: haptics,
        router: router,
      );
      expect(controller.sample, same(sample));
      expect(controller.colorScience, same(colorScience));
      expect(controller.speech, same(speech));
      expect(controller.haptics, same(haptics));
      expect(controller.router, same(router));
    });

    test('starts on the CIELCh space', () {
      final controller = _controllerFor(
        const Sample(coordinates: _coords, provenance: _provenance),
      );
      expect(controller.selectedSpace, ReadoutSpace.cielch);
    });

    test('nameText uses the sample name when present', () {
      final controller = _controllerFor(
        const Sample(
          name: 'Warm Terracotta',
          coordinates: _coords,
          provenance: _provenance,
        ),
      );
      expect(controller.nameText, 'Warm Terracotta');
    });

    test('nameText derives the nearest colour name when the sample is unnamed',
        () {
      // No stored name → the name is the nearest ISCC-NBS colour to _coords
      // (L58, a36, b34), which is "Warm Terracotta" (AC-3).
      final controller = _controllerFor(
        const Sample(coordinates: _coords, provenance: _provenance),
      );
      expect(controller.nameText, 'Warm Terracotta');
    });

    test('justCaptured reflects the sample', () {
      final fresh = _controllerFor(
        const Sample(
          coordinates: _coords,
          provenance: _provenance,
          justCaptured: true,
        ),
      );
      final old = _controllerFor(
        const Sample(coordinates: _coords, provenance: _provenance),
      );
      expect(fresh.justCaptured, isTrue);
      expect(old.justCaptured, isFalse);
    });

    test('selectSpace changes the space and notifies', () {
      final controller = _controllerFor(
        const Sample(coordinates: _coords, provenance: _provenance),
      );
      var notified = 0;
      controller.addListener(() => notified++);
      controller.selectSpace(ReadoutSpace.munsell);
      expect(controller.selectedSpace, ReadoutSpace.munsell);
      expect(notified, 1);
    });

    test('selectSpace to the current space is a no-op', () {
      final controller = _controllerFor(
        const Sample(coordinates: _coords, provenance: _provenance),
      );
      var notified = 0;
      controller.addListener(() => notified++);
      controller.selectSpace(ReadoutSpace.cielch);
      expect(controller.selectedSpace, ReadoutSpace.cielch);
      expect(notified, 0);
    });

    test('acknowledge clears the just-captured marker and notifies', () {
      final controller = _controllerFor(
        const Sample(
          coordinates: _coords,
          provenance: _provenance,
          justCaptured: true,
        ),
      );
      var notified = 0;
      controller.addListener(() => notified++);
      controller.acknowledge();
      expect(controller.justCaptured, isFalse);
      expect(notified, 1);
    });

    test('acknowledge on an already-acknowledged reading is a no-op', () {
      final controller = _controllerFor(
        const Sample(coordinates: _coords, provenance: _provenance),
      );
      var notified = 0;
      controller.addListener(() => notified++);
      controller.acknowledge();
      expect(controller.justCaptured, isFalse);
      expect(notified, 0);
    });
  });

  group('ReadoutController value readings (AC-1, AC-2)', () {
    ReadoutController controllerAtLightness(double l) => _controllerFor(
          Sample(
            coordinates: ColorCoordinates(lightness: l, a: 25.27, b: 22.75),
            provenance: _provenance,
          ),
        );

    test('lightness is the sample CIELAB L*', () {
      expect(controllerAtLightness(58).lightness, 58);
    });

    test('valueWord tracks the lightness (low / middle / high)', () {
      // The word is derived from the lightness, not a constant (AC-2 control).
      expect(controllerAtLightness(58).valueWord, 'middle value');
      expect(controllerAtLightness(15).valueWord, 'very low value');
      expect(controllerAtLightness(90).valueWord, 'very high value');
    });

    test('munsell exposes the sample Munsell notation (value 5.5 at L58)', () {
      final munsell = controllerAtLightness(58).munsell;
      expect(munsell.value, 5.5);
      expect(munsell.hue, '10R');
    });

    test('grayscale is a neutral (equal RGB channels) preview', () {
      final gray = controllerAtLightness(58).grayscale;
      expect(gray.red, gray.green);
      expect(gray.green, gray.blue);
    });

    test('load replaces the sample and the derived readings, and notifies', () {
      final controller = controllerAtLightness(58);
      expect(controller.valueWord, 'middle value');
      var notified = 0;
      controller.addListener(() => notified++);

      controller.load(
        const Sample(
          coordinates: ColorCoordinates(lightness: 15, a: 25.27, b: 22.75),
          provenance: _provenance,
        ),
      );

      expect(controller.lightness, 15);
      expect(controller.valueWord, 'very low value');
      expect(notified, 1);
    });

    test('load of the same sample instance is a no-op', () {
      const sample = Sample(
        coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
        provenance: _provenance,
      );
      final controller = _controllerFor(sample);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.load(sample);

      expect(controller.sample, same(sample));
      expect(notified, 0);
    });
  });

  group('ReadoutController colour-space readout (AC-5)', () {
    // Warm Terracotta — the AC-5 fixture (L58, a25.27, b22.75).
    ReadoutController terracotta() => _controllerFor(
          const Sample(
            coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
            provenance: _provenance,
          ),
        );

    test('CIELCh formats L, C and rounded hue in degrees', () {
      expect(
        terracotta().readoutForSpace(ReadoutSpace.cielch),
        'L 58, C 34, h 42°',
      );
    });

    test('Munsell formats the notation, dropping a redundant .0 chroma', () {
      // value 5.5 keeps its fraction; chroma 6.0 renders as "6" (the familiar
      // "10R 5.5/6" the spec shows), not "6.0".
      expect(
        terracotta().readoutForSpace(ReadoutSpace.munsell),
        '10R 5.5/6',
      );
    });

    test('sRGB formats the 8-bit triplet and the hex value', () {
      expect(
        terracotta().readoutForSpace(ReadoutSpace.srgb),
        '192, 122, 101  #c07a65',
      );
    });

    test('CIELAB formats the canonical L, a, b coordinates', () {
      expect(
        terracotta().readoutForSpace(ReadoutSpace.cielab),
        'L 58, a 25.27, b 22.75',
      );
    });

    test('spaceReadout tracks the selected space (one at a time)', () {
      final controller = terracotta();
      // Defaults to CIELCh; selecting another space replaces the reading, so
      // the previous space is no longer shown.
      expect(controller.spaceReadout, 'L 58, C 34, h 42°');
      controller.selectSpace(ReadoutSpace.srgb);
      expect(controller.spaceReadout, '192, 122, 101  #c07a65');
      expect(controller.spaceReadout, isNot(contains('°')));
    });

    test('spaceReadout tracks a reloaded sample', () {
      final controller = terracotta();
      controller.load(
        const Sample(
          coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
          provenance: _provenance,
        ),
      );
      // The CIELAB readout now reflects the olive sample's own coordinates.
      expect(
        controller.readoutForSpace(ReadoutSpace.cielab),
        'L 40, a -8.00, b 24.00',
      );
    });
  });

  group('ReadoutController temperature word (AC-4)', () {
    ReadoutController controllerAt(double a, double b) => _controllerFor(
          Sample(
            coordinates: ColorCoordinates(lightness: 55, a: a, b: b),
            provenance: _provenance,
          ),
        );

    test('a warm sample (hue ~42°) reads "warm"', () {
      // The terracotta a*/b* — hue ≈ 42°, within 60° of the warm pole.
      expect(controllerAt(25.27, 22.75).temperatureWord, 'warm');
    });

    test('a cool sample (hue ~250°) reads "cool" — the SAMPLE_COOL control', () {
      // The cool-fixture a*/b* — hue ≈ 250°, within 60° of the cool pole; the
      // temperature word is derived from the hue, never "always warm".
      expect(controllerAt(-11.63, -31.95).temperatureWord, 'cool');
    });

    test('a transitional sample (hue ~150°) reads "neutral"', () {
      // Hue ≈ 150° (a green transition) — equidistant enough from both poles to
      // read "neutral", the axis temperature is stated relative to.
      expect(controllerAt(-17.32, 10).temperatureWord, 'neutral');
    });
  });

  group('navigation handoffs', () {
    const sample = Sample(
      name: 'Warm Terracotta',
      coordinates: _coords,
      provenance: _provenance,
    );

    test('comparisonRoute(a) carries this sample into slot A (AC-9)', () {
      final router = _RecordingRouter();
      final controller = _controllerFor(sample, router: router);
      final route = controller.comparisonRoute(ComparisonSlot.a);
      expect(router.comparisonSample, same(controller.sample));
      expect(router.comparisonSlot, ComparisonSlot.a);
      expect(route, same(router.lastRoute));
    });

    test('comparisonRoute(b) carries this sample into slot B (AC-10)', () {
      final router = _RecordingRouter();
      final controller = _controllerFor(sample, router: router);
      final route = controller.comparisonRoute(ComparisonSlot.b);
      expect(router.comparisonSample, same(controller.sample));
      expect(router.comparisonSlot, ComparisonSlot.b);
      expect(route, same(router.lastRoute));
    });

    test('recipesRoute() makes this sample the recipe target (AC-11)', () {
      final router = _RecordingRouter();
      final controller = _controllerFor(sample, router: router);
      final route = controller.recipesRoute();
      expect(router.recipesTarget, same(controller.sample));
      expect(router.comparisonSample, isNull,
          reason: 'finding recipes is not a comparison handoff');
      expect(route, same(router.lastRoute));
    });

    test('a handoff built after a load() carries the reloaded sample', () {
      // The reading can be replaced in place (bs-02 capture, D-1); the handoff
      // must carry whatever sample is current, not the one built with.
      final router = _RecordingRouter();
      final controller = _controllerFor(sample, router: router);
      const next = Sample(
        name: 'Deep Olive Green',
        coordinates: ColorCoordinates(lightness: 40, a: -12, b: 28),
        provenance: _provenance,
      );
      controller.load(next);
      controller.recipesRoute();
      expect(router.recipesTarget, same(next));
    });
  });
}
