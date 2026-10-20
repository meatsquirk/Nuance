// Acceptance-suite harness for bs-18 Apply the visual design system (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and pending gate the AC tests
// (ITEST-2/3/4) are written against. bs-18 is a *presentation* application over
// bs-17 (D-2), so the suite drives the **real** assembled app through the single
// production `buildApp` entry (D-7) — the real `AppTheme`, the real CHROME-2
// shell, the real bs-17 wrapper widgets and the real screens — and asserts, per
// control/region, that the design-system wrapper is present and the superseded
// ad-hoc widget absent (D-3). Only the platform sinks the sibling harnesses
// already fake are faked (`FakeSpeech` / `FakeHaptics`, and a deterministic
// `FakeCaptureSource` for the Capture scene); colour-science is the real
// `ColorScienceImpl`. The design system itself is pure Flutter rendering and is
// never faked.
//
// [pumpShell] boots the default route — the four-destination nav shell (AC-1 /
// AC-2, and the Readout AC-5, whose screen is the opening Capture destination's
// body). [pumpScreen] opens a deep-link destination (Capture / Compare / Recipes
// / Palette) through its `AppDependencies` entry flag, wired with the matching
// fixture's source, exactly as the sibling design-system harness positions each
// screen. The CFG screens (Display settings reached through the app chrome,
// onboarding pushed onto the running app) have no home entry; ITEST-3 extends
// this harness with their pump when it authors AC-10.
//
// Re-exports the pending gate, the fixtures, the fakes, the shell/top-bar types
// and the bs-17 component widgets so an AC test imports only this harness.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/app_destinations.dart';
import 'package:paint_color_assistant/app/app_shell.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/inactive_peer_transport.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';
import 'package:paint_color_assistant/widgets/mono_label.dart';
import 'package:paint_color_assistant/widgets/pill_button.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';
import 'package:paint_color_assistant/widgets/speak_button.dart';
import 'package:paint_color_assistant/widgets/surface_card.dart';
import 'package:paint_color_assistant/widgets/swatch_caption.dart';

import '../fakes/fake_capture_source.dart';
import '../fakes/fake_haptics.dart';
import '../fakes/fake_speech.dart';
import 'fixtures.dart';

// Re-export the gate, fixtures, fakes, shell/top-bar and component surfaces so
// an AC test needs to import only this harness.
export 'package:paint_color_assistant/app/app_destinations.dart';
export 'package:paint_color_assistant/app/app_shell.dart';
export 'package:paint_color_assistant/app/app_top_bar.dart';
export 'package:paint_color_assistant/widgets/mono_label.dart';
export 'package:paint_color_assistant/widgets/pill_button.dart';
export 'package:paint_color_assistant/widgets/provenance_badge.dart';
export 'package:paint_color_assistant/widgets/speak_button.dart';
export 'package:paint_color_assistant/widgets/surface_card.dart';
export 'package:paint_color_assistant/widgets/swatch_caption.dart';
export '../fakes/fake_haptics.dart';
export '../fakes/fake_speech.dart';
export 'fixtures.dart';
export 'pending.dart';

// ---------------------------------------------------------------------------
// The screen roster
// ---------------------------------------------------------------------------

/// A surface the suite positions the assembled app on.
///
/// [shell] is the default route (the nav shell; its opening Capture destination
/// renders the Readout, so AC-1/AC-2/AC-5 all pump [shell]). The others are the
/// deep-link destinations opened through their `AppDependencies` entry flag.
enum VisualScreen {
  /// The default route — the four-destination bottom-nav shell.
  shell('Shell'),

  /// `captureSource` — the Capture screen.
  capture('Capture'),

  /// `comparisonEntry` — the side-by-side Compare screen.
  compare('Compare'),

  /// `recipesEntry` — the Recipes screen mixing toward the fixture target.
  recipes('Recipes'),

  /// `paletteEntry` — the Palette / Projects screen.
  palette('Palette'),

  /// The Display settings panel (AC-10) — opened through the app chrome's E2
  /// entry on every route; it has no `AppDependencies` entry flag, so
  /// [pumpDisplaySettings] pumps it, not [_pump].
  displaySettings('Display settings'),

  /// The onboarding / self-assessment host (AC-10) — pushed onto the running
  /// app through its production route; no entry flag, so [pumpOnboarding] pumps
  /// it, not [_pump].
  onboarding('Onboarding');

  const VisualScreen(this.label);

  /// The surface's human name, for failure messages.
  final String label;
}

// ---------------------------------------------------------------------------
// The harness
// ---------------------------------------------------------------------------

/// A driver over the assembled app positioned on one [VisualScreen].
///
/// Holds the recording platform sinks and exposes the observation points the
/// swap ACs read: the one installed [ThemeData] (AC-11), the CHROME-2 shell
/// anchors (AC-1/AC-2) and the bs-17 component finders (AC-3..AC-10, AC-12).
class VisualHarness {
  VisualHarness(
    this.tester, {
    required this.screen,
    required this.speech,
    required this.haptics,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The surface the app was opened on.
  final VisualScreen screen;

  /// The recording speech sink injected into the app.
  final FakeSpeech speech;

  /// The recording haptics sink injected into the app.
  final FakeHaptics haptics;

  /// The single [ThemeData] installed on the app's [MaterialApp] — the one theme
  /// chokepoint every screen inherits (AC-11).
  ThemeData get installedTheme =>
      tester.widget<MaterialApp>(find.byType(MaterialApp).first).theme!;

  /// The installed [ColorScheme] (the nav / component token checks read it).
  ColorScheme get colorScheme => installedTheme.colorScheme;

  // --- CHROME-2 shell anchors (AC-1 / AC-2) -------------------------------

  /// The bottom navigation bar.
  Finder get bottomNav => find.byKey(AppShell.bottomNavKey);

  /// The non-colour active-destination marker (present once, under the selected
  /// item).
  Finder get activeDestination => find.byKey(AppShell.activeDestinationKey);

  /// The nav item for [destination], whatever its position or selected state.
  Finder navItem(AppDestination destination) =>
      find.byKey(destination.navItemKey);

  // --- bs-17 component finders (the component ACs anchor on these) ---------

  /// Every [PillButton] in the tree (AC-3/AC-6/AC-7/AC-8/AC-9/AC-10).
  Finder get pillButtons => find.byType(PillButton);

  /// Every [SpeakButton] in the tree (AC-5/AC-6 speak FAB).
  Finder get speakButtons => find.byType(SpeakButton);

  /// Every [SurfaceCard] in the tree (AC-5/AC-6/AC-7/AC-9/AC-10 carded regions).
  Finder get surfaceCards => find.byType(SurfaceCard);

  /// Every [MonoLabel] in the tree (AC-5/AC-7 mono eyebrows / notes).
  Finder get monoLabels => find.byType(MonoLabel);

  /// Every [ProvenanceBadge] in the tree (AC-8 per-row provenance signature).
  Finder get provenanceBadges => find.byType(ProvenanceBadge);

  /// Every swatch approximation caption in the tree (AC-12).
  Finder get swatchCaptions => find.byKey(SwatchCaption.captionKey);

  /// The screen-space rectangle of [finder] (AC-4 reads warning rects).
  Rect rectOf(Finder finder) => tester.getRect(finder);
}

// ---------------------------------------------------------------------------
// Pumps
// ---------------------------------------------------------------------------

/// Boots the app on the default route — the CHROME-2 nav shell — reading
/// [initialSample] (default [aReading]) on its opening Capture destination.
///
/// The fall-through entry (no capture source, no deep-link entry) is what lands
/// on [AppShell], so this is how AC-1/AC-2 reach the nav and top bar and AC-5
/// reaches the Readout.
Future<VisualHarness> pumpShell(
  WidgetTester tester, {
  Sample? initialSample,
}) {
  // The carded Readout (READ-3) renders taller than the short default test
  // surface, so its in-scroll actions bar — the compare / recipes handoffs AC-6
  // reads — sits below the fold on an 800px surface and a lazy [ListView] never
  // builds it. Pump the shell on a device-tall surface so every readout region
  // builds (the tall-surface gotcha, READ-3). AC-1/AC-2 (the Scaffold nav and
  // top bar) and AC-5 (the top-of-list cards and the FAB) are unaffected — a
  // taller surface only reveals more.
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return _pump(tester, VisualScreen.shell, initialSample: initialSample);
}

/// Opens the app on a deep-link [screen] through its `AppDependencies` entry
/// flag, wired with the matching fixture's source.
///
/// Mirrors the sibling design-system harness: a *fresh* app is pumped each call
/// (an empty frame first) so a repeated pump disposes the prior screen's state.
Future<VisualHarness> pumpScreen(WidgetTester tester, VisualScreen screen) =>
    _pump(tester, screen);

/// Opens the Recipes screen mixing toward [target] (default the fixture's
/// reachable target).
///
/// FLOW-2's AC-7 augmentation pumps the fixture's `outOfGamutTarget` through
/// this so the out-of-gamut note actually renders (the reachable target leaves
/// the banner collapsed), letting the test assert the ranked-by and
/// out-of-gamut notes render in the design-system mono style over one palette.
Future<VisualHarness> pumpRecipes(WidgetTester tester, {Sample? target}) =>
    _pump(tester, VisualScreen.recipes, recipesTarget: target);

Future<VisualHarness> _pump(
  WidgetTester tester,
  VisualScreen screen, {
  Sample? initialSample,
  Sample? recipesTarget,
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  await tester.pumpWidget(
    buildApp(_depsFor(screen, speech, haptics, initialSample, recipesTarget)),
  );
  await tester.pumpAndSettle();
  return VisualHarness(
    tester,
    screen: screen,
    speech: speech,
    haptics: haptics,
  );
}

/// The production dependencies that open the app on [screen] — the entry flag
/// for the screen, the matching fixture's source, and the faked platform sinks;
/// every other seam takes its production default (D-7).
AppDependencies _depsFor(
  VisualScreen screen,
  FakeSpeech speech,
  FakeHaptics haptics,
  Sample? initialSample,
  Sample? recipesTarget,
) {
  const science = ColorScienceImpl();
  switch (screen) {
    case VisualScreen.shell:
      return AppDependencies(
        colorScience: science,
        speech: speech,
        haptics: haptics,
        initialSample: initialSample ?? aReading,
      );
    case VisualScreen.capture:
      return AppDependencies(
        colorScience: science,
        speech: speech,
        haptics: haptics,
        captureSource:
            FakeCaptureSource(SceneSpec(groundTruth: aReading.coordinates)),
      );
    case VisualScreen.compare:
      return AppDependencies(
        colorScience: science,
        speech: speech,
        haptics: haptics,
        comparisonEntry: const ComparisonEntry(),
        sampleSource: aComparison.sampleSource,
      );
    case VisualScreen.recipes:
      return AppDependencies(
        colorScience: science,
        speech: speech,
        haptics: haptics,
        recipesEntry:
            RecipesEntry(target: recipesTarget ?? recipesForTarget.target),
        paletteSource: recipesForTarget.paletteSource,
      );
    case VisualScreen.palette:
      return AppDependencies(
        colorScience: science,
        speech: speech,
        haptics: haptics,
        paletteEntry: const PaletteEntry(),
        paletteSource: aPalette.paletteSource,
        projectSource: aProject.projectSource,
      );
    case VisualScreen.displaySettings:
    case VisualScreen.onboarding:
      throw StateError(
        '${screen.label} has no AppDependencies entry flag; pump it with '
        'pumpDisplaySettings / pumpOnboarding, not _pump.',
      );
  }
}

// ---------------------------------------------------------------------------
// CFG pumps (ITEST-3) — the Display settings panel and the onboarding host
// (AC-10), which have no `AppDependencies` entry flag (ITEST-1 handoff): the
// Display panel is opened through the app chrome's E2 entry present on every
// route, and the onboarding host is pushed onto the running app (its production
// route). Both boot the **real** assembled app through [buildApp] (D-7), so the
// one installed warm-paper theme is live and the design-system treatment is
// what the screen actually renders — exactly as the sibling bs-07 / bs-08
// harnesses reach these two surfaces.
// ---------------------------------------------------------------------------

/// Boots the app and opens the Display settings panel through its real E2 chrome
/// entry (AC-10), seeding the injected [DisplayController] from [settings] (the
/// CFG fixture's moderate-deutan snapshot by default) so the view controls have
/// a non-default state to render. The injected controller is owned here (an
/// injected controller is the injector's to dispose), so it is torn down after
/// the test.
Future<VisualHarness> pumpDisplaySettings(
  WidgetTester tester, {
  DisplaySettings? settings,
}) async {
  final resolved = settings ?? anOnboardingStep.displaySettings;
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final controller = DisplayController(
    defaultSimulationType: resolved.simulationType ?? CvdType.deutan,
    initialSettings: resolved,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        initialSample: aReading,
        displayController: controller,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Open the panel through the E2 entry the chrome shows on every route.
  await tester.tap(find.byKey(DisplaySettingsButton.openKey));
  await tester.pumpAndSettle();
  return VisualHarness(
    tester,
    screen: VisualScreen.displaySettings,
    speech: speech,
    haptics: haptics,
  );
}

/// Boots the app and pushes the onboarding / self-assessment host onto it
/// through its production route (AC-10), the way the bs-07 harness does — the
/// host has no home entry. An in-memory store backs the host's profile store,
/// and an [InactivePeerTransport] keeps the push deterministic (no real
/// local-network discovery, bs-14). The route future completes only on pop, so
/// it is intentionally not awaited.
Future<VisualHarness> pumpOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    initialSample: aReading,
    store: InMemoryPersistentStore(),
    peerTransport: const InactivePeerTransport(),
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  final navigator = tester.firstState<NavigatorState>(find.byType(Navigator));
  unawaited(navigator.push<void>(deps.router.toSelfAssessment()));
  await tester.pumpAndSettle();
  return VisualHarness(
    tester,
    screen: VisualScreen.onboarding,
    speech: speech,
    haptics: haptics,
  );
}

// ---------------------------------------------------------------------------
// Component assertions (ITEST-3) — the "design-system wrapper present" checks
// the AC-6..AC-10 pill ACs share. Placement-robust: a swap phase may put the
// control's key on the wrapper or on the inner button, so these accept the
// wrapper at, above or below the keyed control.
// ---------------------------------------------------------------------------

/// Whether [keyed]'s widget is a [T], or has a [T] ancestor or descendant.
///
/// [keyed] must resolve to exactly one widget (assert its presence first).
bool subtreeHas<T extends Widget>(WidgetTester tester, Finder keyed) =>
    tester.widget(keyed) is T ||
    find.ancestor(of: keyed, matching: find.byType(T)).evaluate().isNotEmpty ||
    find.descendant(of: keyed, matching: find.byType(T)).evaluate().isNotEmpty;

/// Asserts the control at [key] renders as a design-system [PillButton] (present
/// at, above or below the key), failing a control left as an ad-hoc button.
void expectPill(WidgetTester tester, Key key, {String? reason}) {
  final keyed = find.byKey(key);
  expect(keyed, findsOneWidget, reason: 'the $key control renders');
  expect(
    subtreeHas<PillButton>(tester, keyed),
    isTrue,
    reason: reason ?? 'the $key control renders as a design-system PillButton',
  );
}
