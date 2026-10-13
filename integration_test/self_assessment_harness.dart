// Acceptance-suite harness for bs-07 CVD self-assessment (onboarding) — ITEST-1.
//
// The Given/When/Then vocabulary, fixtures and independent references the AC
// tests (ITEST-2, ITEST-3) are written against. The suite drives the *real*
// assembled app through the single production `buildApp` entry and reaches the
// onboarding exactly the way production does — by pushing
// `AppRouter.toSelfAssessment()` (the route the bs-06 vision-profile card
// pushes). There is no `buildApp` home-entry for onboarding (it is reached by
// navigation, not launched into), so the harness navigates rather than inventing
// a new entry seam.
//
// Everything is real except the platform/infrastructure sinks — `FakeSpeech`,
// `FakeHaptics` (bs-01) and the in-memory `InMemoryPersistentStore` behind the
// production `CvdProfileStore` (PROFILE-1). No scoring/colour/ΔE00 maths is
// faked: the shipped `ColorScienceImpl` and `DichromatConfusionCheck` run, the
// real `OnboardingController` over the (shell) `AssessmentEngine` drives the
// flow, and AC-5/AC-9/AC-11 are graded against this harness's *own* independent
// references ([referenceBand] and the fixture axes) so no scorer is graded
// against itself.
//
// The pending gate (all 14 ACs → owning phase) lives in `bs07/pending.dart`
// (seeded in ENGINE-1); this harness re-exports it so an AC test imports only
// this file. The behaviour phases un-pend their AC by deleting its row there.
//
// Fixtures and vocabulary are lowerCamelCase (the plan's own fixture names), so
// no SCREAMING_CASE opt-out is needed here.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/onboarding/cvd_profile_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/engine/cvd_estimate.dart';
import 'package:paint_color_assistant/onboarding/engine/severity_band.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/onboarding_read_endpoint.dart';
import 'package:paint_color_assistant/onboarding/onboarding_state.dart';
import 'package:paint_color_assistant/onboarding/screens/arrangement_step.dart';
import 'package:paint_color_assistant/onboarding/screens/intake_step.dart';
import 'package:paint_color_assistant/onboarding/screens/lighting_step.dart';
import 'package:paint_color_assistant/onboarding/screens/onboarding_screen.dart';
import 'package:paint_color_assistant/onboarding/screens/progress_region.dart';
import 'package:paint_color_assistant/onboarding/screens/result_step.dart';
import 'package:paint_color_assistant/onboarding/screens/screening_step.dart';
import 'package:paint_color_assistant/onboarding/screens/threshold_step.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the fakes and the pending gate so an AC test imports only this file.
export 'bs07/pending.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// Small value-type inputs the AC scenarios run on. The scoring that turns them
// into results (presence/direction, severity, prior) lives behind the
// `AssessmentEngine` and is built by the behaviour phases (ENGINE-3..7); the
// fixtures fix only the inputs and the *independent* references the tests grade
// against, never the product function.
// ---------------------------------------------------------------------------

/// The intake question id the "reds/browns/greens mixed up?" item is asked under
/// (AC-3). Stable so an [IntakeAnswer] fixture and the wired question agree.
const String intakeConfusionQuestionId = 'rg-confusion';

/// The "Often" intake answer (AC-3): the red-green-leaning response whose
/// contribution to the starting prior ENGINE-3 folds in. Its [IntakeAnswer.value]
/// matches the intake step's "Often" button so [whenAnswerIntake] can drive it.
const IntakeAnswer intakeOften =
    IntakeAnswer(questionId: intakeConfusionQuestionId, value: 'Often');

/// The "Never" intake answer — the AC-3 control (it must move the prior the
/// other way, or not at all, where "Often" moves it toward red-green).
const IntakeAnswer intakeNever =
    IntakeAnswer(questionId: intakeConfusionQuestionId, value: 'Never');

/// The intake answer options for the Tier 1 question (AC-3). AC-3 uses
/// [intakeOften]; the control uses [intakeNever]. The prior-diagnosis path (AC-4)
/// reports a [CvdType] directly through `reportDiagnosis`, so it needs no answer
/// fixture — the test passes [CvdType.deutan] (control: [CvdType.protan]).
const List<IntakeAnswer> intakeAnswers = [
  intakeOften,
  IntakeAnswer(questionId: intakeConfusionQuestionId, value: 'Sometimes'),
  intakeNever,
];

/// A red-green–deficient plate set (AC-5): the painter misreads the red-green
/// plates and reads the blue-yellow ones correctly, so a correct scorer reports
/// present along [ScreeningDirection.redGreen].
const List<PlateResponse> screeningPlatesRedGreen = [
  PlateResponse(axis: ScreeningDirection.redGreen, correct: false),
  PlateResponse(axis: ScreeningDirection.redGreen, correct: false),
  PlateResponse(axis: ScreeningDirection.redGreen, correct: false),
  PlateResponse(axis: ScreeningDirection.blueYellow, correct: true),
  PlateResponse(axis: ScreeningDirection.blueYellow, correct: true),
];

/// A blue-yellow–deficient plate set — the AC-5 direction control (present along
/// [ScreeningDirection.blueYellow], not red-green).
const List<PlateResponse> screeningPlatesBlueYellow = [
  PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
  PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
  PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
  PlateResponse(axis: ScreeningDirection.blueYellow, correct: false),
  PlateResponse(axis: ScreeningDirection.blueYellow, correct: false),
];

/// A no-deficiency plate set — the AC-5 presence control (every plate read
/// correctly, so a correct scorer reports present == false). A full response
/// set over the screening deck (3 red-green + 2 blue-yellow, all correct).
const List<PlateResponse> screeningPlatesNone = [
  PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
  PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
  PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
  PlateResponse(axis: ScreeningDirection.blueYellow, correct: true),
  PlateResponse(axis: ScreeningDirection.blueYellow, correct: true),
];

/// The red-green plate set AC-5's main assertion drives (present + redGreen).
const List<PlateResponse> screeningPlates = screeningPlatesRedGreen;

/// The unordered colour-cap pool for the Tier 3 arrangement (AC-6/7/8): six cap
/// ids in a scrambled (non-hue) order, so "arrange them in hue order" is a real
/// reordering and placing a cap removes exactly it from the pool.
const List<int> capPool = [3, 0, 4, 1, 5, 2];

/// An easy-threshold probe sequence (AC-9 control): the painter detects even low
/// contrast, so a correct scorer returns a *lower* severity than
/// [thresholdProbesStrong].
const List<ThresholdProbe> thresholdProbesMild = [
  ThresholdProbe(contrast: 0.1, detected: true),
  ThresholdProbe(contrast: 0.15, detected: true),
  ThresholdProbe(contrast: 0.2, detected: true),
  ThresholdProbe(contrast: 0.25, detected: true),
];

/// A hard-threshold probe sequence (AC-9): the painter only detects high
/// contrast, so a correct scorer returns a *higher* severity than
/// [thresholdProbesMild] — the two together are AC-9's discriminating control.
const List<ThresholdProbe> thresholdProbesStrong = [
  ThresholdProbe(contrast: 0.2, detected: false),
  ThresholdProbe(contrast: 0.4, detected: false),
  ThresholdProbe(contrast: 0.6, detected: false),
  ThresholdProbe(contrast: 0.85, detected: true),
];

/// The probe sequence AC-9's main assertion drives.
const List<ThresholdProbe> thresholdProbe = thresholdProbesStrong;

/// An **independent** severity→band mapping to grade AC-11 against — the G-4
/// midpoint cut-offs (D-5: mild `[0,0.45)`, moderate `[0.45,0.75)`, strong
/// `[0.75,1.0]`), written here by hand so the AC-11 test never grades the product
/// `AssessmentEngine.band` against itself. The slider is 0..100 and the stored
/// severity is `slider/100`, so the example rows land at 0.30→mild, 0.60→moderate,
/// 0.90→strong.
SeverityBand referenceBand(double severity) {
  if (severity < 0.45) return SeverityBand.mild;
  if (severity < 0.75) return SeverityBand.moderate;
  return SeverityBand.strong;
}

/// A colour pair a deutan confuses, for proving the saved profile reconfigures
/// bs-03's `ConfusionCheck` (AC-13).
///
/// A red-green pair (equal L and b, opposite a) that normal vision sees as
/// clearly different (CIEDE2000 ≈ 33.9) but a deutan projection collapses. Its
/// confusability is sensitive to the deutan severity: measured against the
/// shipped `DichromatConfusionCheck`, it is confusable at a strong deutan profile
/// (severity ≈ 1.0, projected ΔE00 ≈ 2.8) and *not* at a moderate one
/// (severity ≈ 0.6, projected ΔE00 ≈ 15.7). So saving a measured profile changes
/// the verdict on this pair — AC-13's behavioural assertion (pinned by ITEST-2
/// and the PROFILE-2 augmentation, which choose the injected default so the save
/// flips it). The [typedef] record keeps the two coordinates together.
const FixedPair fixedPair = (
  a: ColorCoordinates(lightness: 50, a: 20, b: 18),
  b: ColorCoordinates(lightness: 50, a: -18, b: 18),
);

/// A colour pair for the confusion-reconfiguration check (AC-13).
typedef FixedPair = ({ColorCoordinates a, ColorCoordinates b});

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one self-assessment scenario.
///
/// Holds the recording sinks and the in-memory store the scenario injected, and
/// reaches the live state through the two read endpoints the onboarding host
/// mounts — [OnboardingReadEndpoint] (the assessment state) and
/// [CvdProfileReadEndpoint] (the persisted profile). The `when…` actions drive
/// the **real UI surface** (the keyed controls and labelled buttons); in the
/// shell those controls are inert, so each becomes live only in its behaviour
/// phase (named on the method), at which point its AC's test un-pends.
class SelfAssessmentHarness {
  SelfAssessmentHarness(
    this.tester, {
    required this.speech,
    required this.haptics,
    required this.store,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app.
  final FakeSpeech speech;

  /// The recording haptics sink injected into the app.
  final FakeHaptics haptics;

  /// The in-memory persistent store behind the production [CvdProfileStore]
  /// (starts empty; AC-13 writes exactly one profile through it).
  final InMemoryPersistentStore store;

  /// The live onboarding controller, read through the [OnboardingReadEndpoint]
  /// the host wraps its subtree in.
  OnboardingController get controller => tester
      .widget<OnboardingReadEndpoint>(
          find.byKey(OnboardingReadEndpoint.endpointKey))
      .controller;

  /// The live profile store, read through the [CvdProfileReadEndpoint].
  CvdProfileStore get profileStore => tester
      .widget<CvdProfileReadEndpoint>(
          find.byKey(CvdProfileReadEndpoint.endpointKey))
      .store;

  /// The current observable assessment state (the Then surface).
  OnboardingState get state => controller.state;

  /// The number of top-level progress steps (AC-14).
  int get stepTotal => controller.stepTotal;

  /// The current top-level step index, 0-based (AC-14).
  int get stepIndex => state.stepIndex;

  /// Whether all three Tier 0 lighting checks are confirmed (AC-2).
  bool get lightingConfirmed => state.lightingConfirmed;

  /// Whether testing has begun past the lighting gate (AC-2).
  bool get testingStarted => state.testingStarted;

  /// The Tier 1 starting prior (AC-3/AC-4).
  StartingPrior get prior => state.prior;

  /// The Tier 2 screening result, or null until scored (AC-5).
  ScreeningResult? get screening => state.screening;

  /// The Tier 3 caps not yet placed (AC-6/AC-7).
  List<int> get arrangementPool => state.arrangementPool;

  /// The Tier 3 caps placed so far, in order (AC-6/AC-7).
  List<int> get arrangedCaps => state.arrangedCaps;

  /// Whether the painter skipped the arrangement (AC-8).
  bool get arrangementSkipped => state.arrangementSkipped;

  /// The Tier 3 arrangement result, or null until the arrangement is completed;
  /// absent after a skip (AC-8).
  ArrangementResult? get arrangementResult => state.arrangementResult;

  /// The Tier 4 threshold result, or null until scored (AC-9).
  ThresholdResult? get threshold => state.threshold;

  /// The assembled estimate shown on the result step, or null until FLOW-5
  /// assembles it (AC-1/10/11/12).
  CvdEstimate? get estimate => state.estimate;

  /// The severity kept via the self-calibration slider, or null (AC-12).
  double? get calibratedSeverity => state.calibratedSeverity;

  /// Whether the approximate-estimate caveat is shown (AC-1).
  bool get caveatShown => state.caveatShown;

  /// Whether the profile has been saved to the store (AC-13).
  bool get saved => state.saved;

  /// How many profiles are persisted (0 or 1) — AC-13's "exactly one".
  Future<int> get profileCount => profileStore.count();

  /// The persisted profile, or null when none is saved (AC-13).
  Future<CvdProfile?> get savedProfile => profileStore.load();

  /// The progress indicator's text ("Step N of M"; AC-14).
  String get progressText =>
      tester.widget<Text>(find.byKey(ProgressRegion.regionKey)).data!;

  /// Confirms one Tier 0 lighting [check] by its checkbox (AC-2, wired FLOW-3).
  Future<void> whenConfirmLightingCheck(LightingCheck check) async {
    await tester.tap(find.descendant(
      of: find.byKey(LightingStep.regionKey),
      matching: find.widgetWithText(CheckboxListTile, _lightingTitles[check]!),
    ));
    await tester.pumpAndSettle();
  }

  /// Taps the lighting step's Continue control — E43 (AC-2/AC-14; wired
  /// FLOW-2/FLOW-3).
  Future<void> whenContinue() async {
    await tester.tap(find.byKey(LightingStep.continueKey));
    await tester.pumpAndSettle();
  }

  /// Answers the Tier 1 intake question with [value] (e.g. [intakeOften]'s
  /// "Often") by its labelled button (AC-3; wired ENGINE-3).
  Future<void> whenAnswerIntake(String value) async {
    await tester.tap(find.descendant(
      of: find.byKey(IntakeStep.regionKey),
      matching: find.widgetWithText(TextButton, value),
    ));
    await tester.pumpAndSettle();
  }

  /// Reports a prior clinical diagnosis of [type] (default deutan; control:
  /// protan) — opens the prior-diagnosis entry, then picks the type from the
  /// revealed picker, seeding the prior through `reportDiagnosis` (AC-4; wired
  /// ENGINE-4). The picker label is keyed off [IntakeStep.diagnosisTypeLabels]
  /// so the chosen [type] always finds its button.
  Future<void> whenReportDiagnosis({CvdType type = CvdType.deutan}) async {
    await tester.tap(find.descendant(
      of: find.byKey(IntakeStep.regionKey),
      matching: find.widgetWithText(TextButton, 'I have a diagnosis'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byKey(IntakeStep.regionKey),
      matching: find.widgetWithText(
          TextButton, IntakeStep.diagnosisTypeLabels[type]!),
    ));
    await tester.pumpAndSettle();
  }

  /// Completes the Tier 2 plate screening by reporting each plate in
  /// [responses] in order (AC-5; wired ENGINE-5).
  ///
  /// For each plate it taps the "I can read it" (correct) or "I can't read it"
  /// (incorrect) control, scrolling it into view first (the screening sits below
  /// the earlier steps in the shell's single scroll view). Once every plate in
  /// the deck is answered the controller scores the whole set. The plate at each
  /// index probes [ScreeningStep.plateDeck]'s axis there; [responses] are
  /// response sets over that deck (the harness fixtures), so the painter's
  /// read/can't-read choices drive the scoring while the axes stay the
  /// independent fixture axes.
  Future<void> whenScreenPlates(List<PlateResponse> responses) async {
    for (var i = 0; i < responses.length; i++) {
      final control = find.byKey(responses[i].correct
          ? ScreeningStep.readKey(i)
          : ScreeningStep.cantReadKey(i));
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
    }
  }

  /// Places the pooled Tier 3 cap [capId] into the next arranged position by
  /// tapping its control — E38 (AC-6/7; wired FLOW-4). Ensures the control is
  /// scrolled into view first (the arrangement sits below the earlier steps in
  /// the shell's single scroll view).
  Future<void> whenPlaceCap(int capId) async {
    final cap = find.byKey(ArrangementStep.capKey(capId));
    await tester.ensureVisible(cap);
    await tester.tap(cap);
    await tester.pumpAndSettle();
  }

  /// Returns every placed cap to the pool — E39 (AC-7; wired FLOW-4). Scrolls
  /// the control into view first (the arrangement sits below the earlier steps).
  Future<void> whenStartOver() async {
    final startOver = find.byKey(ArrangementStep.startOverKey);
    await tester.ensureVisible(startOver);
    await tester.tap(startOver);
    await tester.pumpAndSettle();
  }

  /// Skips the arrangement — E43 (AC-8; wired FLOW-4). Scrolls the control into
  /// view first (the arrangement sits below the earlier steps).
  Future<void> whenSkipArrangement() async {
    final skip = find.byKey(ArrangementStep.skipKey);
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }

  /// Answers one Tier 4 threshold probe — [detected] taps "I can see it", else
  /// "I can't see it" (AC-9; wired ENGINE-6). Scrolls the probe control into
  /// view first (the threshold step sits below the earlier steps in the shell's
  /// single scroll view, like the screening and arrangement drivers).
  Future<void> whenProbe({required bool detected}) async {
    final control = find.descendant(
      of: find.byKey(ThresholdStep.regionKey),
      matching: find.widgetWithText(
          TextButton, detected ? 'I can see it' : "I can't see it"),
    );
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Concludes the battery: taps "See my result" to assemble the estimate from
  /// whatever tiers ran and advance to the result step (FLOW-5 enabler). After
  /// this the result-step ACs (AC-1/10/11/12/13) observe the assembled
  /// [estimate]. Scrolls the control into view first (it sits below the earlier
  /// steps in the shell's single scroll view).
  Future<void> whenAdvanceToResult() async {
    final control = find.byKey(OnboardingScreen.seeResultKey);
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Selects [type] in the by-hand type picker on the result step — E40 (AC-10;
  /// wired FLOW-6). Taps the specific type choice so the Then can reject the
  /// wrong type among protan/deutan/tritan, not merely "stays deutan". Scrolls
  /// it into view first (the result step sits below the earlier steps).
  Future<void> whenAdjustType(CvdType type) async {
    final choice = find.byKey(ResultStep.typeChoiceKey(type));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
  }

  /// Sets the result severity slider to [value] on its 0..100 scale by tapping
  /// along its track — E41 (AC-11/AC-12; wired FLOW-7). Approximate until FLOW-7
  /// pins the control; the Then reads the resulting state, not the tap.
  Future<void> whenSetSeverity(double value) async {
    final slider = find.byKey(ResultStep.severityKey);
    final box = tester.getRect(slider);
    // Slider value runs left (0) → right (max 100) across the track width.
    final fraction = (value / 100).clamp(0.0, 1.0);
    final target = Offset(box.left + box.width * fraction, box.center.dy);
    await tester.tapAt(target);
    await tester.pumpAndSettle();
  }

  /// Saves the profile — E43 on the result step (AC-13; wired PROFILE-2).
  Future<void> whenSave() async {
    await tester.tap(find.byKey(ResultStep.saveKey));
    await tester.pumpAndSettle();
  }

  static const Map<LightingCheck, String> _lightingTitles = {
    LightingCheck.brightness: 'Screen brightness turned up',
    LightingCheck.nightLight: 'Night-light turned off',
    LightingCheck.daylight: 'In daylight',
  };
}

/// Opens the CVD self-assessment in the fully assembled app.
///
/// Builds the real app through the production `buildApp` entry (faking only the
/// platform sinks and backing the production [CvdProfileStore] with an empty
/// [InMemoryPersistentStore]), then reaches the onboarding the way the bs-06
/// vision-profile card does — by pushing `AppRouter.toSelfAssessment()` onto the
/// root navigator under the real `AppScope`, so the pushed [OnboardingHost]
/// resolves the injected store and mounts both read endpoints. [profile] is the
/// live `AppDependencies.cvdProfile` the confusion pipeline uses *before* a save
/// (AC-13); it defaults to the shipped deutan default. Returns a
/// [SelfAssessmentHarness] over the booted flow.
Future<SelfAssessmentHarness> givenSelfAssessment(
  WidgetTester tester, {
  CvdProfile profile = const CvdProfile(type: CvdType.deutan),
}) async {
  // Open a fresh app each time so a repeated given in one test disposes the
  // prior OnboardingHost State (its controller is built once in
  // didChangeDependencies) rather than reusing it.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final store = InMemoryPersistentStore();

  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    cvdProfile: profile,
    store: store,
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();

  // Reach the self-assessment the production way: the same route the
  // vision-profile card pushes (`AppRouter.toSelfAssessment()`), under the
  // AppScope buildApp wraps the MaterialApp in.
  final navigator = tester.firstState<NavigatorState>(find.byType(Navigator));
  // Not awaited: NavigatorState.push completes only when the route is *popped*,
  // so awaiting it would hang the given forever — pump the transition instead.
  unawaited(navigator.push<void>(deps.router.toSelfAssessment()));
  await tester.pumpAndSettle();

  return SelfAssessmentHarness(
    tester,
    speech: speech,
    haptics: haptics,
    store: store,
  );
}
