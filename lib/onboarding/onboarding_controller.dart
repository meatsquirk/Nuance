import 'package:flutter/widgets.dart';

import '../a11y/cvd/cvd_profile.dart';
import '../store/cvd_profile_store.dart';
import 'engine/assessment_engine.dart';
import 'engine/tier_results.dart';
import 'onboarding_state.dart';
import 'onboarding_steps.dart';

/// Drives the self-assessment onboarding: holds the observable
/// [OnboardingState], the ordered progress [steps], and offers the actions each
/// step takes on the flow.
///
/// The onboarding screens are a pure view over this controller (read through
/// `OnboardingReadEndpoint`). All scoring lives behind the injected
/// [AssessmentEngine] (D-9) — the controller never computes a score itself; the
/// save lands through the injected [CvdProfileStore] (PROFILE-2).
///
/// A [ChangeNotifier] so the screens and the acceptance read endpoint rebuild as
/// the state moves. FLOW-1 (shell) fixes the interface: the painter *action*
/// methods below are declared here and **throw [UnimplementedError]** until
/// their behaviour phase fills them (exactly as bs-02's capture controller and
/// bs-03's comparison controller deferred their actions), and the step widgets
/// render their controls inert until then. Each method names the phase that
/// wires it.
class OnboardingController extends ChangeNotifier {
  /// Creates a controller over [engine] (the scoring seam) and the optional
  /// [profileStore] (the save seam), starting in the default empty
  /// [OnboardingState] with the given progress [steps] (the provisional four by
  /// default, pinned at FLOW-2).
  OnboardingController({
    this.engine = const ShellAssessmentEngine(),
    this.profileStore,
    this.steps = defaultOnboardingSteps,
  });

  /// The scoring engine every tier is scored through (D-9). Held so the
  /// behaviour phases (ENGINE-3..7, FLOW-5) call it rather than computing in the
  /// controller; unused by the shell actions, which throw.
  final AssessmentEngine engine;

  /// The store the saved profile is written to (AC-13). Null when no persistence
  /// is wired; PROFILE-2 writes the assessed estimate through it.
  final CvdProfileStore? profileStore;

  /// The ordered top-level steps the progress indicator counts (AC-14).
  final List<OnboardingStep> steps;

  // Mutable from FLOW-2 on: the step-advance and tier actions replace the state
  // and notify listeners. The shell never reassigns it — every action below
  // throws until its behaviour phase fills it — so the analyzer sees a field it
  // could make final; it is deliberately left mutable for those phases.
  // ignore: prefer_final_fields
  OnboardingState _state = const OnboardingState();

  /// The Tier 1 intake answers recorded so far, at most one per question
  /// (ENGINE-3). Re-answering a question replaces its earlier answer;
  /// [answerIntake] folds the whole set through [engine] into the prior.
  final List<IntakeAnswer> _intakeAnswers = [];

  /// The current observable onboarding state.
  OnboardingState get state => _state;

  /// The number of top-level steps — the total AC-14 shows the current step
  /// against ("… of four"). Provisional until G-5/FLOW-2.
  int get stepTotal => steps.length;

  /// Confirms (or clears) one of the Tier 0 lighting checks (brightness /
  /// night-light off / daylight) — FLOW-3 (AC-2) tracks the three; all three
  /// confirmed opens the continue gate ([OnboardingState.lightingConfirmed]).
  void confirmLightingCheck(LightingCheck check, {bool confirmed = true}) {
    switch (check) {
      case LightingCheck.brightness:
        _state = _state.copyWith(brightnessConfirmed: confirmed);
      case LightingCheck.nightLight:
        _state = _state.copyWith(nightLightConfirmed: confirmed);
      case LightingCheck.daylight:
        _state = _state.copyWith(daylightConfirmed: confirmed);
    }
    notifyListeners();
  }

  /// Tries to advance past the current step — FLOW-3 gates the Tier 0 → testing
  /// transition on the three lighting checks (AC-2): a Continue with the checks
  /// unconfirmed is a no-op (testing does not begin); once all three are
  /// confirmed it advances to the next step and marks testing started. FLOW-2
  /// generalises the step advance across the later steps (AC-14).
  void tryContinue() {
    if (!_state.lightingConfirmed) return;
    final next = _state.stepIndex + 1;
    _state = _state.copyWith(
      stepIndex: next < stepTotal ? next : _state.stepIndex,
      testingStarted: true,
    );
    notifyListeners();
  }

  /// Records a Tier 1 intake [answer] toward the starting prior (AC-3).
  ///
  /// Keeps the latest answer per question (re-answering replaces the earlier
  /// one), folds the whole intake set through [engine] into the new
  /// [OnboardingState.prior], and notifies listeners. The scoring itself lives
  /// in [engine] (D-9) — the controller only records the answer and holds the
  /// result.
  void answerIntake(IntakeAnswer answer) {
    _intakeAnswers
      ..removeWhere((a) => a.questionId == answer.questionId)
      ..add(answer);
    _state = _state.copyWith(prior: engine.recordIntake(_intakeAnswers));
    notifyListeners();
  }

  /// Seeds the prior from a reported prior clinical diagnosis — ENGINE-4 folds
  /// it through [engine] (AC-4).
  void reportDiagnosis(CvdType type) =>
      throw UnimplementedError('reportDiagnosis is wired in ENGINE-4 (AC-4)');

  /// Scores the Tier 2 screening responses — ENGINE-5 scores them through
  /// [engine] into presence + direction (AC-5).
  void scoreScreening(List<PlateResponse> responses) =>
      throw UnimplementedError('scoreScreening is wired in ENGINE-5 (AC-5)');

  /// Places the Tier 3 cap [capId] into the next arranged position — FLOW-4
  /// moves it from the pool to the arrangement (AC-6).
  void placeCap(int capId) =>
      throw UnimplementedError('placeCap is wired in FLOW-4 (AC-6)');

  /// Returns every placed cap to the pool — FLOW-4 clears the arrangement
  /// (AC-7).
  void startOver() =>
      throw UnimplementedError('startOver is wired in FLOW-4 (AC-7)');

  /// Skips the arrangement so it contributes no result — FLOW-4 continues
  /// without it (AC-8).
  void skipArrangement() =>
      throw UnimplementedError('skipArrangement is wired in FLOW-4 (AC-8)');

  /// Scores the Tier 4 threshold probes — ENGINE-6 scores them through [engine]
  /// into a severity on the confusion line (AC-9).
  void scoreThreshold(List<ThresholdProbe> probes) =>
      throw UnimplementedError('scoreThreshold is wired in ENGINE-6 (AC-9)');

  /// Assembles the available tier results into an estimate and advances to the
  /// result step — FLOW-5 (the enabler) folds them through [engine].
  void advanceToResult() =>
      throw UnimplementedError('advanceToResult is wired in FLOW-5');

  /// Overrides the estimated type by hand on the result step — FLOW-6 (AC-10).
  void setType(CvdType type) =>
      throw UnimplementedError('setType is wired in FLOW-6 (AC-10)');

  /// Sets the result severity (0..1) from the slider — FLOW-7 re-renders the
  /// simulated/original pair and the band (AC-11/AC-12).
  void setSeverity(double severity) =>
      throw UnimplementedError('setSeverity is wired in FLOW-7 (AC-12)');

  /// Keeps the chosen severity as the subjective self-calibration — FLOW-7
  /// (AC-12).
  void confirmCalibration() =>
      throw UnimplementedError('confirmCalibration is wired in FLOW-7 (AC-12)');

  /// Projects the estimate onto a `CvdProfile` and saves it through
  /// [profileStore], configuring the pipeline — PROFILE-2 (AC-13).
  Future<void> save() =>
      throw UnimplementedError('save is wired in PROFILE-2 (AC-13)');
}

/// The three Tier 0 lighting checks the painter confirms before testing (AC-2).
///
/// Named so FLOW-3's `confirmLightingCheck` can set the matching
/// [OnboardingState] flag without positional ambiguity.
enum LightingCheck {
  /// Screen brightness is turned up.
  brightness,

  /// The device night-light / warm filter is off.
  nightLight,

  /// The painter is in daylight (or matched lighting).
  daylight,
}
