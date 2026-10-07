import 'package:flutter/foundation.dart';

import 'capture_state.dart';
import 'source/capture_source.dart';

/// Drives one capture: holds the [CaptureSource], exposes the observable
/// [CaptureState], and offers the actions the Capture screen takes on it.
///
/// This is the CAPTURE-2 shell — the fields and the action surface are present
/// but the behaviour behind each action is deferred to its behaviour phase and
/// throws [UnimplementedError] until then, exactly as the SOURCE sampling
/// signatures do. A [ChangeNotifier] so the screen (and the acceptance read
/// endpoint) can rebuild as the state moves.
class CaptureController extends ChangeNotifier {
  /// Creates a controller reading from [source], starting in the default
  /// [CaptureState] (auto exposure, 5 px radius, approximate accuracy).
  CaptureController({required this.source});

  /// The source of frames and camera controls this capture reads (D-2). Held
  /// for the behaviour phases; the shell does not yet read frames from it.
  final CaptureSource source;

  CaptureState _state = const CaptureState();

  /// The current observable capture state.
  CaptureState get state => _state;

  /// Locks AE, AWB and AF together so the reading settles to "STABLE 12/12"
  /// (AC-4). Behaviour lands in CAPTURE-3.
  void lock() => throw UnimplementedError('lock: behaviour lands in CAPTURE-3');

  /// Sets the area-average sampling [radiusPx] (1 / 5 / 21 px — AC-3). Behaviour
  /// lands in SCREEN-2 (the selector) over SOURCE-2's radius-driven sampling.
  void setRadius(int radiusPx) =>
      throw UnimplementedError('setRadius: behaviour lands in SCREEN-2');

  /// Normalises captures against a reference card and upgrades the stated
  /// accuracy to [CaptureAccuracy.calibrated] (AC-8). Behaviour lands in
  /// CAPTURE-5.
  void calibrate() =>
      throw UnimplementedError('calibrate: behaviour lands in CAPTURE-5');

  /// Clears the low-light warning without changing the accuracy label (AC-7).
  /// Behaviour lands in CAPTURE-4.
  void dismissWarning() =>
      throw UnimplementedError('dismissWarning: behaviour lands in CAPTURE-4');

  /// Toggles the value-only grayscale preview (AC-10). Behaviour lands in
  /// SCREEN-3.
  void toggleValueOnly() =>
      throw UnimplementedError('toggleValueOnly: behaviour lands in SCREEN-3');

  /// Averages several frames into a committed [CaptureState.lastCommittedSample]
  /// and opens its readout with a haptic (AC-11). Behaviour lands in CAPTURE-6.
  void commit() =>
      throw UnimplementedError('commit: behaviour lands in CAPTURE-6');

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
}
