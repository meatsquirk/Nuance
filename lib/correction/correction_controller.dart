import 'package:flutter/foundation.dart';

import '../a11y/speech.dart';
import '../app/router.dart';
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
/// This is the LOOP-2 **shell**: it establishes the state shape, the seams and
/// the read getter, but every painter *action* ([checkMix] / [rephotograph] /
/// [speakCorrection] / [saveConfirmed]) is declared here and throws until its
/// behaviour phase fills it — exactly as bs-04's recipe controller deferred its
/// actions. No photography, comparison, speech or save happens yet.
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

  // Reassigned by the behaviour phases: the check fills the swatch / difference
  // / correction (LOOP-3, CORRECT-2/3/4), a re-photograph replaces them
  // (LOOP-5), a save records the promoted provenance (LOOP-6). Only assigned
  // once in this inert shell, hence the ignore — it is not final by design.
  // ignore: prefer_final_fields
  CorrectionState _state;

  /// The current observable correction state.
  CorrectionState get state => _state;

  /// The saved samples the loop can promote into (empty until seeded).
  List<Sample> get savedSamples => sampleSource.savedSamples();

  // --- Actions deferred to the behaviour phases (inert in this shell) ---
  //
  // Each throws until its phase fills it; the phase that adds the first real
  // mutation also adds the private emit/notify path these will route through.

  /// Photographs the mixed swatch and compares it to the target (AC-1) —
  /// LOOP-3.
  Future<void> checkMix() => throw UnimplementedError(_deferred('LOOP-3'));

  /// Re-photographs the swatch and re-checks it against the target (AC-8) —
  /// LOOP-5.
  Future<void> rephotograph() => throw UnimplementedError(_deferred('LOOP-5'));

  /// Speaks the difference and the paints to add as one utterance (AC-7) —
  /// LOOP-4.
  Future<void> speakCorrection() =>
      throw UnimplementedError(_deferred('LOOP-4'));

  /// Saves the mix as confirmed, promoting the value's provenance (AC-9) —
  /// LOOP-6.
  void saveConfirmed() => throw UnimplementedError(_deferred('LOOP-6'));

  static String _deferred(String phase) =>
      'CorrectionController is a shell (LOOP-2); this action lands in $phase.';
}
