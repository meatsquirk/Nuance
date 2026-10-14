import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/cvd/daltonize.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/conversions.dart';
import 'package:paint_color_assistant/display/color_simulation.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

/// The displayed sRGB [Color] of a projected CIELAB colour — the same back
/// conversion the readout uses, so the expectation composes the shipped pieces
/// (this is the chokepoint's own wiring; the acceptance test grades the result
/// against an independent projection, AC-3).
Color _project(Color original, CvdType type, {double severity = 1.0}) {
  final lab = srgbToLab(SRGBColor(
    red: (original.r * 255).round(),
    green: (original.g * 255).round(),
    blue: (original.b * 255).round(),
  ));
  final out =
      labToSrgb(projectDichromat(lab, CvdProfile(type: type, severity: severity)));
  return Color.fromARGB(255, out.red, out.green, out.blue);
}

void main() {
  // A saturated cyan-blue: shifted a clear distance by every one of the three
  // dichromacies (red-green for protan/deutan, blue-yellow for tritan), so the
  // "projection actually moves the colour" control below holds for each type.
  const original = Color(0xFF3AA0BF);

  group('simulateColor — identity (simulation off, AC-2)', () {
    test('returns the original colour when no simulation type is set', () {
      expect(simulateColor(original, const DisplaySettings()), original);
    });

    test('a severity set while the type is off still leaves the colour '
        'untouched (off is defined by the null type)', () {
      expect(
        simulateColor(original, const DisplaySettings(simulationSeverity: 0.5)),
        original,
      );
    });
  });

  group('simulateColor — projection (simulation on, AC-3)', () {
    for (final type in CvdType.values) {
      test('projects through the shipped projectDichromat for $type', () {
        final settings = DisplaySettings(simulationType: type);
        final simulated = simulateColor(original, settings);
        // Composes srgb→lab → projectDichromat → lab→srgb with the chosen type
        // at full severity (the CvdProfile default this DisplaySettings carries).
        expect(simulated, _project(original, type));
        // Control: the projection actually shifts this colour — a stubbed
        // identity (ignoring the type) would fail here.
        expect(simulated, isNot(original),
            reason: '$type projection shifts this saturated colour');
      });
    }

    test('uses the settings severity (severity 0 collapses to the original)',
        () {
      // Severity 0: projectDichromat blends 0 of the way to the dichromat
      // projection, so the displayed colour is the original (within the sRGB
      // round-trip). Proves the severity is read, not hard-coded to 1.
      final simulated = simulateColor(
        original,
        const DisplaySettings(
            simulationType: CvdType.deutan, simulationSeverity: 0),
      );
      expect(simulated, _project(original, CvdType.deutan, severity: 0));
      expect(_channelDistance(simulated, original), lessThanOrEqualTo(2),
          reason: 'severity 0 renders the unaffected original');
    });

    test('severity scales the shift (half is nearer the original than full)',
        () {
      final half = simulateColor(
        original,
        const DisplaySettings(
            simulationType: CvdType.deutan, simulationSeverity: 0.5),
      );
      final full = simulateColor(
        original,
        const DisplaySettings(simulationType: CvdType.deutan),
      );
      expect(_channelDistance(half, original),
          lessThan(_channelDistance(full, original)),
          reason: 'a weaker severity sits closer to the true colour');
    });
  });

  // bs-10 DALT-2: the one display-transform decision shared by ColorChip and
  // the read endpoint. The two view modes are distinct (AC-7); daltonization,
  // when on, takes the colour through the (identity, for now) bs-10 remap, and
  // simulation otherwise.
  group('displayedSwatchColor — the shared chokepoint', () {
    const profile = CvdProfile(type: CvdType.deutan);

    test('daltonization off, simulation off → the simulation identity', () {
      const settings = DisplaySettings();
      expect(displayedSwatchColor(original, settings, profile),
          simulateColor(original, settings));
      expect(displayedSwatchColor(original, settings, profile), original);
    });

    test('daltonization off → the original regardless of the stored profile '
        '(AC-2: off is unremapped, never consults the profile)', () {
      // AC-2 (DALT-6): with daltonization off, colours are shown with their
      // original values. The off branch must not touch the stored profile — a
      // strong protan profile that produces a large remap when on still leaves
      // the colour unchanged while off. Rejects an off path that leaks a remap
      // (or that reads the profile) when daltonization is false; the existing
      // off/off case above only uses a default-severity deutan, which a bug that
      // scaled a tiny remap by severity could slip past.
      const off = DisplaySettings();
      const strong = CvdProfile(type: CvdType.protan, severity: 1);
      expect(displayedSwatchColor(original, off, strong), original,
          reason: 'off → the original, whatever the stored profile');
      // Control: that same strong profile *does* move the colour when on, so the
      // off result above is the off branch, not a coincidentally gentle profile.
      const on = DisplaySettings(daltonization: true);
      expect(displayedSwatchColor(original, on, strong), isNot(original),
          reason: 'the same strong profile remaps the colour when on');
    });

    test('daltonization off, simulation on → the simulation projection', () {
      const settings = DisplaySettings(simulationType: CvdType.deutan);
      final displayed = displayedSwatchColor(original, settings, profile);
      expect(displayed, simulateColor(original, settings));
      expect(displayed, isNot(original),
          reason: 'with simulation on the chokepoint still simulates');
    });

    test('daltonization on → the daltonization remap (not the simulation)', () {
      // Daltonization set, with a simulation type also set: the chokepoint takes
      // the daltonization branch, not simulateColor (AC-7 distinctness).
      const settings = DisplaySettings(
        simulationType: CvdType.deutan,
        daltonization: true,
      );
      expect(displayedSwatchColor(original, settings, profile),
          daltonizeColor(original, profile));
    });

    // AC-7 (DALT-5): the two view modes diverge *at the chokepoint*. With the
    // same stored profile the daltonization output aids distinction while the
    // simulation output shows perception, so the chokepoint must not render one
    // as the other. This pins the distinctness at the render grain (not only
    // that `daltonize` differs from `projectDichromat` as a pure function —
    // daltonize_test.dart `is distinct from the dichromat projection`): a
    // refactor that routed daltonization through the simulation projection would
    // pass the pure-function test's inputs yet fail here.
    test('daltonization on → distinct from the simulation render for the same '
        'colour + profile (AC-7)', () {
      const deutan = CvdProfile(type: CvdType.deutan);
      const daltonized = DisplaySettings(daltonization: true);
      const simulated = DisplaySettings(simulationType: CvdType.deutan);
      final dalt = displayedSwatchColor(original, daltonized, deutan);
      final sim = displayedSwatchColor(original, simulated, deutan);
      // Both transform this chromatic swatch (neither is the identity)…
      expect(dalt, isNot(original), reason: 'daltonization moves the colour');
      expect(sim, isNot(original), reason: 'simulation moves the colour');
      // …and the daltonization remap is a different colour from the simulation
      // projection of the same colour + profile — it aids distinction, it does
      // not show how the painter perceives the colour.
      expect(_channelDistance(dalt, sim), greaterThan(2),
          reason: 'the chokepoint keeps daltonization distinct from simulation');
      // And it is not `simulateColor` either (the simulation render path).
      expect(dalt, isNot(simulateColor(original, simulated)),
          reason: 'the remap is not the simulation projection');
    });

    // AC-5 (D-3): the chokepoint drives the remap from the *stored* profile it
    // is handed — its type and its severity — never a hard-coded default. These
    // pin that the `profile` argument is forwarded whole, so when the render
    // feeds it `AppScope.cvdProfile` the painter's saved values reach the remap.
    test('daltonization on → the chokepoint forwards the stored profile TYPE', () {
      const settings = DisplaySettings(daltonization: true);
      const protan = CvdProfile(type: CvdType.protan);
      const deutan = CvdProfile(type: CvdType.deutan);
      // Each result is the remap for exactly the profile handed in…
      expect(displayedSwatchColor(original, settings, protan),
          daltonizeColor(original, protan));
      expect(displayedSwatchColor(original, settings, deutan),
          daltonizeColor(original, deutan));
      // …and the two differ, so the type is read from the stored profile, not a
      // fixed default (an impl ignoring the argument's type could not do this).
      expect(displayedSwatchColor(original, settings, protan),
          isNot(displayedSwatchColor(original, settings, deutan)),
          reason: 'the chokepoint remaps per the stored profile type');
    });

    test('daltonization on → the chokepoint forwards the stored SEVERITY, which '
        'scales the remap', () {
      const settings = DisplaySettings(daltonization: true);
      const none = CvdProfile(type: CvdType.deutan, severity: 0);
      const mild = CvdProfile(type: CvdType.deutan, severity: 0.3);
      const strong = CvdProfile(type: CvdType.deutan, severity: 0.9);
      // Severity 0 (an unaffected painter) → no remap: the original is shown.
      expect(displayedSwatchColor(original, settings, none), original,
          reason: 'severity 0 collapses the remap to the original');
      // Each result is the remap at exactly the stored severity…
      expect(displayedSwatchColor(original, settings, mild),
          daltonizeColor(original, mild));
      expect(displayedSwatchColor(original, settings, strong),
          daltonizeColor(original, strong));
      // …and a stronger stored severity remaps further from the original, so the
      // severity is read and scales the shift (rejects a hard-coded severity).
      expect(
        _channelDistance(displayedSwatchColor(original, settings, strong), original),
        greaterThan(
            _channelDistance(displayedSwatchColor(original, settings, mild), original)),
        reason: 'a stronger stored severity yields a stronger remap',
      );
    });

    // AC-8 (DALT-7): the remap is a display transform only. The chokepoint
    // returns a new colour for display and writes nothing back, so a daltonized
    // render followed by an off render still yields the original. An
    // implementation that cached or persisted the remapped colour (so the "off"
    // read came back remapped) would fail here; the on-control shows the on
    // render genuinely moved the colour, so the off-equality is meaningful.
    test('daltonization on remaps only the returned colour; a later off render '
        'still yields the original (no write-back, AC-8)', () {
      const on = DisplaySettings(daltonization: true);
      const off = DisplaySettings();
      const strong = CvdProfile(type: CvdType.deutan, severity: 0.9);
      // The on render moves the colour (a real remap)…
      final remapped = displayedSwatchColor(original, on, strong);
      expect(remapped, isNot(original),
          reason: 'daltonization on genuinely remaps the shown colour');
      // …yet a subsequent off render returns the original — the remap persisted
      // nothing back to any shared state.
      expect(displayedSwatchColor(original, off, strong), original,
          reason: 'an off render after a remapped one still shows the original — '
              'the remap was never written back');
      // And repeating the on render yields the same remap (a pure function of
      // its arguments, carrying no state between calls).
      expect(displayedSwatchColor(original, on, strong), remapped,
          reason: 'the remap is a pure transform of (colour, settings, profile)');
    });
  });
}

/// Summed absolute 8-bit channel distance between two opaque colours.
int _channelDistance(Color a, Color b) =>
    ((a.r - b.r).abs() * 255 +
            (a.g - b.g).abs() * 255 +
            (a.b - b.b).abs() * 255)
        .round();
