import 'package:flutter/foundation.dart';

import '../a11y/speech.dart';
import '../app/router.dart';
import '../capture/capture_controller.dart';
import '../capture/source/capture_source.dart';
import '../compare/sample_source.dart';
import '../domain/sample.dart';
import '../recipes/engine/mixing_engine.dart';
import '../recipes/engine/subtractive_engine.dart';
import '../recipes/palette_source.dart';
import 'correction_state.dart';
import 'engine/correction_engine.dart';

/// Drives the Correction screen: holds the correction [state] and offers the
/// actions the screen takes on it.
///
/// A [ChangeNotifier] so the screen and the acceptance read endpoint rebuild as
/// the state moves, mirroring bs-04's `RecipeController`. It is given the seams
/// the loop rides — the [captureSource] it photographs the swatch through
/// (reused from bs-02, D-2), the [correctionEngine] it reads the difference and
/// the correction from (D-2/D-3; the controller never computes that math
/// itself), the [paletteSource] the correction's additions are drawn from, the
/// [mixingEngine] the correction scores candidates through, the [sampleSource] a
/// confirmed mix is persisted to (D-8), and the [speech] sink — plus the typed
/// [router] and the mixing [target] / [currentMix] the loop corrects.
///
/// [checkMix] (LOOP-3) photographs the swatch and reads the difference; the
/// remaining painter *actions* ([rephotograph] / [speakCorrection] /
/// [saveConfirmed]) are declared here and throw until their behaviour phase
/// fills them, exactly as bs-04's recipe controller deferred its actions.
class CorrectionController extends ChangeNotifier {
  /// Creates a controller correcting [currentMix] toward [target], over the
  /// given seams.
  ///
  /// The initial [CorrectionState] carries [target] and [currentMix] with no
  /// checked swatch, difference, correction or saved provenance — the screen
  /// opens on the pre-check state until the painter checks the mix.
  CorrectionController({
    required this.captureSource,
    required Sample target,
    required Recipe currentMix,
    required this.paletteSource,
    required this.correctionEngine,
    this.mixingEngine = const SubtractiveMixingEngine(),
    this.sampleSource = const InMemorySampleSource(),
    this.speech = const NoopSpeech(),
    this.router = const AppRouter(),
  }) : _state = CorrectionState(target: target, currentMix: currentMix);

  /// The capture source the swatch is photographed through (bs-02 D-2); the
  /// check drives it to a measured [Sample].
  final CaptureSource captureSource;

  /// The owned palettes the correction's additions are drawn from (AC-4/AC-5).
  final PaletteSource paletteSource;

  /// The swappable engine the difference and the correction are read through
  /// (D-2/D-3); the controller never computes that math itself.
  final CorrectionEngine correctionEngine;

  /// The swappable mixing engine the correction scores candidate additions
  /// through (bs-04 reuse); carried for the behaviour phases' search.
  final MixingEngine mixingEngine;

  /// The saved-sample catalogue a confirmed mix is persisted to (D-8), reused
  /// from bs-03.
  final SampleSource sampleSource;

  /// Spoken-output sink the [speakCorrection] action drives (AC-7) — the same
  /// injected [Speech] seam bs-01's readout speaks through.
  final Speech speech;

  /// Typed navigation (e.g. to the confirmed value's Readout), injected by the
  /// app.
  final AppRouter router;

  // Reassigned through [_emit] as the painter acts: the check fills the swatch /
  // difference / correction (LOOP-3, CORRECT-2/3/4), a re-photograph replaces
  // them (LOOP-5), a save records the promoted provenance (LOOP-6).
  CorrectionState _state;

  /// The current observable correction state.
  CorrectionState get state => _state;

  /// The saved samples the loop can promote into (empty until seeded).
  List<Sample> get savedSamples => sampleSource.savedSamples();

  /// Photographs the mixed swatch and compares it to the target (AC-1).
  ///
  /// Drives the injected [captureSource] through a bs-02 [CaptureController] to a
  /// committed, *measured* [Sample] — the painter's own physical swatch read back
  /// as colour (D-2) — then reads how it differs from the [state] target through
  /// the [correctionEngine] (the controller never computes that colour maths
  /// itself, D-2/D-3). The measured swatch and its [Difference] land on the
  /// state, moving the screen from its pre-check state to the difference reading.
  /// A feed that yields no frame leaves the state untouched.
  ///
  /// Only the difference is read here: AC-1 needs the ΔE00, [CorrectionEngine]'s
  /// stub supplies it now and CORRECT-2 adds the verdict + value-leading
  /// decomposition. CORRECT-3 extends this check to also read the concrete
  /// [Correction] (so [speakCorrection]/the correction body have one to show).
  Future<void> checkMix() async {
    final capture = CaptureController(source: captureSource);
    try {
      // Let the finite live feed drain into the capture controller — its events
      // are microtasks, so a zero-delay timer resumes us only once they have all
      // been read — then commit the averaged reading as the measured swatch.
      await Future<void>.delayed(Duration.zero);
      capture.commit();
      final swatch = capture.state.lastCommittedSample;
      if (swatch == null) return;
      _emit(CorrectionState(
        target: _state.target,
        currentMix: _state.currentMix,
        mixedSwatch: swatch,
        difference: correctionEngine.difference(swatch, _state.target),
      ));
    } finally {
      capture.dispose();
    }
  }

  /// Re-photographs the swatch and re-checks it against the target (AC-8).
  ///
  /// The painter adjusts the physical mix and photographs again: this re-drives
  /// the [captureSource] through a fresh bs-02 [CaptureController] to a new,
  /// *measured* [Sample] — the same capture idiom [checkMix] rides (D-2) — then
  /// reads its [Difference] from the target through the [correctionEngine]
  /// (D-2/D-3). The new swatch and difference *replace* the prior ones on the
  /// state, so the loop re-runs in place: the screen moves from the first
  /// reading to the re-checked one. A feed that yields no frame leaves the state
  /// untouched.
  ///
  /// Like [checkMix], this reads the difference only and clears any prior
  /// [Correction] — a fresh photograph invalidates the old correction. Once
  /// CORRECT-3 extends the check to also compute the correction, this shares
  /// that path (the two can then be unified); until then a re-photograph, like a
  /// first check, leaves `state.correction` null.
  Future<void> rephotograph() async {
    final capture = CaptureController(source: captureSource);
    try {
      // Drain the finite live feed (microtask events) before committing the
      // averaged reading as the re-measured swatch — mirrors checkMix.
      await Future<void>.delayed(Duration.zero);
      capture.commit();
      final swatch = capture.state.lastCommittedSample;
      if (swatch == null) return;
      _emit(CorrectionState(
        target: _state.target,
        currentMix: _state.currentMix,
        mixedSwatch: swatch,
        difference: correctionEngine.difference(swatch, _state.target),
      ));
    } finally {
      capture.dispose();
    }
  }

  /// Speaks the difference and the paints to add as one utterance (AC-7) —
  /// LOOP-4.
  Future<void> speakCorrection() =>
      throw UnimplementedError(_deferred('LOOP-4'));

  /// Saves the mix as confirmed, promoting the value's provenance (AC-9) —
  /// LOOP-6.
  void saveConfirmed() => throw UnimplementedError(_deferred('LOOP-6'));

  /// Replaces the observable [state] and notifies listeners.
  ///
  /// The single mutation seam the behaviour actions move the state through (the
  /// bs-04 `RecipeController` pattern), so every transition rebuilds the screen
  /// and the acceptance read endpoint the same way.
  void _emit(CorrectionState next) {
    _state = next;
    notifyListeners();
  }

  static String _deferred(String phase) =>
      'CorrectionController is a shell (LOOP-2); this action lands in $phase.';
}
