import 'dart:async';

import 'package:paint_color_assistant/capture/camera_permission.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

/// A scripted [CaptureSource] for the bs-19 live-camera acceptance suite (D-5).
///
/// The camera plugin's platform channels cannot run under `flutter-tester`, so
/// the suite injects this at the `AppDependencies.captureSource` seam (the same
/// seam `FakeCaptureSource` uses) and fakes **only the camera device**: the
/// frames it streams, its lock / torch state, the scene lighting and
/// reference-card presence, and the test-only selection signals the production
/// source-selection (PERM-2 / PERM-3) resolves to — its [kind], the
/// [permissionState] it stands for and whether a camera is [available].
///
/// Nothing colour- or sampling-related is faked: the frames are ordinary
/// [Frame]s the real `CaptureController` samples through the real sampling
/// layer, exactly like the shipped `SoftwareCaptureSource`. Two affordances the
/// acceptance Thens read beyond a plain source:
///
///   * a **controllable feed** — it replays its [initialFrames] to the
///     controller when it subscribes, then forwards every frame pushed with
///     [emitFrame] afterwards, so a test can change the colour under the reticle
///     mid-stream (AC-3);
///   * **recorded control calls** — [lockCalls], [torchOnCalls] and
///     [torchOffCalls] count the controls the controller drove, so an AC-5 /
///     AC-6 augmentation can assert the toggle actually *reached the source*
///     rather than only flipping a UI flag.
///
/// The shipped sources return a constant [kind]; this one makes it settable so a
/// single fixture can stand for either the live [CaptureSourceKind.camera]
/// selection (granted permission, camera present) or the
/// [CaptureSourceKind.software] fallback (denied / no camera) the read endpoint
/// surfaces (AC-1 / AC-7 / AC-8).
class ScriptedCameraSource implements CaptureSource {
  /// Creates a scripted source.
  ///
  /// [initialFrames] are replayed to the controller the moment it subscribes,
  /// so the live reading starts on a known colour; [emitFrame] pushes later
  /// ones. [kind] is the selection this fixture stands for (defaults to the live
  /// [CaptureSourceKind.camera]). [permissionState] and [available] are the
  /// test-only selection signals (defaulting to the granted-with-camera happy
  /// path) the production selection resolves — inert here, read by the AC-7 /
  /// AC-8 behaviour phases. [lighting], [canLock] and [referenceCardPresent]
  /// configure the scene the same way a `SceneSpec` does.
  ScriptedCameraSource({
    List<Frame> initialFrames = const <Frame>[],
    this.kind = CaptureSourceKind.camera,
    this.permissionState = CameraPermissionState.granted,
    this.available = true,
    this.lighting = Lighting.adequate,
    this.canLock = true,
    this.referenceCardPresent = false,
  }) : _initialFrames = List<Frame>.unmodifiable(initialFrames);

  final List<Frame> _initialFrames;

  // Broadcast so the live view (VIEW-2) may also listen without disturbing the
  // controller's subscription; the controller is the only listener today.
  final StreamController<Frame> _live = StreamController<Frame>.broadcast();

  /// The selection this fixture stands for — the live [CaptureSourceKind.camera]
  /// or the [CaptureSourceKind.software] fallback. Settable (also via [setKind])
  /// so one fixture can script either source-selection path; surfaced by the
  /// read endpoint as the active source kind (AC-1 / AC-7 / AC-8).
  @override
  CaptureSourceKind kind;

  /// The scene's lighting (AC-5 approximate-warning inputs).
  @override
  final Lighting lighting;

  /// Whether a reference card is in view.
  @override
  final bool referenceCardPresent;

  /// Whether this source honours the lock controls (false models a device whose
  /// AE/AWB/AF cannot be held, so [locks] never settles).
  final bool canLock;

  CaptureLocks _locks = const CaptureLocks();
  bool _torchOn = false;
  ImportedPhoto? _importedPhoto;

  /// The camera-permission state this fixture stands for (AC-7).
  ///
  /// A test-only selection signal: the production source selection (PERM-2)
  /// resolves permission through the separate [CameraPermission] seam and
  /// chooses the source accordingly; this records which decision the fixture
  /// represents so an AC-7 Then can pair it with the resolved [kind].
  CameraPermissionState permissionState;

  /// Whether the modelled device has a usable camera (AC-8).
  ///
  /// A test-only selection signal read by the no-camera fallback phase (PERM-3):
  /// false means the availability probe finds no camera, so the selection must
  /// fall back to the software source.
  bool available;

  /// How many times the lock controls were driven at the source (AC-5).
  ///
  /// One call to any of [lockExposure] / [lockWhiteBalance] / [lockFocus]
  /// increments it, so an augmentation can assert the lock actually reached the
  /// source rather than the UI merely flipping its own flag.
  int lockCalls = 0;

  /// How many times the torch was lit at the source (AC-6).
  int torchOnCalls = 0;

  /// How many times the torch was extinguished at the source (AC-6).
  int torchOffCalls = 0;

  /// Replaces the selection this fixture stands for (AC-1 / AC-7 / AC-8).
  ///
  /// The read endpoint surfaces [kind] as the active source kind, so a test
  /// scripts the granted-camera vs fallback-software selection by setting it.
  void setKind(CaptureSourceKind value) => kind = value;

  /// Pushes [frame] onto the live feed so the reading under the reticle changes
  /// to its colour (AC-3). Delivered to the controller on the next pump.
  void emitFrame(Frame frame) => _live.add(frame);

  /// Closes the feed. Called by the harness when the scenario ends so no stream
  /// is left open across tests.
  void dispose() {
    if (!_live.isClosed) _live.close();
  }

  @override
  Stream<Frame> get frames async* {
    // Replay the seed frames to the subscriber (the controller), then forward
    // every frame pushed with [emitFrame] for the rest of the scenario.
    for (final frame in _initialFrames) {
      yield frame;
    }
    yield* _live.stream;
  }

  @override
  CaptureLocks get locks => _locks;

  @override
  Stream<StabilityReading> get stability =>
      const Stream<StabilityReading>.empty();

  @override
  ColorCoordinates normaliseAgainstCard(ColorCoordinates raw) => raw;

  @override
  ImportedPhoto? get importedPhoto => _importedPhoto;

  @override
  void importPhoto(ImportedPhoto photo) => _importedPhoto = photo;

  @override
  void lockExposure() {
    if (!canLock) return;
    lockCalls++;
    _locks = _locks.copyWith(exposure: true);
  }

  @override
  void lockWhiteBalance() {
    if (!canLock) return;
    lockCalls++;
    _locks = _locks.copyWith(whiteBalance: true);
  }

  @override
  void lockFocus() {
    if (!canLock) return;
    lockCalls++;
    _locks = _locks.copyWith(focus: true);
  }

  @override
  bool get torchOn => _torchOn;

  @override
  void turnTorchOn() {
    torchOnCalls++;
    _torchOn = true;
  }

  @override
  void turnTorchOff() {
    torchOffCalls++;
    _torchOn = false;
  }

  @override
  bool get supportsWideGamut => false;

  @override
  bool get supportsRaw => false;

  @override
  CaptureColorSpace get colorSpace => CaptureColorSpace.srgb;

  @override
  CaptureMode get captureMode => CaptureMode.processed;
}

/// A recording [CameraPermission] for the bs-19 suite (AC-7).
///
/// The production permission request (PERM-2) prompts the OS through the camera
/// plugin's platform channel, which cannot run under `flutter-tester`; this
/// stand-in records each [request] and resolves to a scripted outcome instead,
/// so an AC-7 Then can assert the app requested permission exactly once and then
/// selected the source the decision implies.
///
/// Until PERM-2 wires a `CameraPermission` into the assembly there is no seam to
/// inject this at, so the AC-7 acceptance test that drives it stays pending on a
/// Given precondition naming PERM-2; the fixture is built now so that phase (and
/// its unit tests) has the recorder ready.
class RecordingCameraPermission implements CameraPermission {
  /// Creates a recorder that starts at [initial] and resolves every [request]
  /// to [resolvesTo] (the scripted granted / denied outcome).
  RecordingCameraPermission({
    CameraPermissionState initial = CameraPermissionState.undetermined,
    this.resolvesTo = CameraPermissionState.granted,
  }) : _status = initial;

  /// The outcome every [request] resolves to.
  final CameraPermissionState resolvesTo;

  CameraPermissionState _status;

  /// How many times [request] was called — exactly one on the AC-7 happy path.
  int requestCount = 0;

  @override
  CameraPermissionState get status => _status;

  @override
  Future<CameraPermissionState> request() async {
    requestCount++;
    _status = resolvesTo;
    return _status;
  }
}

/// A uniform [width]×[height] [Frame] every pixel of which is [colour].
///
/// A uniform frame samples to [colour] at the reticle (the frame centre) under
/// any sampling radius, so a test fixing the colour under the reticle (AC-1 /
/// AC-3) builds one of these. The default size leaves room for the widest
/// sampling disc (21 px radius) around the centre.
Frame knownFrame(Pixel colour, {int width = 48, int height = 48}) => Frame(
      width: width,
      height: height,
      pixels: List<Pixel>.filled(width * height, colour),
    );
