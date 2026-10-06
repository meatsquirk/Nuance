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

ReadoutController _controllerFor(Sample sample) => ReadoutController(
      sample: sample,
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: const AppRouter(),
    );

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
}
