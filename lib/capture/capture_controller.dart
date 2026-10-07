import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../domain/color_coordinates.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import 'capture_accuracy.dart';
import 'capture_state.dart';
import 'source/capture_source.dart';
import 'source/frame.dart';
import 'source/sampling.dart';

/// Drives one capture: holds the [CaptureSource], exposes the observable
/// [CaptureState], and offers the actions the Capture screen takes on it.
///
/// The live feed is sampled passively into [CaptureState.currentSample]
/// (SOURCE-2); the painter *action* methods below are still deferred to their
/// behaviour phases and throw [UnimplementedError] until then. A
/// [ChangeNotifier] so the screen (and the acceptance read endpoint) can rebuild
/// as the state moves.
class CaptureController extends ChangeNotifier {
  /// Creates a controller reading from [source], starting in the default
  /// [CaptureState] (auto exposure, 5 px radius, approximate accuracy) and
  /// subscribing to the live feed so [CaptureState.currentSample] tracks the
  /// colour under the centre reticle (SOURCE-2).
  CaptureController({required this.source}) {
    _feed = source.frames.listen(_onFrame);
    _scheduleSettleTick();
  }

  /// The source of frames and camera controls this capture reads (D-2).
  final CaptureSource source;

  /// The live-feed subscription that drives [CaptureState.currentSample].
  late final StreamSubscription<Frame> _feed;

  bool _disposed = false;

  CaptureState _state = const CaptureState();

  /// The current observable capture state.
  CaptureState get state => _state;

  /// Advances the stability settling counter one step per rendered frame while
  /// the reading is unlocked and not yet stable (AC-5): the painter watches
  /// "SETTLING n/12" climb as the live view runs under auto exposure. Each frame
  /// the camera settles a little more, so the counter tracks rendered frames up
  /// to [kStabilityFrameTarget]; it stops once the reading is stable or [lock]
  /// has settled it, and never restarts (a settled reading stays settled).
  void _scheduleSettleTick() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      if (_state.lockState == LockState.auto && !_state.isStable) {
        emit(_state.copyWith(stabilityCount: _state.stabilityCount + 1));
        _scheduleSettleTick();
      }
    });
  }

  /// Whether the reading has been switched to an imported photo (AC-9).
  ///
  /// Set once [importPhoto] samples a staged photo; while true the live feed no
  /// longer drives [_onFrame], so the sampled point P of the photograph stands
  /// instead of the camera colour.
  bool _photoImported = false;

  /// The most recent live frames, newest last, capped at [kStabilityFrameTarget]
  /// — the window a [commit] averages over so the committed colour is the mean
  /// of several settled frames rather than one noisy frame (AC-11). Bounded so a
  /// live feed never grows it without limit.
  final List<Frame> _recentFrames = <Frame>[];

  /// Samples the colour under the centre reticle of each live frame at the
  /// current radius and publishes it as [CaptureState.currentSample] (AC-2).
  ///
  /// The feed drives the reading passively — no painter action is needed; the
  /// radius selector (SCREEN-2) changes which disc is averaged. Once a photo has
  /// been imported ([importPhoto]) the feed no longer overwrites the reading.
  void _onFrame(Frame frame) {
    if (_photoImported) return;
    // Buffer the frame for the multi-frame commit (AC-11), keeping only the most
    // recent window so a live feed cannot grow the buffer unboundedly.
    _recentFrames.add(frame);
    if (_recentFrames.length > kStabilityFrameTarget) {
      _recentFrames.removeAt(0);
    }
    final coordinates = sampleAreaAverage(
      frame,
      frame.width ~/ 2,
      frame.height ~/ 2,
      radiusPx: _state.radiusPx,
    );
    emit(_state.copyWith(
      currentSample: Sample(
        coordinates: coordinates,
        provenance: const Provenance(ProvenanceTier.measured),
        accuracy: _state.accuracy,
      ),
    ));
  }

  /// Samples the gallery photo imported into the [source] at its chosen point P
  /// and publishes it as [CaptureState.currentSample], switching the reading off
  /// the live feed (AC-9).
  ///
  /// A no-op when no photo has been imported. The sample is a measured reading
  /// at the current accuracy, exactly like a live-feed read, but taken over the
  /// imported image at point P rather than the camera centre; once it lands the
  /// live feed no longer overwrites it.
  void importPhoto() {
    final photo = source.importedPhoto;
    if (photo == null) return;
    _photoImported = true;
    final coordinates = sampleFromPhoto(
      photo.image,
      photo.pointX,
      photo.pointY,
      radiusPx: _state.radiusPx,
    );
    emit(_state.copyWith(
      currentSample: Sample(
        coordinates: coordinates,
        provenance: const Provenance(ProvenanceTier.measured),
        accuracy: _state.accuracy,
      ),
    ));
  }

  /// Locks AE, AWB and AF together so the reading settles to "STABLE 12/12"
  /// (AC-4): the source locks all three, the indicator reads
  /// "AE · AWB · AF LOCKED" and the stability reading completes to
  /// "STABLE 12/12" at once (locking is the painter settling the reading).
  void lock() {
    source.lockExposure();
    source.lockWhiteBalance();
    source.lockFocus();
    emit(_state.copyWith(
      lockState: LockState.locked,
      stabilityCount: kStabilityFrameTarget,
    ));
  }

  /// Sets the area-average sampling [radiusPx] (1 / 5 / 21 px — AC-3). Behaviour
  /// lands in SCREEN-2 (the selector) over SOURCE-2's radius-driven sampling.
  void setRadius(int radiusPx) =>
      throw UnimplementedError('setRadius: behaviour lands in SCREEN-2');

  /// Normalises the current reading against a reference card and upgrades the
  /// stated accuracy to [CaptureAccuracy.calibrated] (AC-8).
  ///
  /// A no-op when no reference card is in view ([CaptureSource.referenceCardPresent]
  /// is false): without a card there is nothing to normalise against, so the
  /// reading stays at its card-less tier. With a card present, the source
  /// corrects the reading toward ground truth (within the calibrated tier's
  /// ΔE00 3) and the stated accuracy is upgraded to [CaptureAccuracy.calibrated];
  /// the live feed has already drained into [CaptureState.currentSample], so the
  /// correction lands on that reading and the next [commit] carries it. The
  /// accuracy upgrades even before any colour has been sampled, so the painter
  /// sees the calibrated tier the moment the card is read.
  void calibrate() {
    if (!source.referenceCardPresent) return;
    final reading = _state.currentSample;
    emit(_state.copyWith(
      accuracy: CaptureAccuracy.calibrated,
      currentSample: reading == null ? null : _normalisedAgainstCard(reading),
    ));
  }

  /// [reading] corrected toward ground truth by the source's reference card and
  /// stamped with the upgraded [CaptureAccuracy.calibrated] tier.
  Sample _normalisedAgainstCard(Sample reading) => reading.copyWith(
        coordinates: source.normaliseAgainstCard(reading.coordinates),
        accuracy: CaptureAccuracy.calibrated,
      );

  /// Clears the low-light warning without changing the stated accuracy (AC-7).
  ///
  /// Dismissing the warning is a purely visual acknowledgement: it hides the
  /// low-light notice but leaves [CaptureState.accuracy] (and any already
  /// committed sample's accuracy) exactly as it was — a dim reading stays
  /// approximate after the painter waves the warning away.
  void dismissWarning() => emit(_state.copyWith(lowLightWarning: false));

  /// Toggles the value-only grayscale preview (AC-10). Behaviour lands in
  /// SCREEN-3.
  void toggleValueOnly() =>
      throw UnimplementedError('toggleValueOnly: behaviour lands in SCREEN-3');

  /// Commits the reading as [CaptureState.lastCommittedSample], stamped with the
  /// stated [CaptureState.accuracy] tier and marked [Sample.justCaptured] so the
  /// Readout confirms with a haptic as it lands (bs-01 AC-12).
  ///
  /// The committed colour is the mean of the recent settled frames
  /// ([averageFrames] over [_recentFrames]), not one noisy frame, so per-frame
  /// camera noise averages out (AC-11); [CaptureState.framesAveraged] records how
  /// many frames went in. When the reading is calibrated the averaged colour is
  /// normalised against the reference card exactly as the live reading was
  /// (AC-8). A reading taken from an imported photo (AC-9) is a single point
  /// sample, not a live average, so it commits as it stands.
  ///
  /// A capture is **downgraded, never refused** (D-3): when the source reports
  /// [Lighting.low] the commit still lands a sample and raises the low-light
  /// warning, marking the reading approximate; in adequate light the warning
  /// stays clear. A no-op before any colour has been sampled. The confirm haptic
  /// and the Readout handoff ride on [Sample.justCaptured] through the router's
  /// `toReadout` (D-5), fired by the Capture home screen on an adequate-light
  /// commit.
  void commit() {
    final reading = _state.currentSample;
    if (reading == null) return;
    final ColorCoordinates coordinates;
    final int framesAveraged;
    if (_photoImported) {
      coordinates = reading.coordinates;
      framesAveraged = 1;
    } else {
      final averaged = averageFrames(_recentFrames);
      final mean = sampleAreaAverage(
        averaged,
        averaged.width ~/ 2,
        averaged.height ~/ 2,
        radiusPx: _state.radiusPx,
      );
      coordinates = _state.accuracy == CaptureAccuracy.calibrated
          ? source.normaliseAgainstCard(mean)
          : mean;
      framesAveraged = _recentFrames.length;
    }
    emit(_state.copyWith(
      lastCommittedSample: Sample(
        coordinates: coordinates,
        provenance: const Provenance(ProvenanceTier.measured),
        accuracy: _state.accuracy,
        justCaptured: true,
      ),
      framesAveraged: framesAveraged,
      lowLightWarning: source.lighting == Lighting.low,
    ));
  }

  /// Replaces the observable state and notifies listeners.
  ///
  /// The single mutation seam the behaviour phases move state through, so every
  /// transition notifies the screen the same way. A no-op when [next] equals the
  /// current state.
  @protected
  void emit(CaptureState next) {
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _feed.cancel();
    super.dispose();
  }
}
