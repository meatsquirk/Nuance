// Acceptance-suite harness for bs-03 Relative comparison (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and independent reference the AC
// tests (ITEST-2, ITEST-3) are written against. The suite drives the *real*
// assembled app through the single production `buildApp` entry with the bs-03
// comparison entry (D-6/D-8): an injected `SampleSource` catalogue, a
// `CvdProfile` and a `ConfusionCheck`. Only the platform speech sink is faked
// (bs-01's `FakeSpeech`); no colour, ΔE00 or confusion math is faked — the real
// `compare` (ΔE00 + LCh decomposition) and the real detector are exercised, and
// a scenario's expected ΔE00 is checked against [referenceDeltaE00], an
// independent CIEDE2000 implementation so AC-4/AC-7 never grade the impl against
// itself.
//
// The pending gate (all 12 ACs → owning phase) lives in `bs03/pending.dart`
// (scaffolded in COMPARE-1); ITEST-1 seeds it with the 12 ACs and this harness
// re-exports it so an AC test imports only this file.
//
// Fixture identifiers mirror the plan's `SAMPLE_*` / `CATALOGUE` / `CVD_*`
// names, and the AC catalogue references them verbatim, so this file opts out of
// lowerCamelCase for them.
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/comparison_controller.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/comparison_state.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate and the fakes so an AC test only needs to import
// this harness.
export 'bs03/pending.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// Samples are stored in canonical CIELAB (the domain's single source of truth).
// A fixture whose plan shape is given in CIELCh carries the exact polar form of
// that chroma/hue in a*/b* (a* = C·cos h, b* = C·sin h), since CIELCh is the
// polar form of CIELAB a*/b* by definition; the L/C/h a slot renders and the
// relational deltas a scenario asserts are derived by the behaviour phases from
// these coordinates. Values are the ones pinned in the master plan's fixture
// table, rounded so C/h recover exactly (C 34, h 42° etc.).
// ---------------------------------------------------------------------------

/// "Warm Terracotta" — CIELAB from CIELCh L 58 / C 34 / h 42° = (58, 25.27,
/// 22.75). Drives AC-1, AC-3, AC-4, AC-5, AC-6, AC-8, AC-10.
const Sample SAMPLE_A_TERRACOTTA = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Raw Sienna Light" — CIELAB from CIELCh L 70 / C 25 / h 60° = (70, 12.50,
/// 21.65). Drives AC-2, AC-3, AC-4, AC-5, AC-8, AC-11.
const Sample SAMPLE_B_SIENNA = Sample(
  name: 'Raw Sienna Light',
  coordinates: ColorCoordinates(lightness: 70, a: 12.50, b: 21.65),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A sample sharing Terracotta's hue angle (CIELCh L 70 / C 25 / **h 42°** =
/// (70, 18.58, 16.73)), different in lightness and chroma. The AC-6 partner: a
/// comparison against [SAMPLE_A_TERRACOTTA] moves lightness and saturation but
/// leaves the hue angle unchanged, so the hue dimension must read "Same hue".
const Sample SAMPLE_A_PRIME = Sample(
  name: 'Terracotta Tint',
  coordinates: ColorCoordinates(lightness: 70, a: 18.58, b: 16.73),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Mid Raw Umber" — one half of the AC-7/AC-9 deutan confusion pair.
///
/// A dark warm reddish-brown (CIELAB L 40 / a\* 18 / b\* 16 — CIELCh C 24.1 /
/// h 41.6°). Paired with [SAMPLE_TERRE_VERTE] it forms a **genuine deutan
/// confusion-line pair** (D-5): the two differ mainly in the red↔green (a\*)
/// direction at equal lightness and near-equal yellowness, so a deuteranope
/// cannot tell them apart, yet they are clearly different to normal vision.
///
/// Constructed and verified in ITEST-3 against the harness's independent
/// [referenceDeutanProjected]: their normal ΔE00 ≈ 28 (clearly different) while
/// their ΔE00 *after* the deutan projection ≈ 1.4 (below the confusion
/// threshold). The verification guard lives in `comparison_test.dart`; CVD-2's
/// shipped detector must agree. (The original "umber / ultramarine" pairing was
/// retired — umber-vs-ultramarine is a blue↔yellow difference, which *no*
/// dichromacy confuses; the spec author renamed B to a green earth, keeping the
/// deutan profile — ITEST-3 reconciliation.)
const Sample SAMPLE_UMBER = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 40, a: 18, b: 16),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Terre Verte Shadow" — the other half of the AC-7/AC-9 deutan confusion pair.
///
/// A dark green earth (CIELAB L 40 / a\* −10 / b\* 18 — CIELCh C 20.6 /
/// h 119°). See [SAMPLE_UMBER]: equal lightness and near-equal b\* with an
/// opposite-signed a\* puts the pair on the deutan confusion line (it collapses
/// under the deutan projection) while staying clearly different to normal
/// vision.
const Sample SAMPLE_TERRE_VERTE = Sample(
  name: 'Terre Verte Shadow',
  coordinates: ColorCoordinates(lightness: 40, a: -10, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

/// The painter's colour-vision profile for the bs-03 scenarios: a full deutan
/// dichromat (D-4). Drives the confusion check (AC-7, AC-8, AC-9).
const CvdProfile CVD_DEUTAN = CvdProfile(type: CvdType.deutan);

/// The saved samples the comparison picker lists (D-7) — the catalogue injected
/// into every scenario. Every selection Given (AC-1, AC-2, …) chooses from this
/// list by name.
const List<Sample> CATALOGUE = [
  SAMPLE_A_TERRACOTTA,
  SAMPLE_B_SIENNA,
  SAMPLE_UMBER,
  SAMPLE_TERRE_VERTE,
  SAMPLE_A_PRIME,
];

// ---------------------------------------------------------------------------
// Independent reference ΔE00
//
// A standalone CIEDE2000 (Sharma, Wu & Dalal 2005) the AC tests grade the
// product's `deltaE00` against, so AC-4/AC-7 never check the implementation
// against itself. Validated against Sharma et al.'s published test data (see
// comparison_test.dart's reference guard). This is test-only reference code; the
// shipped metric is `lib/compare/difference.dart`'s `compare` (DIFF-2).
// ---------------------------------------------------------------------------

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// The CIEDE2000 colour difference ΔE00 between [a] and [b] (reference, D-2).
double referenceDeltaE00(ColorCoordinates a, ColorCoordinates b) {
  const kL = 1.0, kC = 1.0, kH = 1.0;
  final l1 = a.lightness, a1 = a.a, b1 = a.b;
  final l2 = b.lightness, a2 = b.a, b2 = b.b;

  final c1 = math.sqrt(a1 * a1 + b1 * b1);
  final c2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar = (c1 + c2) / 2.0;

  final cBar7 = math.pow(cBar, 7).toDouble();
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25.0, 7))));

  final a1p = (1 + g) * a1;
  final a2p = (1 + g) * a2;

  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);

  double h1p = (a1p == 0 && b1 == 0) ? 0.0 : _deg(math.atan2(b1, a1p));
  if (h1p < 0) h1p += 360.0;
  double h2p = (a2p == 0 && b2 == 0) ? 0.0 : _deg(math.atan2(b2, a2p));
  if (h2p < 0) h2p += 360.0;

  final dLp = l2 - l1;
  final dCp = c2p - c1p;

  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0.0;
  } else {
    final diff = h2p - h1p;
    if (diff.abs() <= 180) {
      dhp = diff;
    } else if (diff > 180) {
      dhp = diff - 360;
    } else {
      dhp = diff + 360;
    }
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_rad(dhp / 2.0));

  final lBarp = (l1 + l2) / 2.0;
  final cBarp = (c1p + c2p) / 2.0;

  double hBarp;
  if (c1p * c2p == 0) {
    hBarp = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarp = (h1p + h2p) / 2.0;
  } else if (h1p + h2p < 360) {
    hBarp = (h1p + h2p + 360) / 2.0;
  } else {
    hBarp = (h1p + h2p - 360) / 2.0;
  }

  final t = 1 -
      0.17 * math.cos(_rad(hBarp - 30)) +
      0.24 * math.cos(_rad(2 * hBarp)) +
      0.32 * math.cos(_rad(3 * hBarp + 6)) -
      0.20 * math.cos(_rad(4 * hBarp - 63));

  final dTheta = 30 * math.exp(-math.pow((hBarp - 275) / 25.0, 2).toDouble());
  final cBarp7 = math.pow(cBarp, 7).toDouble();
  final rc = 2 * math.sqrt(cBarp7 / (cBarp7 + math.pow(25.0, 7)));
  final rt = -rc * math.sin(_rad(2 * dTheta));

  final sl = 1 +
      (0.015 * math.pow(lBarp - 50, 2)) /
          math.sqrt(20 + math.pow(lBarp - 50, 2));
  final sc = 1 + 0.045 * cBarp;
  final sh = 1 + 0.015 * cBarp * t;

  final termL = dLp / (kL * sl);
  final termC = dCp / (kC * sc);
  final termH = dHp / (kH * sh);

  return math.sqrt(
      termL * termL + termC * termC + termH * termH + rt * termC * termH);
}

// ---------------------------------------------------------------------------
// Independent deutan dichromat projection
//
// A standalone simulation of how a deuteranope sees a colour, used *only* to
// verify the `SAMPLE_UMBER` / `SAMPLE_TERRE_VERTE` fixtures genuinely sit on the
// deutan confusion line (ITEST-3's construct-and-verify task, D-5): a pair is on
// the line when its ΔE00 **after** this projection collapses below a small
// threshold while its normal ΔE00 stays clearly-different. This is the deutan
// analogue of [referenceDeltaE00] — an independent reference so the fixtures
// (and, later, CVD-2's shipped detector) are never graded against the product's
// own projection.
//
// Method: Viénot, Brettel & Mollon (1999), the single-plane LMS simulation for
// deuteranopia. CIELAB → XYZ (D65) → linear sRGB → LMS (their matrix) → drop the
// M cone onto the L/S plane (M' = 0.494207·L + 1.24827·S) → back. The
// coefficients are specific to this LMS matrix, so the whole path stays
// self-consistent. Validated by the projection-invariant guards in
// `comparison_test.dart` (a neutral grey is unchanged; the map is idempotent).
// ---------------------------------------------------------------------------

// CIELAB (D65) → XYZ, 0..1 scale.
const double _xn = 0.95047, _yn = 1.0, _zn = 1.08883;

List<double> _labToXyz(ColorCoordinates c) {
  final fy = (c.lightness + 16) / 116;
  final fx = fy + c.a / 500;
  final fz = fy - c.b / 200;
  double inv(double t) {
    final t3 = t * t * t;
    return t3 > 0.008856 ? t3 : (t - 16 / 116) / 7.787;
  }

  return [_xn * inv(fx), _yn * inv(fy), _zn * inv(fz)];
}

ColorCoordinates _xyzToLab(List<double> xyz) {
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  final fx = f(xyz[0] / _xn), fy = f(xyz[1] / _yn), fz = f(xyz[2] / _zn);
  return ColorCoordinates(
    lightness: 116 * fy - 16,
    a: 500 * (fx - fy),
    b: 200 * (fy - fz),
  );
}

List<double> _mul(List<List<double>> m, List<double> v) => [
      for (final row in m) row[0] * v[0] + row[1] * v[1] + row[2] * v[2],
    ];

List<List<double>> _inv3(List<List<double>> m) {
  final a = m[0][0], b = m[0][1], c = m[0][2];
  final d = m[1][0], e = m[1][1], f = m[1][2];
  final g = m[2][0], h = m[2][1], i = m[2][2];
  final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  return [
    [(e * i - f * h) / det, (c * h - b * i) / det, (b * f - c * e) / det],
    [(f * g - d * i) / det, (a * i - c * g) / det, (c * d - a * f) / det],
    [(d * h - e * g) / det, (b * g - a * h) / det, (a * e - b * d) / det],
  ];
}

// Linear sRGB (D65) ↔ XYZ.
const List<List<double>> _rgb2xyz = [
  [0.4124564, 0.3575761, 0.1804375],
  [0.2126729, 0.7151522, 0.0721750],
  [0.0193339, 0.1191920, 0.9503041],
];
// Viénot 1999 LMS from linear sRGB, and the deutan M-drop in that LMS space.
const List<List<double>> _rgb2lms = [
  [17.8824, 43.5161, 4.11935],
  [3.45565, 27.1554, 3.86714],
  [0.0299566, 0.184309, 1.46709],
];
const List<List<double>> _deutanLms = [
  [1.0, 0.0, 0.0],
  [0.494207, 0.0, 1.24827],
  [0.0, 0.0, 1.0],
];

final List<List<double>> _xyz2rgb = _inv3(_rgb2xyz);
final List<List<double>> _lms2rgb = _inv3(_rgb2lms);

/// How colour [c] appears to a deuteranope — the Viénot 1999 deutan simulation.
///
/// Test-only reference for verifying the deutan confusion-line fixtures (D-5);
/// not the shipped detector (CVD-2). See the section header above.
ColorCoordinates referenceDeutanProjected(ColorCoordinates c) {
  final rgb = _mul(_xyz2rgb, _labToXyz(c));
  final lms = _mul(_rgb2lms, rgb);
  final lmsP = _mul(_deutanLms, lms);
  final rgbP = _mul(_lms2rgb, lmsP);
  final xyzP = _mul(_rgb2xyz, rgbP);
  return _xyzToLab(xyzP);
}

/// The ΔE00 between [a] and [b] **as a deuteranope sees them** — their distance
/// after the [referenceDeutanProjected] simulation. Small (below the confusion
/// threshold) for a pair on the deutan confusion line (D-5, AC-7); large for a
/// pair a deuteranope can still tell apart (AC-8's control).
double referenceDeutanProjectedDeltaE00(ColorCoordinates a, ColorCoordinates b) =>
    referenceDeltaE00(referenceDeutanProjected(a), referenceDeutanProjected(b));

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one comparison scenario.
///
/// Holds the recording speech sink the scenario injected (so AC-9 can read what
/// was spoken) and exposes the `when…` actions the painter takes on the
/// Comparison screen, plus [controller] / [state] read seams over the live
/// [ComparisonReadEndpoint] for the Thens the rendered UI does not surface
/// directly (the numeric ΔE00, the `confusable` flag, the decomposition).
class ComparisonHarness {
  ComparisonHarness(this.tester, {required this.speech});

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app (AC-9).
  final FakeSpeech speech;

  /// The live comparison controller behind the screen, read through the
  /// acceptance [ComparisonReadEndpoint] the home screen wraps its subtree in.
  ComparisonController get controller => tester
      .widget<ComparisonReadEndpoint>(
        find.byKey(ComparisonReadEndpoint.endpointKey),
      )
      .controller;

  /// The current observable comparison state (slots + derived reading).
  ComparisonState get state => controller.state;

  /// Chooses the saved sample named [name] into slot A (E3 → picker E49).
  ///
  /// Opens the picker from the Choose-sample-A control and taps the catalogue
  /// entry for [name]. The shell's control is inert until COMPARE-3 drives the
  /// picker over [ComparisonController.savedSamples]; ITEST-2 wires this against
  /// that picker as the selection flow lands.
  Future<void> whenChooseA(String name) => _choose(ComparisonSlot.a, name);

  /// Chooses the saved sample named [name] into slot B (E5 → picker E49).
  Future<void> whenChooseB(String name) => _choose(ComparisonSlot.b, name);

  /// Opens the sample picker for [slot] from its Choose-sample control (E3/E5 →
  /// E49) without choosing an entry, so a test can assert what the picker lists
  /// (AC-1's Given) before picking. The shell's control is inert and opens
  /// nothing; COMPARE-3 opens the real picker over
  /// [ComparisonController.savedSamples]. Tapping the inert control is a no-op
  /// (`warnIfMissed: false` since a disabled control absorbs no pointer).
  Future<void> whenOpenPicker(ComparisonSlot slot) async {
    final label =
        slot == ComparisonSlot.a ? 'Choose sample A' : 'Choose sample B';
    await tester.tap(
      find.widgetWithText(TextButton, label),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  Future<void> _choose(ComparisonSlot slot, String name) async {
    await whenOpenPicker(slot);
    // The picker (E49) must list the catalogue for the painter to choose from.
    // Until COMPARE-3 drives it the Choose control is inert and the picker never
    // opens, so this precondition fails cleanly (naming the owner) rather than
    // the next line tapping a sample entry that is not in the tree.
    expect(
      find.text(name),
      findsWidgets,
      reason:
          'the sample picker must list "$name" to choose it (COMPARE-3 E49)',
    );
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  /// Swaps slots A and B, re-expressing the statement new-A → new-B (E4, AC-3).
  Future<void> whenSwap() async {
    await tester.tap(find.widgetWithText(TextButton, 'Swap A and B'));
    await tester.pumpAndSettle();
  }

  /// Asks to speak the whole comparison, incl. any warning (E6, AC-9).
  Future<void> whenSpeak() async {
    await tester.tap(find.widgetWithText(TextButton, 'Speak whole comparison'));
    await tester.pumpAndSettle();
  }

  /// Opens the full Readout for the sample in [slot] (E7/E8, AC-10/AC-11).
  Future<void> whenOpenReadout(ComparisonSlot slot) async {
    final label = slot == ComparisonSlot.a
        ? 'Open readout for A'
        : 'Open readout for B';
    await tester.tap(find.widgetWithText(TextButton, label));
    await tester.pumpAndSettle();
  }
}

/// Opens the Comparison screen in the fully assembled app for [profile].
///
/// Builds the real app via the production `buildApp` entry with the comparison
/// entry wired (D-8): the [CATALOGUE] catalogue and the given [profile] injected,
/// the speech sink faked and the real `ColorScienceImpl`.
///
/// [confusionCheck] is left **null** by default, so the comparison runs the
/// detector the shipped app wires through [AppDependencies.confusionCheck] — the
/// inert [NoopConfusionCheck] today, CVD-2's real dichromat projection once it
/// lands. AC-7/AC-8/AC-9 therefore exercise the real detector automatically when
/// CVD-2 ships it, with no forward reference to a not-yet-built class. Pass a
/// specific [confusionCheck] only to pin a particular detector in a test.
/// Returns a [ComparisonHarness] over the booted app.
Future<ComparisonHarness> givenComparison(
  WidgetTester tester, {
  CvdProfile profile = CVD_DEUTAN,
  ConfusionCheck? confusionCheck,
}) async {
  final speech = FakeSpeech();
  // When no detector is pinned, omit it so AppDependencies' shipped default
  // applies (the one CVD-2 replaces with the real projection).
  final deps = confusionCheck == null
      ? AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: speech,
          haptics: FakeHaptics(),
          cvdProfile: profile,
          sampleSource: const InMemorySampleSource(samples: CATALOGUE),
          comparisonEntry: const ComparisonEntry(),
        )
      : AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: speech,
          haptics: FakeHaptics(),
          cvdProfile: profile,
          confusionCheck: confusionCheck,
          sampleSource: const InMemorySampleSource(samples: CATALOGUE),
          comparisonEntry: const ComparisonEntry(),
        );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return ComparisonHarness(tester, speech: speech);
}
