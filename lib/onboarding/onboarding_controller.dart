import 'package:flutter/widgets.dart';

import '../a11y/cvd/cvd_profile.dart';
import '../store/cvd_profile_store.dart';
import 'engine/assessment_engine.dart';
import 'engine/cvd_estimate.dart';
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
    this.onProfileSaved,
    this.steps = defaultOnboardingSteps,
  });

  /// The scoring engine every tier is scored through (D-9). Held so the
  /// behaviour phases (ENGINE-3..7, FLOW-5) call it rather than computing in the
  /// controller; unused by the shell actions, which throw.
  final AssessmentEngine engine;

  /// The store the saved profile is written to (AC-13). Null when no persistence
  /// is wired; PROFILE-2 writes the assessed estimate through it.
  final CvdProfileStore? profileStore;

  /// Called after [save] persists the profile, with the saved [CvdProfile], so
  /// the app reconfigures the live pipeline (AC-13, D-3). Null when no live
  /// dependency is wired (a bare controller / unit test); the production host
  /// wires it to update the live `AppDependencies.cvdProfile` — the single seam
  /// bs-03's `ConfusionCheck` and the bs-08/bs-10 projection read (D-8).
  final ValueChanged<CvdProfile>? onProfileSaved;

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

  /// Seeds the prior from a reported prior clinical diagnosis (AC-4).
  ///
  /// A reported diagnosis is authoritative, so it folds through [engine]
  /// ([AssessmentEngine.seedFromDiagnosis]) and replaces the whole
  /// [OnboardingState.prior] with the diagnosis-seeded one (overriding any lean
  /// the intake questions had formed), then notifies. The scoring lives in
  /// [engine] (D-9) — the controller only holds the result.
  void reportDiagnosis(CvdType type) {
    _state = _state.copyWith(prior: engine.seedFromDiagnosis(type));
    notifyListeners();
  }

  /// Scores the Tier 2 screening [responses] into presence + direction (AC-5).
  ///
  /// Folds the per-plate responses through [engine]
  /// ([AssessmentEngine.scoreScreening]) and holds the [ScreeningResult] on
  /// [OnboardingState.screening], then notifies. The scoring lives in [engine]
  /// (D-9) — the controller only passes the responses and holds the result.
  void scoreScreening(List<PlateResponse> responses) {
    _state = _state.copyWith(screening: engine.scoreScreening(responses));
    notifyListeners();
  }

  /// Places the Tier 3 cap [capId] into the next arranged position (AC-6).
  ///
  /// Moves [capId] out of [OnboardingState.arrangementPool] and onto the end of
  /// [OnboardingState.arrangedCaps], then notifies. A cap that is not in the
  /// pool — already placed, or not one of the caps — is a no-op (no move, no
  /// notify), so the arrangement never holds a duplicate and a stale tap can't
  /// corrupt the order.
  void placeCap(int capId) {
    if (!_state.arrangementPool.contains(capId)) return;
    _state = _state.copyWith(
      arrangementPool: [..._state.arrangementPool]..remove(capId),
      arrangedCaps: [..._state.arrangedCaps, capId],
    );
    notifyListeners();
  }

  /// Returns every placed cap to the pool and empties the arrangement — the
  /// painter starts the arrangement over (AC-7).
  ///
  /// Resets the pool to the full [arrangementCaps] and clears
  /// [OnboardingState.arrangedCaps], so no placement survives, then notifies.
  void startOver() {
    _state = _state.copyWith(
      arrangementPool: arrangementCaps,
      arrangedCaps: const [],
    );
    notifyListeners();
  }

  /// Skips the arrangement so it contributes no result — the flow continues
  /// without an arrangement result (AC-8).
  ///
  /// Marks [OnboardingState.arrangementSkipped], which leaves
  /// [OnboardingState.arrangementResult] absent (a skip records no result),
  /// then notifies.
  void skipArrangement() {
    _state = _state.copyWith(arrangementSkipped: true);
    notifyListeners();
  }

  /// Scores the Tier 4 threshold probes into a severity on the confusion line
  /// (AC-9).
  ///
  /// Folds the per-probe responses through [engine]
  /// ([AssessmentEngine.scoreThreshold]) and holds the [ThresholdResult] on
  /// [OnboardingState.threshold], then notifies. The scoring lives in [engine]
  /// (D-9) — the controller only passes the probes and holds the result.
  void scoreThreshold(List<ThresholdProbe> probes) {
    _state = _state.copyWith(threshold: engine.scoreThreshold(probes));
    notifyListeners();
  }

  /// Assembles the available tier results into an estimate and advances to the
  /// result step — FLOW-5 (the enabler, D-7).
  ///
  /// Folds the current prior and whatever tier results are present (the Tier 2
  /// [OnboardingState.screening], the completed Tier 3
  /// [OnboardingState.arrangementResult] — absent after a skip — and the Tier 4
  /// [OnboardingState.threshold]) through [engine] into a single
  /// [OnboardingState.estimate], then moves to the last top-level step (the
  /// result step) and notifies. The scoring lives in [engine] (D-9); the
  /// controller only gathers the tier state and advances. A result is always
  /// reachable even when a tier was skipped (AC-8) — `assemble` stands in the
  /// defaults for a tier never run. The result adjustments (FLOW-6/7/8) refine
  /// the assembled estimate from here.
  ///
  /// Reaching the result is when the result is *shown*, so this also raises
  /// [OnboardingState.caveatShown] — the result carries the approximate-estimate
  /// caveat and the clinical-anomaloscope recommendation the step renders
  /// (FLOW-8, AC-1): the estimate never appears without the caveat beside it.
  void advanceToResult() {
    _state = _state.copyWith(
      estimate: engine.assemble(
        prior: _state.prior,
        screening: _state.screening,
        arrangement: _state.arrangementResult,
        threshold: _state.threshold,
      ),
      stepIndex: steps.length - 1,
      caveatShown: true,
    );
    notifyListeners();
  }

  /// Overrides the estimated [type] by hand on the result step — FLOW-6
  /// (AC-10).
  ///
  /// Replaces the assembled estimate's [CvdEstimate.type] with the painter's
  /// chosen one, regardless of what the tiers computed, keeping the rest of the
  /// estimate (severity, prior, per-tier evidence) intact, then notifies. A
  /// no-op before the estimate is assembled (no result step yet) — the result
  /// step is the only place the control is live, so this guards a stray call.
  void setType(CvdType type) {
    final estimate = _state.estimate;
    if (estimate == null) return;
    _state = _state.copyWith(
      estimate: CvdEstimate(
        type: type,
        severity: estimate.severity,
        prior: estimate.prior,
        screening: estimate.screening,
        threshold: estimate.threshold,
        arrangementPresent: estimate.arrangementPresent,
      ),
    );
    notifyListeners();
  }

  /// Keeps the painter's chosen [severity] (0..1) from the result slider as the
  /// subjective self-calibration — FLOW-7 (AC-12).
  ///
  /// The result step reads this back as `calibratedSeverity ?? estimate.severity`
  /// for the slider position, the simulated/original pair and the plain-language
  /// band, so moving the slider re-renders all three live — the chosen severity
  /// *is* the kept calibration. Clamped to 0..1 to match `CvdProfile.severity`.
  /// A no-op (no notify) before the estimate is assembled: the result step is
  /// the only place the slider is live, so this guards a stray call.
  void setSeverity(double severity) {
    if (_state.estimate == null) return;
    _state = _state.copyWith(calibratedSeverity: severity.clamp(0.0, 1.0));
    notifyListeners();
  }

  /// Finalises the self-calibration once the painter settles the slider — FLOW-7
  /// (AC-12).
  ///
  /// If the painter never moved the slider ([OnboardingState.calibratedSeverity]
  /// still null), the assembled estimate's own severity is kept as the
  /// calibration, so a confirmed result always carries a kept severity — the
  /// value that becomes the profile severity (D-6). Idempotent: a value already
  /// set by [setSeverity] stands (no notify). A no-op before the estimate is
  /// assembled.
  void confirmCalibration() {
    final estimate = _state.estimate;
    if (estimate == null) return;
    if (_state.calibratedSeverity != null) return;
    _state = _state.copyWith(calibratedSeverity: estimate.severity);
    notifyListeners();
  }

  /// Projects the assembled estimate onto a `CvdProfile`, saves it through
  /// [profileStore] and reconfigures the live pipeline — PROFILE-2 (AC-13).
  ///
  /// Projects the result the painter confirmed: the (possibly by-hand overridden,
  /// FLOW-6) [CvdEstimate.type] and the kept self-calibration
  /// ([OnboardingState.calibratedSeverity]) — which *is* the profile severity
  /// (D-6) — falling back to the assembled [CvdEstimate.severity] when the slider
  /// was never moved. Writes exactly one document through [profileStore] (AC-13's
  /// "exactly one"), marks the flow [OnboardingState.saved], and hands the saved
  /// profile to [onProfileSaved] so the live `AppDependencies.cvdProfile` — the
  /// single seam bs-03's `ConfusionCheck` and the bs-08/bs-10 projection read
  /// (D-8) — is reconfigured off the default immediately. A no-op before the
  /// estimate is assembled (no result step yet), guarding a stray call like the
  /// other result actions.
  Future<void> save() async {
    final estimate = _state.estimate;
    if (estimate == null) return;
    final profile = CvdProfile(
      type: estimate.type,
      severity: _state.calibratedSeverity ?? estimate.severity,
    );
    await profileStore?.save(profile);
    _state = _state.copyWith(saved: true);
    onProfileSaved?.call(profile);
    notifyListeners();
  }
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
