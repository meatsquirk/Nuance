import 'dart:async';

import 'package:flutter/scheduler.dart';
// `widgets.dart` (for `Widget`, VIEW-5's preview seam) also exports a
// `LockState`; hide it so the capture state's `LockState` stays unambiguous.
import 'package:flutter/widgets.dart' hide LockState;

import '../domain/color_coordinates.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import 'camera_permission.dart';
import 'capture_accuracy.dart';
import 'capture_state.dart';
import 'source/camera_capture_source.dart';
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

  /// The live-feed subscription that drives [CaptureState.currentSample], or
  /// null while the feed is released across the app lifecycle (AC-9).
  ///
  /// Opened at construction, cancelled and cleared by [pauseFeed] when the
  /// Capture screen leaves the foreground, and re-opened by [resumeFeed] when it
  /// returns (plan D-7).
  StreamSubscription<Frame>? _feed;

  bool _disposed = false;

  CaptureState _state = const CaptureState();

  /// The current observable capture state.
  CaptureState get state => _state;

  /// The latest live frame for the preview to paint (bs-19 VIEW-2), or null
  /// when the active source has no live image to show.
  ///
  /// On the live [CaptureSourceKind.camera] source this is the most recent
  /// frame the feed delivered, so [CaptureLiveView] paints the camera image
  /// instead of the flat placeholder; it is null before the first frame
  /// arrives. On the deterministic [CaptureSourceKind.software] fallback — the
  /// demo scene or the no-camera / denied-permission path — it stays null, so
  /// that source keeps the flat placeholder surface it has always shown
  /// (the VIEW-1 invariant); its synthetic feed still drives the sampled
  /// reading, it is simply not painted as a live preview.
  Frame? get currentFrame =>
      source.kind == CaptureSourceKind.camera && _recentFrames.isNotEmpty
          ? _recentFrames.last
          : null;

  /// The active source's native preview widget, or null when the source has no
  /// platform preview (bs-19 VIEW-5, D-9).
  ///
  /// Only the live [CameraCaptureSource] — the real device camera — provides a
  /// native `CameraPreview`; the Capture screen renders it in place of painting
  /// the downsampled sampling [currentFrame], so on-device the preview is
  /// upright, full-resolution and smooth. For the deterministic software
  /// fallback (and the scripted acceptance source, which is not a
  /// [CameraCaptureSource]) this is null, so the view keeps painting
  /// [currentFrame] / the flat placeholder exactly as before. The [frames]
  /// stream continues to drive colour sampling either way.
  Widget? get previewWidget {
    final source = this.source;
    return source is CameraCaptureSource ? source.buildPreview() : null;
  }

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

  /// Sets the area-average sampling [radiusPx] (1 / 5 / 21 px — AC-3) and
  /// re-samples the current reading at the new radius, so
  /// [CaptureState.currentSample] tracks the selection at once (SCREEN-2 over
  /// SOURCE-2's radius-driven sampling).
  ///
  /// The live feed is finite and has already drained by the time the painter
  /// picks a radius, so moving [CaptureState.radiusPx] alone would leave the
  /// reading on the old disc; this re-averages the most recent live frame at
  /// [radiusPx]. Once a photo has been imported ([importPhoto]) the live feed no
  /// longer drives the reading, so the imported point sample is left as it
  /// stands; and before any frame has arrived there is nothing to re-sample (the
  /// radius is still recorded for the first frame to use).
  void setRadius(int radiusPx) {
    final frame = _recentFrames.isEmpty ? null : _recentFrames.last;
    emit(_state.copyWith(
      radiusPx: radiusPx,
      currentSample: _photoImported || frame == null
          ? null
          : Sample(
              coordinates: sampleAreaAverage(
                frame,
                frame.width ~/ 2,
                frame.height ~/ 2,
                radiusPx: radiusPx,
              ),
              provenance: const Provenance(ProvenanceTier.measured),
              accuracy: _state.accuracy,
            ),
    ));
  }

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

  /// Records the resolved camera-permission state (bs-19 AC-7, PERM-2).
  ///
  /// The Capture host requests camera access on first live-capture entry and
  /// calls this with the outcome, so the read endpoint's `permissionState`
  /// surfaces granted / denied. Purely a state record — it does not touch the
  /// feed; on denial the host swaps the controller to the software fallback.
  void setCameraPermission(CameraPermissionState permission) =>
      emit(_state.copyWith(cameraPermission: permission));

  /// Clears the low-light warning without changing the stated accuracy (AC-7).
  ///
  /// Dismissing the warning is a purely visual acknowledgement: it hides the
  /// low-light notice but leaves [CaptureState.accuracy] (and any already
  /// committed sample's accuracy) exactly as it was — a dim reading stays
  /// approximate after the painter waves the warning away.
  void dismissWarning() => emit(_state.copyWith(lowLightWarning: false));

  /// Toggles the value-only grayscale preview on and off (AC-10).
  ///
  /// Flips [CaptureState.valueOnly]; the Capture screen renders the live feed in
  /// grayscale while it is on (a saturation-0 filter over the feed surface) and
  /// the E21 control reads "✓ Value". A purely presentational toggle — it leaves
  /// the sampled reading untouched, so the committed colour is unaffected.
  void toggleValueOnly() =>
      emit(_state.copyWith(valueOnly: !_state.valueOnly));

  /// The colour-temperature warning raised while the torch lights the scene
  /// (AC-1): the LED's light has its own colour temperature, so a reading taken
  /// under it is biased away from how the colour looks in ambient light. Shown
  /// as the banner (SCREEN-2) until the painter acknowledges it, and the reason
  /// the committed reading is flagged [Sample.litByTorch] (AC-2).
  static const String torchColorTemperatureWarning =
      'Torch on — its colour temperature biases the measured colour.';

  /// Lights the camera torch and raises the colour-temperature warning (bs-09
  /// AC-1, AC-2).
  ///
  /// Turns the torch on at the [source] (the LED floods the scene so a reading
  /// can be taken in the dark), records [CaptureState.torchOn], and raises the
  /// [torchColorTemperatureWarning] so the painter is told the torch biases the
  /// reading. From here a [commit] stamps [Sample.litByTorch] true.
  void turnTorchOn() {
    source.turnTorchOn();
    emit(_state.copyWith(
      torchOn: true,
      torchWarning: torchColorTemperatureWarning,
    ));
  }

  /// Extinguishes the torch and clears the warning (bs-09 AC-1, AC-2).
  ///
  /// Turns the torch off at the [source], clears [CaptureState.torchOn] and
  /// drops the warning banner — the reading is back under ambient light, so a
  /// later [commit] is not torch-lit. [clearTorchWarning] is needed because the
  /// state's set-forward merge cannot otherwise return the warning to null.
  void turnTorchOff() {
    source.turnTorchOff();
    emit(_state.copyWith(torchOn: false, clearTorchWarning: true));
  }

  /// Dismisses the torch colour-temperature warning while leaving the torch lit
  /// (bs-09 AC-1).
  ///
  /// A purely visual acknowledgement: it hides the banner but keeps
  /// [CaptureState.torchOn] true, so a reading committed afterward is still
  /// flagged [Sample.litByTorch] (AC-2).
  void acknowledgeTorchWarning() =>
      emit(_state.copyWith(clearTorchWarning: true));

  /// Marks the point ([x], [y]) on the live frame for multi-point sampling
  /// (bs-09 AC-3).
  ///
  /// Appends a [MarkedPoint] to [CaptureState.markedPoints]; the painter can
  /// mark several before sampling them together with [sampleMarkedPoints]. The
  /// mark records only the position — the colour is read later, off the frame
  /// current when the painter samples.
  void markPoint(int x, int y) => emit(_state.copyWith(
        markedPoints: [..._state.markedPoints, MarkedPoint(x, y)],
      ));

  /// Clears every marked point (bs-09 AC-3): empties
  /// [CaptureState.markedPoints] so the painter can start a fresh set.
  void clearMarkedPoints() =>
      emit(_state.copyWith(markedPoints: const <MarkedPoint>[]));

  /// Samples the current frame at every marked point at once, producing one
  /// [MultiPointReading] per point (bs-09 AC-3).
  ///
  /// Each marked point is area-averaged on the most recent live frame at the
  /// current [CaptureState.radiusPx] — the same area-average a single reading
  /// uses — so every point gets its own colour rather than one reading averaged
  /// across them all. The readings keep their marked positions so the screen can
  /// show each point with its own value (AC-4) and any two can be sent to a
  /// comparison (AC-5). A no-op before any frame has arrived (nothing to sample).
  void sampleMarkedPoints() {
    if (_recentFrames.isEmpty) return;
    final frame = _recentFrames.last;
    emit(_state.copyWith(
      markedReadings: [
        for (final point in _state.markedPoints)
          MultiPointReading(
            position: point,
            coordinates: sampleAreaAverage(
              frame,
              point.x,
              point.y,
              radiusPx: _state.radiusPx,
            ),
          ),
      ],
    ));
  }

  /// Sends the readings at marked points [i] and [j] to a side-by-side
  /// comparison, opening it with both slots filled at once (bs-09 AC-5).
  ///
  /// Builds a measured [Sample] from each chosen [MultiPointReading] — carrying
  /// its sampled colour and the reading's stated [CaptureState.accuracy] — and
  /// publishes the pair as [CaptureState.pairToCompare] with [i] in slot A and
  /// [j] in slot B. The Capture screen watches that field and opens the
  /// comparison for it (the mirror of the commit → Readout handoff), so the two
  /// marked readings arrive in the comparison together rather than being added
  /// one at a time through the picker.
  void sendPairToComparison(int i, int j) {
    final readings = _state.markedReadings;
    emit(_state.copyWith(
      pairToCompare: ComparisonPair(
        _sampleOf(readings[i]),
        _sampleOf(readings[j]),
      ),
    ));
  }

  /// A measured [Sample] carrying [reading]'s sampled colour at the reading's
  /// stated accuracy — the shape the comparison takes each slot in.
  Sample _sampleOf(MultiPointReading reading) => Sample(
        coordinates: reading.coordinates,
        provenance: const Provenance(ProvenanceTier.measured),
        accuracy: _state.accuracy,
      );

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
  ///
  /// Reliability (bs-12 AC-9): whenever any [activeDowngradeReasons] holds — poor
  /// lighting, AE/AWB/AF not locked, or no reference card in view — the committed
  /// reading's stated accuracy is **forced to [CaptureAccuracy.approximate]**,
  /// never returned as [CaptureAccuracy.calibrated], so an unsettled or
  /// uncalibrated reading is not handed back as if trustworthy (plan bs-12 D-5).
  /// With no reason active the reading keeps the tier it earned (an explicit
  /// card calibration stays calibrated). The reason is surfaced to the painter
  /// on the live view (the Capture screen reads [activeDowngradeReasons]).
  void commit() {
    final reading = _state.currentSample;
    if (reading == null) return;
    // AC-9: a poor-condition reading is downgraded to approximate rather than
    // returned at its would-be tier; an unqualified reading keeps its tier.
    final accuracy = activeDowngradeReasons.isEmpty
        ? _state.accuracy
        : CaptureAccuracy.approximate;
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
      // bs-09 SOURCE-4: the capture contract normalises a committed reading
      // against the reference card whenever one is in view, so the sample is
      // canonical CIELAB independent of the platform's raw pipeline offset
      // (AC-9, AC-10) — not only after the painter taps calibrate. The explicit
      // calibrate still upgrades the stated accuracy tier (AC-8, carried by
      // `_state.accuracy` below); without a card there is nothing to normalise
      // against and the raw reading stands. `calibrate()` only reaches the
      // calibrated tier with a card present, so this is a strict superset of the
      // old `accuracy == calibrated` condition.
      coordinates = source.referenceCardPresent
          ? source.normaliseAgainstCard(mean)
          : mean;
      framesAveraged = _recentFrames.length;
    }
    emit(_state.copyWith(
      lastCommittedSample: Sample(
        coordinates: coordinates,
        provenance: const Provenance(ProvenanceTier.measured),
        accuracy: accuracy,
        justCaptured: true,
        // bs-09 (CAPTURE-2): tag the committed reading with the gamut the source
        // captured in, whether the torch lit it, and processed-vs-RAW. Until
        // SOURCE-2/3 and CAPTURE-3 give these meaning they are the sRGB /
        // processed / torch-off defaults, so bs-02 behaviour is unchanged.
        colorSpace: source.colorSpace,
        captureMode: source.captureMode,
        litByTorch: _state.torchOn,
      ),
      framesAveraged: framesAveraged,
      lowLightWarning: source.lighting == Lighting.low,
    ));
  }

  /// The poor-capture conditions currently in effect at the [source] — the
  /// AC-9 downgrade *inputs* (plan bs-12 D-5), read-only and side-effect-free.
  ///
  /// Exposes, as first-class [AccuracyDowngradeReason]s, the three conditions
  /// the spec's AC-9 requires be surfaced: low lighting
  /// ([Lighting.low]), AE/AWB/AF not locked together
  /// ([CaptureLocks.allLocked] false), and no reference card in view
  /// ([CaptureSource.referenceCardPresent] false). The set is empty in the
  /// trustworthy case — well lit, locked and a card present.
  ///
  /// **This is the QUALITY-1 seam, not the fix.** Reading it changes nothing: a
  /// [commit] still states exactly the accuracy it always did, so current
  /// behaviour is byte-for-byte unchanged. QUALITY-2 consumes this to force a
  /// committed reading approximate (and surface the reason) whenever it is
  /// non-empty, closing the gap where only lighting downgraded the reading.
  Set<AccuracyDowngradeReason> get activeDowngradeReasons => {
        if (source.lighting == Lighting.low) AccuracyDowngradeReason.lowLight,
        if (!source.locks.allLocked)
          AccuracyDowngradeReason.exposureUnlocked,
        if (!source.referenceCardPresent)
          AccuracyDowngradeReason.missingReferenceCard,
      };

  /// Releases the live feed across the app lifecycle (AC-9, plan D-7).
  ///
  /// Cancels the frame subscription so the active source tears its device down —
  /// the live [CaptureSource] stops the camera through the `frames` stream's
  /// `onCancel` — freeing the camera (and dropping any AE/AWB/AF/torch hold)
  /// while the Capture screen is inactive, hidden, paused or disposed. Idempotent:
  /// a no-op once the feed is already released, so the several transitions that
  /// precede a background (`inactive` → `hidden` → `paused`) release the camera
  /// exactly once.
  void pauseFeed() {
    _feed?.cancel();
    _feed = null;
  }

  /// Re-acquires the live feed when the Capture screen returns to the foreground
  /// (AC-9, plan D-7).
  ///
  /// Opens a fresh subscription so the source re-initialises its device — the
  /// live [CaptureSource] restarts the camera through the `frames` stream's
  /// `onListen` — and the preview resumes from a new frame rather than the frozen
  /// or black last frame. Idempotent: a no-op while the feed is already live, and
  /// once the controller is [dispose]d, so a late `resumed` cannot resurrect a
  /// torn-down controller.
  void resumeFeed() {
    if (_disposed || _feed != null) return;
    _feed = source.frames.listen(_onFrame);
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
    _feed?.cancel();
    super.dispose();
  }
}
