import 'package:flutter/foundation.dart';

import '../a11y/speech.dart';
import '../app/router.dart';
import '../capture/capture_controller.dart';
import '../capture/source/capture_source.dart';
import '../compare/sample_source.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import '../recipes/engine/mixing_engine.dart';
import '../recipes/engine/subtractive_engine.dart';
import '../recipes/palette.dart';
import '../recipes/palette_source.dart';
import 'correction_speech.dart';
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

  // The mixes the painter has confirmed this session, promoted to the confirmed
  // tier (LOOP-6, AC-9). The injected [sampleSource] is the read-only bs-03 seam
  // (bs-06 later backs it with the persistent catalogue); until then a confirmed
  // mix is exposed here so [savedSamples] — and so a later readout (AC-10) —
  // carries it, the plan's sanctioned "or exposes it for the readout" path.
  final List<Sample> _confirmedSaves = [];

  /// The current observable correction state.
  CorrectionState get state => _state;

  /// The saved samples the loop reads and promotes into: the injected
  /// [sampleSource]'s catalogue plus the mixes confirmed this session (AC-9),
  /// read-only so callers cannot mutate either through it.
  List<Sample> get savedSamples => List<Sample>.unmodifiable(
        [...sampleSource.savedSamples(), ..._confirmedSaves],
      );

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
  /// Both the difference and the concrete correction are read here (CORRECT-3):
  /// the [Difference] (ΔE00 + verdict + value-leading decomposition, AC-2/AC-3)
  /// and the [Correction] — the paint(s) to add, drawn from the owned palette
  /// (AC-4/AC-5) — so the correction body and [speakCorrection] have one to
  /// show. The correction is searched over the painter's selected palette (the
  /// first palette the [paletteSource] lists; an empty catalogue yields no
  /// correction). The controller never computes that math itself (D-2/D-3).
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
        correction: correctionEngine.correct(
          swatch,
          _state.target,
          _state.currentMix,
          _selectedPalette(),
        ),
      ));
    } finally {
      capture.dispose();
    }
  }

  /// The palette the correction's additions are drawn from: the first palette
  /// the [paletteSource] lists, or an empty palette when the catalogue is empty
  /// (then the engine offers no correction).
  PaintPalette _selectedPalette() {
    final palettes = paletteSource.palettes();
    return palettes.isEmpty
        ? const PaintPalette(name: '', paints: [])
        : palettes.first;
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

  /// Speaks the difference and the paints to add as one utterance (AC-7).
  ///
  /// Builds the utterance from the checked [state] via [correctionSpeech] — the
  /// difference's verdict and value-leading decomposition followed by each paint
  /// to add — and sends it to [Speech.speak] exactly once, so the painter hears
  /// the whole correction as one utterance rather than a stream of fragments.
  /// The controller never phrases that output itself; the builder reuses the
  /// strings the difference and correction regions show, so heard and seen stay
  /// in step (D-2/D-3). With no reading yet ([correctionSpeech] null, the mix
  /// not checked) there is nothing to speak, so the action is inert — the E27
  /// control is disabled in that state anyway. Speaking does not change the
  /// reading, so it does not notify.
  Future<void> speakCorrection() async {
    final utterance = correctionSpeech(_state);
    if (utterance != null) await speech.speak(utterance);
  }

  /// Saves the mix as confirmed, promoting the value's provenance (AC-9).
  ///
  /// The painter is satisfied with the checked swatch and confirms it: the
  /// [state] target is promoted to [ProvenanceTier.confirmed] — the only path to
  /// that tier (SI; D-8) — carrying the [_confirmedNote] ("Confirmed — you
  /// measured this…", G-4(d)) and the measured swatch appended as an append-only
  /// [EvidencePoint] (D9), so a later readout reads the confirmed provenance
  /// (AC-10). The shared [Provenance.label] is left unchanged (G-4(d)); the
  /// painter-facing phrasing rides the note, rendered by the readout's provenance
  /// region. The confirmed sample is added to the saved catalogue the controller
  /// exposes (see [savedSamples]) and the promotion is recorded on the state.
  ///
  /// **Honest-provenance guard (D-8):** no value graduates to Confirmed without
  /// the painter's own measured swatch — a save before any check is inert (the
  /// E29 control is disabled in that state anyway), so nothing is promoted on
  /// anything but the painter's own photographic evidence.
  void saveConfirmed() {
    final swatch = _state.mixedSwatch;
    if (swatch == null) return;
    final target = _state.target;
    final confirmed = target.copyWith(
      provenance: const Provenance(
        ProvenanceTier.confirmed,
        note: _confirmedNote,
      ),
      evidence: [
        ...target.evidence,
        EvidencePoint(coordinates: swatch.coordinates, source: 'own swatch'),
      ],
    );
    _confirmedSaves.add(confirmed);
    _emit(CorrectionState(
      target: _state.target,
      currentMix: _state.currentMix,
      mixedSwatch: _state.mixedSwatch,
      difference: _state.difference,
      correction: _state.correction,
      savedProvenance: confirmed.provenance,
    ));
  }

  /// The note a confirmed mix carries (G-4(d) + D-8): the painter-facing
  /// "Confirmed — you measured this" phrasing, recording that it was confirmed
  /// after the painter photographed their own swatch. Carried on the
  /// [Provenance.note] (the shared tier [Provenance.label] stays "Confirmed",
  /// G-4(d)) and rendered by the readout's provenance region (AC-10).
  static const String _confirmedNote =
      'Confirmed — you measured this, after photographing your own swatch.';

  /// Replaces the observable [state] and notifies listeners.
  ///
  /// The single mutation seam the behaviour actions move the state through (the
  /// bs-04 `RecipeController` pattern), so every transition rebuilds the screen
  /// and the acceptance read endpoint the same way.
  void _emit(CorrectionState next) {
    _state = next;
    notifyListeners();
  }
}
