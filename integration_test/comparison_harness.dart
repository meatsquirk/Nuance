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
/// Provisional CIELAB: a dark yellow-brown clearly different from
/// [SAMPLE_ULTRAMARINE] to normal vision. The confusion-line property (their
/// ΔE00 collapses below the threshold *under the deutan projection* while their
/// normal ΔE00 is clearly-different, D-5) is **constructed and verified in
/// ITEST-3 / CVD-2**, which pins the exact coordinates (and escalates to the
/// spec author if no genuine deutan pair can be found). ITEST-1 only provides
/// the named fixture so the catalogue lists it.
// TODO(ITEST-3): verify/pin the deutan confusion-line coordinates (D-5).
const Sample SAMPLE_UMBER = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 37, a: 8, b: 22),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Ultramarine Shadow" — the other half of the AC-7/AC-9 deutan confusion pair.
///
/// Provisional CIELAB: a dark blue clearly different from [SAMPLE_UMBER] to
/// normal vision. See [SAMPLE_UMBER] — the confusion-line construction is
/// ITEST-3 / CVD-2's responsibility.
// TODO(ITEST-3): verify/pin the deutan confusion-line coordinates (D-5).
const Sample SAMPLE_ULTRAMARINE = Sample(
  name: 'Ultramarine Shadow',
  coordinates: ColorCoordinates(lightness: 37, a: 10, b: -38),
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
  SAMPLE_ULTRAMARINE,
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
/// entry wired (D-8): the [CATALOGUE] catalogue, the given [profile] and
/// [confusionCheck] injected, the speech sink faked and the real
/// `ColorScienceImpl`. [confusionCheck] defaults to the inert
/// [NoopConfusionCheck] the shipped app wires until CVD-2; AC-7/AC-8/AC-9 inject
/// the real detector once it lands. Returns a [ComparisonHarness] over the
/// booted app.
Future<ComparisonHarness> givenComparison(
  WidgetTester tester, {
  CvdProfile profile = CVD_DEUTAN,
  ConfusionCheck confusionCheck = const NoopConfusionCheck(),
}) async {
  final speech = FakeSpeech();
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: FakeHaptics(),
        cvdProfile: profile,
        confusionCheck: confusionCheck,
        sampleSource: const InMemorySampleSource(samples: CATALOGUE),
        comparisonEntry: const ComparisonEntry(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ComparisonHarness(tester, speech: speech);
}
