// Acceptance-suite harness for bs-11 Accessibility conformance (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and pending gate the AC tests
// (ITEST-2, ITEST-3) are written against. Like every other bs harness it drives
// the *real* assembled app through the single production `buildApp` entry
// (D-7), faking only the platform sinks (Speech, Haptics) and injecting the
// same fixtures each feature's own acceptance suite does. No contrast /
// guideline maths is faked — the real Flutter `meetsGuideline` matchers run
// inside `runConformanceCheck` (D-3).
//
// Two kinds of subject:
//   * `realScreens` — every screen `buildApp` can open on `main` at the branch
//     point (Readout, Capture, Comparison, Recipes, Correction, Palette). Each
//     is launched through the one production entry by *reusing* that feature's
//     own harness `given…` launcher (imported with a prefix so their re-exports
//     and the duplicate `givenComparison` never collide here). This is the
//     sweep the SI mandates (D-1): every real screen must pass every automated
//     rule once the behaviour phases land.
//   * the in-harness **control** fixtures (`compliantReference` + the seven
//     non-compliant `control_*` screens) — deliberate fixtures that exist only
//     to prove each rule discriminates (a rule that never fails its control is
//     vacuous). They are built from the bs-11 primitives + `AppTheme`, not from
//     a feature screen, so they are stable regardless of what the sweep finds.
//
// The pending gate (all 10 automated ACs → owning phase) lives in
// `bs11/pending.dart` (seeded in CONF-1); this harness re-exports it, the
// reusable conformance check / eyes-free driver, and the pure-domain result
// types, so an AC test imports only this file.
//
// Fixture identifiers mirror the plan's `control_*` / `compliantReference`
// names, and the AC catalogue references them verbatim, so this file opts out
// of lowerCamelCase for them (the `control_*` fixtures are `final`, so both the
// const- and non-const-identifier lints are waived).
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/widgets/accessible_notice.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';
import 'package:paint_color_assistant/widgets/status_badge.dart';

// Each real screen is launched through its own feature harness's production
// `buildApp` launcher. Prefixed so their top-level fixtures, the two distinct
// `givenComparison` functions and their `export`ed pending gates / fakes stay
// namespaced and never collide with each other or with this harness.
import '../capture_harness.dart' as cap;
import '../comparison_harness.dart' as cmp;
import '../correction_harness.dart' as cor;
import '../harness.dart' as ro; // bs-01 Readout entry (givenReadoutOf)
import '../palette_harness.dart' as pal;
import '../recipes_harness.dart' as rec;

import '../conformance/conformance_check.dart';
import '../conformance/eyes_free.dart';

// Re-export the pending gate, the reusable check + eyes-free driver and the
// pure-domain result/verdict types so an AC test imports only this harness.
// (These five libraries export disjoint symbols — no re-export collision.)
export 'pending.dart';
export '../conformance/conformance_check.dart';
export '../conformance/eyes_free.dart';
export 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';
export 'package:paint_color_assistant/a11y/conformance/acceptance.dart';

// ---------------------------------------------------------------------------
// Real screens — the sweep subjects (D-1)
// ---------------------------------------------------------------------------

/// One screen `buildApp` can open on `main`, named for the sweep and paired
/// with the launcher that opens it through the single production entry and the
/// [Finder] that locates its home widget once open.
///
/// An AC test (ITEST-2/3) iterates [realScreens], calls [givenScreen] to open
/// each, and runs its rule's check over [screen]; the rule must pass on every
/// entry once its behaviour phase lands.
class RealScreen {
  const RealScreen(this.name, this._launch, this.screen);

  /// A human-readable name used in test descriptions and failure messages.
  final String name;

  final Future<void> Function(WidgetTester) _launch;

  /// Locates the opened screen's home widget — the subtree a conformance check
  /// runs over.
  final Finder screen;

  /// Opens this screen through the production `buildApp` entry.
  Future<void> launch(WidgetTester tester) => _launch(tester);
}

/// Every screen `buildApp` opens on `main` at the bs-11 branch point, each
/// launched through its feature's own production `buildApp` launcher (the same
/// wiring that feature's acceptance suite drives), so the sweep exercises the
/// shipped assembly, not a bespoke one.
///
/// Readout, Capture, Comparison, Recipes, Correction and Palette are the six
/// `home:` branches of `buildApp` (see `build_app.dart`); bs-07 (CVD
/// self-assessment) and bs-08 (display/speech) add layers and chrome around
/// these, not new `buildApp` home entries, so they are swept as part of every
/// screen rather than as separate entries.
final List<RealScreen> realScreens = <RealScreen>[
  RealScreen(
    'Readout',
    (tester) => ro.givenReadoutOf(tester, ro.SAMPLE_TERRACOTTA),
    find.byType(ReadoutScreen),
  ),
  RealScreen(
    'Capture',
    (tester) => cap.givenCaptureOf(tester, cap.SCENE_OLIVE),
    find.byType(CaptureHomeScreen),
  ),
  RealScreen(
    'Comparison',
    (tester) => cmp.givenComparison(tester),
    find.byType(ComparisonHomeScreen),
  ),
  RealScreen(
    'Recipes',
    (tester) => rec.givenRecipes(tester),
    find.byType(RecipesHomeScreen),
  ),
  RealScreen(
    'Correction',
    (tester) => cor.givenCorrection(tester),
    find.byType(CorrectionHomeScreen),
  ),
  RealScreen(
    'Palette',
    (tester) => pal.givenPalette(tester),
    find.byType(PaletteHomeScreen),
  ),
];

// ---------------------------------------------------------------------------
// Control fixtures — discriminating subjects
// ---------------------------------------------------------------------------

/// A non-compliant (or, for [compliantReference], fully compliant) in-harness
/// screen, built from the bs-11 primitives, paired with the [Finder] that
/// locates its body so a check runs over exactly the fixture subtree.
class ControlFixture {
  const ControlFixture(this.name, this.app, this.subtree);

  /// A human-readable name used in test descriptions.
  final String name;

  /// The fully assembled fixture app (its own `MaterialApp` + `AppTheme`).
  final Widget app;

  /// Locates the fixture's keyed body — the subtree a check runs over.
  final Finder subtree;
}

/// A [Key] on each fixture's body so a check can target exactly that subtree.
const Key _referenceKey = Key('bs11.compliantReference');
const Key _lowContrastKey = Key('bs11.control_lowContrast');
const Key _smallTargetKey = Key('bs11.control_smallTarget');
const Key _bareDotKey = Key('bs11.control_bareDot');
const Key _unlabelledKey = Key('bs11.control_unlabelled');
const Key _autoDismissKey = Key('bs11.control_autoDismiss');
const Key _overflow200Key = Key('bs11.control_overflow200');
const Key _partialFailKey = Key('bs11.control_partialFail');

/// Wraps a fixture [body] in a minimal app carrying the real [AppTheme] (the
/// same theme `buildApp` installs), keyed so a check can find it.
Widget _fixtureApp(Key key, Widget body) => MaterialApp(
      theme: AppTheme.light().themeData,
      home: Scaffold(body: Center(child: KeyedSubtree(key: key, child: body))),
    );

/// A minimal screen built only from the bs-11 primitives + [AppTheme] that
/// passes every automated rule — the check's **positive control**: a colour
/// paired with a label ([ColorChip]), a status as text+icon ([StatusBadge],
/// never a bare dot), a ≥48dp labelled control, and a notice that never
/// auto-dismisses ([AccessibleNotice]).
final Widget compliantReference = _fixtureApp(
  _referenceKey,
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ColorChip(label: 'Terracotta', color: Color(0xFFB5651D)),
      const StatusBadge(
        label: 'Measured',
        icon: Icons.verified,
        color: Color(0xFF1B5E20),
      ),
      SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add),
          tooltip: 'Add sample',
        ),
      ),
      const AccessibleNotice(message: 'Saved to your palette'),
    ],
  ),
);

/// Finder for [compliantReference]'s body.
final Finder compliantReferenceFinder = find.byKey(_referenceKey);

/// Text at roughly 1.6:1 on its surface — fails AC-5 (contrast) only.
final ControlFixture control_lowContrast = ControlFixture(
  'control_lowContrast',
  _fixtureApp(
    _lowContrastKey,
    const ColoredBox(
      color: Colors.white,
      child: Text(
        'Low-contrast label',
        style: TextStyle(color: Color(0xFFBDBDBD)),
      ),
    ),
  ),
  find.byKey(_lowContrastKey),
);

/// A 24dp tappable — fails AC-4 (tap target) only.
final ControlFixture control_smallTarget = ControlFixture(
  'control_smallTarget',
  _fixtureApp(
    _smallTargetKey,
    SizedBox(
      width: 24,
      height: 24,
      child: GestureDetector(
        onTap: () {},
        child: Semantics(
          label: 'Tiny action',
          button: true,
          child: const ColoredBox(color: Color(0xFF1565C0)),
        ),
      ),
    ),
  ),
  find.byKey(_smallTargetKey),
);

/// A status shown as a bare coloured dot with no text or icon — fails AC-1
/// (colour cue) and AC-2 (no bare dot).
final ControlFixture control_bareDot = ControlFixture(
  'control_bareDot',
  _fixtureApp(
    _bareDotKey,
    Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFC62828),
        shape: BoxShape.circle,
      ),
    ),
  ),
  find.byKey(_bareDotKey),
);

/// An [IconButton] with no tooltip or semantic label — fails AC-6 (meaningful
/// label) only.
final ControlFixture control_unlabelled = ControlFixture(
  'control_unlabelled',
  _fixtureApp(
    _unlabelledKey,
    SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.settings),
      ),
    ),
  ),
  find.byKey(_unlabelledKey),
);

/// A screen that shows a standard [SnackBar] auto-dismissing on a timer — fails
/// AC-8 (nothing auto-dismisses). A11Y-7's no-timeout rule advances the clock
/// past the duration and asserts the SnackBar is gone (the discriminating
/// control), while a real [AccessibleNotice] persists.
final ControlFixture control_autoDismiss = ControlFixture(
  'control_autoDismiss',
  const _AutoDismissControl(key: _autoDismissKey),
  find.byKey(_autoDismissKey),
);

/// A standard SnackBar that auto-dismisses on a short timer — the AC-8 control.
///
/// A [StatefulWidget] because a SnackBar must be shown through a
/// [ScaffoldMessenger] after the first frame; it carries no [AccessibleNotice],
/// so A11Y-7's rule flags it once the clock advances past [_dismissAfter].
class _AutoDismissControl extends StatefulWidget {
  const _AutoDismissControl({super.key});

  @override
  State<_AutoDismissControl> createState() => _AutoDismissControlState();
}

class _AutoDismissControlState extends State<_AutoDismissControl> {
  /// The default-length auto-dismiss window the control imposes (AC-8 violation).
  static const Duration _dismissAfter = Duration(seconds: 4);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light().themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            // Show the auto-dismissing SnackBar once, after the first frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auto-dismissing notice'),
                  duration: _dismissAfter,
                ),
              );
            });
            return const Center(child: Text('Auto-dismiss control'));
          },
        ),
      ),
    );
  }
}

/// A fixed-height column of status rows whose height tracks the font scale, so
/// it does not fit at 200% — fails AC-3 (200% scaling) only. The three rows fit
/// inside the 100dp height at the default scale and overflow it once the text
/// doubles (a `RenderFlex` whose children exceed its bounds — what the scaling
/// rule measures).
///
/// A11Y-4 note: the ITEST-1 fixture was a fixed-*height* `Row` with its label in
/// `Expanded`, which flex-shrinks the text to fit and *silently clips* it —
/// reporting no overflow, so no overflow-based rule could flag it (the control
/// was non-discriminating). It is replaced by a fixed-height column whose rows
/// are each sized by `MediaQuery.textScaler` (30dp → 60dp at 200%). Scaling the
/// box height by the text scaler — rather than relying on a glyph's measured
/// width or line height — makes the overflow **deterministic and
/// font-independent**: it holds identically under the widget-test font and the
/// on-device font (a text-width control overflows only under the wider test
/// font, and a raw line-height control depends on the font's metrics and
/// wrapping). The fixture's name and single-rule intent are unchanged.
final ControlFixture control_overflow200 = ControlFixture(
  'control_overflow200',
  _fixtureApp(
    _overflow200Key,
    SizedBox(
      height: 100,
      width: 200,
      child: Column(
        children: [
          for (var i = 1; i <= 3; i++)
            Builder(
              builder: (context) => SizedBox(
                height: MediaQuery.textScalerOf(context).scale(30),
                child: Text('Status line $i'),
              ),
            ),
        ],
      ),
    ),
  ),
  find.byKey(_overflow200Key),
);

/// A screen that passes most rules but fails exactly one (an undersized target
/// among otherwise-compliant widgets) — drives AC-9's *not accepted* decision
/// (≥1 failing rule **and** ≥1 passing rule).
final ControlFixture control_partialFail = ControlFixture(
  'control_partialFail',
  _fixtureApp(
    _partialFailKey,
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ColorChip(label: 'Terracotta', color: Color(0xFFB5651D)),
        const StatusBadge(
          label: 'Measured',
          icon: Icons.verified,
          color: Color(0xFF1B5E20),
        ),
        // The single rule failure: a 24dp target (fails AC-4) beside compliant
        // widgets, so the aggregate has both a passing and a failing rule.
        SizedBox(
          width: 24,
          height: 24,
          child: GestureDetector(
            onTap: () {},
            child: Semantics(
              label: 'Tiny action',
              button: true,
              child: const ColoredBox(color: Color(0xFF1565C0)),
            ),
          ),
        ),
      ],
    ),
  ),
  find.byKey(_partialFailKey),
);

/// Every control fixture (the positive [compliantReference] is kept separate,
/// since it is the one that must *pass*).
final List<ControlFixture> controlFixtures = <ControlFixture>[
  control_lowContrast,
  control_smallTarget,
  control_bareDot,
  control_unlabelled,
  control_autoDismiss,
  control_overflow200,
  control_partialFail,
];

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// Opens [realScreen] through the production `buildApp` entry, leaving it
/// rendered and (where the screen settles) settled, ready for a conformance
/// check over [RealScreen.screen].
Future<void> givenScreen(WidgetTester tester, RealScreen realScreen) =>
    realScreen.launch(tester);

/// Pumps a control [fixture]'s app and settles it, ready for a check over
/// [ControlFixture.subtree].
Future<void> givenControl(WidgetTester tester, ControlFixture fixture) async {
  // Reset the tree first so a repeated `given…` in one test never reuses the
  // previous screen's State (mirrors the other bs harnesses).
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.pumpWidget(fixture.app);
  await tester.pumpAndSettle();
}

/// Pumps the [compliantReference] app and settles it, ready for a check over
/// [compliantReferenceFinder].
Future<void> givenCompliantReference(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.pumpWidget(compliantReference);
  await tester.pumpAndSettle();
}

/// Runs the reusable automated conformance check over [screen] and returns its
/// aggregate [ConformanceResult] (D-3).
Future<ConformanceResult> whenCheckedForConformance(
  WidgetTester tester,
  Finder screen,
) =>
    runConformanceCheck(tester, screen);

/// Applies a system font-scale of [textScale] to the whole app (e.g. 2.0 for
/// AC-3's 200% case) and re-settles. The override is cleared automatically when
/// the current test ends, so it never leaks into the next test.
///
/// Sets the binding's platform text-scale, which `MediaQuery` reads for the
/// entire tree — the same knob the OS turns — so an already-opened real screen
/// rescales in place without rebuilding it with a bespoke `MediaQuery`.
Future<void> whenScaledTo(WidgetTester tester, double textScale) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
}

/// Advances the clock by [duration] (a settle point for AC-8's negative Then:
/// nothing auto-dismisses) and pumps the resulting frames.
Future<void> whenWaited(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
  await tester.pumpAndSettle();
}

/// Drives a core task using only semantic labels + `SemanticsAction` (AC-7,
/// D-6) and returns whether the terminal state was reached. A thin pass-through
/// to the reusable [eyesFreeComplete] so an AC test speaks one vocabulary.
Future<bool> whenCompletedEyesFree(
  WidgetTester tester, {
  required List<String> steps,
}) =>
    eyesFreeComplete(tester, steps: steps);
