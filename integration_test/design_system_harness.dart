// Acceptance-suite harness for bs-17 Visual design system (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and pending gate the AC tests
// (ITEST-2, ITEST-3) are written against. The suite drives the *real* assembled
// app through the single production `buildApp` entry (D-6/D-7): the real
// `AppTheme`, the real styled component widgets and the real screens, so every
// token / shape / font / component assertion reads what production renders.
// Only the platform sinks sibling harnesses already fake are faked (`FakeSpeech`
// / `FakeHaptics` and, for the Capture screen, the deterministic
// `FakeCaptureSource`); the design system itself is pure Flutter rendering and
// is never faked.
//
// [pumpApp] positions the suite on each primary screen in [screenRoster] through
// the one assembly entry (the entry flags `AppDependencies` already exposes), so
// AC-14's "every screen inherits the one theme" and AC-15's swatch sweep walk
// the real screens. The token ACs read [DesignSystemHarness.installedTheme]
// (the one `ThemeData` on the `MaterialApp`); the component ACs find the widgets
// by type; AC-14's no-hardcoded-palette rule reads the source-scan helper
// (`design_system_source_scan.dart`).
//
// Re-exports the pending gate, the fakes, the source-scan helper and the theme /
// component libraries so an AC test imports only this harness.
//
// Fixture identifiers (`WarmPaper` tokens) mirror the wireframe THEME token
// names, which the AC catalogue references verbatim.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/widgets/mono_label.dart';
import 'package:paint_color_assistant/widgets/pill_button.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';
import 'package:paint_color_assistant/widgets/speak_button.dart';
import 'package:paint_color_assistant/widgets/surface_card.dart';

import 'fakes/fake_capture_source.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate, the fakes, the source-scan helper and the theme /
// component surfaces so an AC test needs to import only this harness.
export 'package:paint_color_assistant/app/theme.dart' show AppTheme;
export 'package:paint_color_assistant/widgets/mono_label.dart';
export 'package:paint_color_assistant/widgets/pill_button.dart';
export 'package:paint_color_assistant/widgets/provenance_badge.dart';
export 'package:paint_color_assistant/widgets/speak_button.dart';
export 'package:paint_color_assistant/widgets/surface_card.dart';
export 'bs17/pending.dart';
export 'design_system_source_scan.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures: the warm-paper token table
//
// The expected hex values the token ACs (AC-1/AC-2/AC-3) assert the installed
// scheme against — the wireframe's THEME tokens. These are the *target* values
// the behaviour phases (THEME-3) make true; at baseline the stock scheme does
// not match them, which is why the token ACs fail in the run-pending baseline.
// They live in this test file (never scanned by AC-14, which sweeps `lib/`).
// ---------------------------------------------------------------------------

/// The wireframe's warm-paper THEME tokens the colour ACs assert the installed
/// [ColorScheme] against.
abstract final class WarmPaper {
  /// `--bg` — the warm paper background tone.
  static const Color background = Color(0xFFF3F1EC);

  /// `--sf` — raised surfaces (paper white).
  static const Color surface = Color(0xFFFFFFFF);

  /// `--sf2` — sunken surfaces (muted paper tone).
  static const Color sunken = Color(0xFFE9E6DF);

  /// `--ink` — primary text (near-black ink).
  static const Color ink = Color(0xFF16150F);

  /// `--mut` — secondary text (warm grey).
  static const Color muted = Color(0xFF57544C);

  /// `--ln` — dividers / hairlines (paper hairline).
  static const Color line = Color(0xFFCFCAC0);

  /// `--acc` — the primary-action cobalt accent (sRGB equivalent of the
  /// wireframe's `oklch(0.48 0.16 262)`, D-5).
  static const Color accent = Color(0xFF2F55C8);

  /// `--accInk` — the label colour on the accent (white).
  static const Color accentInk = Color(0xFFFFFFFF);

  /// Every token, for a guard that asserts they are distinct (no vacuous
  /// placeholder sharing one value).
  static const List<Color> all = [
    background,
    surface,
    sunken,
    ink,
    muted,
    line,
    accent,
    accentInk,
  ];
}

// ---------------------------------------------------------------------------
// The screen roster
// ---------------------------------------------------------------------------

/// A primary screen the suite walks through the one `buildApp` entry.
///
/// Each value names the `AppDependencies` entry flag [pumpApp] sets to open the
/// app on that screen (readout is the default entry). The [label] is the
/// screen's human name, for failure messages.
enum DesignScreen {
  /// `captureSource` — the Capture screen.
  capture('Capture'),

  /// Default entry — the Readout screen for `initialSample`.
  readout('Readout'),

  /// `comparisonEntry` — the side-by-side Comparison screen.
  compare('Comparison'),

  /// `recipesEntry` — the Recipes screen mixing toward a target.
  recipes('Recipes'),

  /// `paletteEntry` — the Palette / Projects screen.
  palette('Palette');

  const DesignScreen(this.label);

  /// The screen's human name, for failure messages.
  final String label;
}

/// The primary screens AC-14 (one theme) and AC-15 (swatch caption) walk.
const List<DesignScreen> screenRoster = DesignScreen.values;

/// The canonical ground truth the Capture screen's [FakeCaptureSource] reads —
/// the demo terracotta, so the capture entry has a scene to render.
const ColorCoordinates _captureGroundTruth =
    ColorCoordinates(lightness: 58, a: 36, b: 34);

// ---------------------------------------------------------------------------
// The harness
// ---------------------------------------------------------------------------

/// A driver over the assembled app positioned on one [DesignScreen].
///
/// Holds the recording platform sinks (so a scenario that drives spoken output
/// can read it) and exposes the design-system observation points: the one
/// installed [ThemeData] and its [ColorScheme] / [TextTheme] (the token / font
/// ACs), and — through the top-level finders below — the styled component
/// widgets (the component ACs).
class DesignSystemHarness {
  DesignSystemHarness(
    this.tester, {
    required this.screen,
    required this.speech,
    required this.haptics,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The screen the app was opened on.
  final DesignScreen screen;

  /// The recording speech sink injected into the app.
  final FakeSpeech speech;

  /// The recording haptics sink injected into the app.
  final FakeHaptics haptics;

  /// The single [ThemeData] installed on the app's [MaterialApp] — the one
  /// theme chokepoint every screen inherits (AC-14). The token / shape / font
  /// ACs read it; AC-14 asserts there is no nested [Theme] below it.
  ThemeData get installedTheme =>
      tester.widget<MaterialApp>(find.byType(MaterialApp).first).theme!;

  /// The installed [ColorScheme] (AC-1/AC-2/AC-3 read its surface / neutral /
  /// accent roles).
  ColorScheme get colorScheme => installedTheme.colorScheme;

  /// The installed [TextTheme] (AC-5/AC-6 read its families).
  TextTheme get textTheme => installedTheme.textTheme;
}

/// Opens the app on [screen] in the fully assembled app.
///
/// Builds the real app via the single production `buildApp` entry (D-7) with the
/// entry flag for [screen] set and the platform sinks faked; colour-science is
/// the real [ColorScienceImpl]. A *fresh* app is pumped each call (an empty
/// frame first) so a repeated [pumpApp] in one test disposes the prior screen's
/// state rather than reusing it. Returns a [DesignSystemHarness] over the booted
/// app.
Future<DesignSystemHarness> pumpApp(
  WidgetTester tester, {
  DesignScreen screen = DesignScreen.readout,
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  await tester.pumpWidget(buildApp(_depsFor(screen, speech, haptics)));
  await tester.pumpAndSettle();
  return DesignSystemHarness(
    tester,
    screen: screen,
    speech: speech,
    haptics: haptics,
  );
}

/// The production dependencies that open the app on [screen] — the entry flag
/// for the screen plus the faked platform sinks; every other seam takes its
/// production default (D-7).
AppDependencies _depsFor(
  DesignScreen screen,
  FakeSpeech speech,
  FakeHaptics haptics,
) {
  switch (screen) {
    case DesignScreen.readout:
      return AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
      );
    case DesignScreen.capture:
      return AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        captureSource:
            FakeCaptureSource(const SceneSpec(groundTruth: _captureGroundTruth)),
      );
    case DesignScreen.compare:
      return AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        comparisonEntry: const ComparisonEntry(),
      );
    case DesignScreen.recipes:
      return AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        recipesEntry: const RecipesEntry(target: demoSample),
      );
    case DesignScreen.palette:
      return AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        paletteEntry: const PaletteEntry(),
      );
  }
}

// ---------------------------------------------------------------------------
// Component finders (the component ACs anchor on these)
// ---------------------------------------------------------------------------

/// Every [PillButton] in the tree (AC-7 shape, AC-10 primary/secondary).
Finder get pillButtons => find.byType(PillButton);

/// Every [SpeakButton] in the tree (AC-11 round accent FAB).
Finder get speakButtons => find.byType(SpeakButton);

/// Every [SurfaceCard] in the tree (AC-7 radius, AC-12 variants).
Finder get surfaceCards => find.byType(SurfaceCard);

/// Every [MonoLabel] in the tree (AC-6 mono family, AC-9 uppercase/weight/track).
Finder get monoLabels => find.byType(MonoLabel);

/// Every [ProvenanceBadge] in the tree (AC-13 glyph-and-border signature).
Finder get provenanceBadges => find.byType(ProvenanceBadge);

// ---------------------------------------------------------------------------
// Style resolution (the font ACs read the effective style on a rendered Text)
// ---------------------------------------------------------------------------

/// The effective [TextStyle] of the [Text] found by [textFinder] — its own
/// style merged onto the ambient [DefaultTextStyle], as Flutter renders it. The
/// font ACs (AC-5 Next, AC-6 Mono) read `fontFamily` from this.
TextStyle effectiveTextStyleOf(WidgetTester tester, Finder textFinder) {
  final text = tester.widget<Text>(textFinder);
  final defaultStyle = DefaultTextStyle.of(tester.element(textFinder)).style;
  return text.style == null ? defaultStyle : defaultStyle.merge(text.style);
}
