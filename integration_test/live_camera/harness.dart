// Acceptance-suite harness for bs-19 Live camera capture source (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and `buildApp` driver the AC tests
// (ITEST-2, ITEST-3) are written against. The suite drives the *real* assembled
// app through bs-01's single production `buildApp` entry with a scripted camera
// source injected at the `AppDependencies.captureSource` seam, so it opens on
// the Capture screen; `WidgetTester` drives the UI and the `CaptureReadEndpoint`
// observes the capture state and the active source kind / permission state.
//
// Faked (infrastructure only): the camera device, via `ScriptedCameraSource`
// (known frames + settable locks / torch / lighting / selection signals), and a
// recording `CameraPermission`. The reading maths, sampling, lock/settle, the
// live-view widget, routing and commit are the real code — which is why every
// AC stays pending until its behaviour phase lands (see `pending.dart`).
//
// Fixture identifiers mirror the plan's names, and the AC catalogue references
// them verbatim, so this file opts out of the camelCase lints for them.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/camera_permission.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/live_frame_view.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';

import '../fakes/fake_haptics.dart';
import '../fakes/fake_speech.dart';
import '../fakes/scripted_camera_source.dart';

// Re-export so an AC test only needs to import this harness: the pending gate
// (`acTestWidgets`, `pendingACs`, …), the scripted source + recording
// permission + frame builder, and the recording platform sinks.
export '../fakes/fake_haptics.dart';
export '../fakes/fake_speech.dart';
export '../fakes/scripted_camera_source.dart';
export 'pending.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// Frame pixels are raw sRGB device channels — the colour under the reticle a
// correct conversion / sampling returns. Two well-separated colours give AC-2's
// conversion control ("a different known colour converts to a correspondingly
// different pixel") and AC-3's live-frame change (c1 → c2) a real contrast; a
// sampler returning a stale or fixed colour fails to tell them apart.
// ---------------------------------------------------------------------------

const ColorScience _science = ColorScienceImpl();

/// A vivid cyan reticle colour — the scene the live feed opens on (c1).
const Pixel RETICLE_CYAN = Pixel(0, 170, 200);

/// A vivid orange reticle colour, well separated from [RETICLE_CYAN] — the
/// colour the live frame changes to (c2), and the AC-2 conversion control.
const Pixel RETICLE_ORANGE = Pixel(220, 120, 20);

/// A uniform frame of [RETICLE_CYAN] — the live feed's opening frame.
final Frame FRAME_CYAN = knownFrame(RETICLE_CYAN);

/// A uniform frame of [RETICLE_ORANGE] — the frame the feed changes to (AC-3)
/// and the second conversion colour (AC-2).
final Frame FRAME_ORANGE = knownFrame(RETICLE_ORANGE);

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one live-camera scenario.
///
/// Holds the injected scripted [source] (its feed, lock / torch recorders and
/// settable selection signals) and the recording [permission] the AC-7 phase
/// drives, and exposes the `when…` actions a painter takes on the Capture
/// screen. Observes capture state and the active source kind through the
/// [CaptureReadEndpoint] the screen provides.
class LiveCameraHarness {
  LiveCameraHarness(
    this.tester, {
    required this.source,
    required this.permission,
    required this.haptics,
  });

  /// The widget tester driving the real Capture UI.
  final WidgetTester tester;

  /// The scripted camera source the scenario was built over.
  final ScriptedCameraSource source;

  /// The recording permission the AC-7 phase drives (held for PERM-2, which
  /// wires a `CameraPermission` into the assembly; inert until then).
  final RecordingCameraPermission permission;

  /// The recording haptics sink injected into the app (commit feedback).
  final FakeHaptics haptics;

  /// The live read endpoint the Capture screen provides.
  ///
  /// `skipOffstage: false` so the state stays observable after a commit pushes
  /// the Readout over the still-mounted Capture route.
  CaptureReadEndpoint get readEndpoint => tester.widget<CaptureReadEndpoint>(
        find.byKey(CaptureReadEndpoint.endpointKey, skipOffstage: false),
      );

  /// The live controller the Capture screen owns.
  CaptureController get controller => readEndpoint.controller;

  /// The current observable capture state.
  CaptureState get state => controller.state;

  /// Which source the production selection chose, as the read endpoint reports
  /// it (AC-1 / AC-7 / AC-8).
  CaptureSourceKind get activeSourceKind => readEndpoint.activeSourceKind;

  /// The resolved camera-permission state the read endpoint reports (AC-7).
  CameraPermissionState get permissionState => readEndpoint.permissionState;

  /// Whether the live view is still showing the flat grey placeholder surface
  /// rather than a painted frame (AC-1): true while the feed-surface widget
  /// under [CaptureLiveView.liveViewKey] is a placeholder [ColoredBox].
  ///
  /// Reads the real widget tree through the live-view anchor, so it tells a
  /// painted camera frame apart from the un-wired placeholder exactly as the
  /// AC-1 Then needs.
  bool get showsPlaceholder {
    final box = find.descendant(
      of: find.byKey(CaptureLiveView.liveViewKey, skipOffstage: false),
      matching: find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == LiveFrameView.placeholderColor,
      ),
    );
    return box.evaluate().isNotEmpty;
  }

  Future<void> _tap(Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  /// Locks exposure / white balance / focus together (E16 — AC-5).
  Future<void> whenLock() => _tap(CaptureControls.lockKey);

  /// Turns the torch on (AC-6).
  Future<void> whenTurnTorchOn() => _tap(CaptureControls.torchKey);

  /// Turns the torch off (AC-6) — a no-op tap when it is already on toggles it
  /// off, mirroring the single toggle control the painter uses.
  Future<void> whenTurnTorchOff() => _tap(CaptureControls.torchKey);

  /// Toggles the value-only grayscale preview (E21 — AC-4).
  Future<void> whenToggleValueOnly() => _tap(CaptureControls.valueOnlyKey);

  /// Commits (captures) the current reading (E20 — AC-6).
  Future<void> whenCommit() => _tap(CaptureControls.captureKey);

  /// Changes the colour under the reticle: pushes [frame] onto the live feed
  /// and pumps so the controller samples it (AC-3).
  Future<void> whenFrameChangesTo(Frame frame) async {
    source.emitFrame(frame);
    await tester.pump();
  }
}

/// Opens the Capture screen over a scripted camera [source] in the assembled
/// app.
///
/// Builds the real app via the production `buildApp` entry with [source]
/// injected through `AppDependencies.captureSource` and the platform sinks
/// faked; colour-science is the real `ColorScienceImpl`. Because a capture
/// source is present, `buildApp` opens on the Capture screen. The [permission]
/// recorder is held on the returned harness for the AC-7 phase (PERM-2 wires a
/// `CameraPermission` into the assembly; until then it is observed only through
/// the fixture).
///
/// Mounts with a single `pump` rather than `pumpAndSettle`, mirroring the bs-02
/// capture harness: the stability counter settles one step per rendered frame,
/// so `pumpAndSettle` would run it straight to "STABLE 12/12"; a single pump
/// opens the screen with the seed frame already sampled into `currentSample`.
/// `when…` actions settle locally.
Future<LiveCameraHarness> givenLiveCamera(
  WidgetTester tester, {
  ScriptedCameraSource? source,
  RecordingCameraPermission? permission,
}) async {
  final cameraSource = source ?? ScriptedCameraSource(initialFrames: [FRAME_CYAN]);
  final cameraPermission = permission ?? RecordingCameraPermission();
  final haptics = FakeHaptics();
  addTearDown(cameraSource.dispose);
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: _science,
        speech: FakeSpeech(),
        haptics: haptics,
        captureSource: cameraSource,
      ),
    ),
  );
  await tester.pump();
  return LiveCameraHarness(
    tester,
    source: cameraSource,
    permission: cameraPermission,
    haptics: haptics,
  );
}
