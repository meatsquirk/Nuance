// bs-19 Live camera capture — acceptance tests for the *preview / conversion*
// ACs (ITEST-2). One *pending* `acTestWidgets` per AC, skipped in the default
// run, executed under `--dart-define=BS19_RUN_PENDING=true`, un-pended by the
// owning behaviour phase (AC-1 → VIEW-2, AC-2 → CAM-3, AC-4 → VIEW-3) by
// deleting its row in `pendingACs`.
//
//   * AC-1 TestAC01_LivePreview     — the live view paints the camera feed.
//   * AC-2 TestAC02_FrameConversion — device buffers convert to the right colour.
//   * AC-4 TestAC04_ValueOnlyLive   — value-only greys the feed, not the readings.
//
// AC-1 / AC-4 drive the real assembled app through `givenLiveCamera` and read
// the live-view widget tree. AC-2 is a conversion test over the pure-Dart
// `frameFromCameraImage` (plan D-4): it builds platform-shaped `CameraImage`
// buffers (Android YUV420 / iOS BGRA8888) with a known uniform colour and
// asserts the converted `Frame` reproduces it — the only AC not driven through
// the UI, because the conversion is a pure buffer→buffer step below the source.
//
// The reading ACs (AC-3 / AC-5) live in `reading_test.dart`; keep the two files
// disjoint.

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/live_frame_view.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/frame_conversion.dart';

import 'harness.dart';

// ---------------------------------------------------------------------------
// AC-2 conversion contract + fixtures (the `rawCameraImage(yuv420 / bgra)`
// fixture the plan names).
//
// The conversion the test pins — the contract CAM-3 must satisfy and G-2
// reviews:
//   * iOS BGRA8888: one plane, 4 bytes/pixel in B,G,R,A order → RGB (exact).
//   * Android YUV420: a full-resolution Y plane and 2×2-subsampled U/V planes,
//     full-range BT.601 (JFIF), read through each plane's own `bytesPerRow` /
//     `bytesPerPixel` strides → RGB (within an 8-bit-rounding tolerance).
// A uniform-colour buffer is used so downsampling (D-4) is lossless: every
// output pixel equals the one known colour, whatever the output resolution.
// ---------------------------------------------------------------------------

/// Exact L1 gap allowed for the lossless BGRA path.
const int _bgraToleranceL1 = 3;

/// L1 gap allowed for the YUV→RGB round-trip. On a uniform frame the only
/// legitimate error is 8-bit quantisation (≤ ~3 L1 for the full-range BT.601
/// contract this fixture encodes). Kept tight on purpose so the Then also
/// rejects a *mis-ranged* decode: reading these full-range buffers with the
/// limited-/video-range BT.601 matrix (the common Android YUV bug) lands ~21–29
/// L1 off (e.g. c1 cyan → (0,178,213), L1 21), well outside this bound. A looser
/// tolerance (e.g. 30) would wave that mis-range through.
const int _yuvToleranceL1 = 12;

int _l1(Pixel a, Pixel b) =>
    (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();

int _clampByte(num v) => v.round().clamp(0, 255).toInt();
int _yOf(Pixel p) => _clampByte(0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
int _uOf(Pixel p) =>
    _clampByte(-0.168736 * p.r - 0.331264 * p.g + 0.5 * p.b + 128);
int _vOf(Pixel p) =>
    _clampByte(0.5 * p.r - 0.418688 * p.g - 0.081312 * p.b + 128);

/// A 16×16 iOS BGRA8888 [CameraImage], every pixel the uniform [colour].
CameraImage _bgraImage(Pixel colour) {
  const w = 16, h = 16;
  final bytes = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    bytes[i * 4 + 0] = colour.b;
    bytes[i * 4 + 1] = colour.g;
    bytes[i * 4 + 2] = colour.r;
    bytes[i * 4 + 3] = 255;
  }
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      // kCVPixelFormatType_32BGRA.
      format: const CameraImageFormat(ImageFormatGroup.bgra8888, raw: 1111970369),
      width: w,
      height: h,
      planes: [
        CameraImagePlane(
          bytes: bytes,
          bytesPerRow: w * 4,
          bytesPerPixel: 4,
          width: w,
          height: h,
        ),
      ],
    ),
  );
}

/// A 16×16 Android YUV420 [CameraImage] of the uniform [colour] (full-range
/// BT.601), with full-resolution Y and 2×2-subsampled U/V planes.
CameraImage _yuvImage(Pixel colour) {
  const w = 16, h = 16;
  final y = _yOf(colour), u = _uOf(colour), v = _vOf(colour);
  final yPlane = Uint8List(w * h)..fillRange(0, w * h, y);
  final cw = w ~/ 2, ch = h ~/ 2;
  final uPlane = Uint8List(cw * ch)..fillRange(0, cw * ch, u);
  final vPlane = Uint8List(cw * ch)..fillRange(0, cw * ch, v);
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      // android.graphics.ImageFormat.YUV_420_888.
      format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
      width: w,
      height: h,
      planes: [
        CameraImagePlane(
            bytes: yPlane, bytesPerRow: w, bytesPerPixel: 1, width: w, height: h),
        CameraImagePlane(
            bytes: uPlane, bytesPerRow: cw, bytesPerPixel: 1, width: cw, height: ch),
        CameraImagePlane(
            bytes: vPlane, bytesPerRow: cw, bytesPerPixel: 1, width: cw, height: ch),
      ],
    ),
  );
}

/// The converted centre pixel of [image] once CAM-3's conversion lands.
///
/// Guards the call with `returnsNormally` so that at the red baseline — where
/// the `frame_conversion.dart` shell throws `UnimplementedError` until CAM-3 —
/// the test fails cleanly on this assertion naming CAM-3, not on an uncaught
/// exception.
Pixel _convertedCentre(CameraImage image, String platform) {
  late final Frame frame;
  expect(
    () => frame = frameFromCameraImage(image),
    returnsNormally,
    reason: 'AC-2: $platform CameraImage→Frame conversion built by CAM-3',
  );
  return frame.pixelAt(frame.width ~/ 2, frame.height ~/ 2);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  acTestWidgets(
    'AC-1',
    'TestAC01_LivePreview — the live view shows the camera feed, not the '
        'placeholder',
    (tester) async {
      // Given: a camera is available and permission is granted, so the live
      // camera source is active — checked through the read endpoint before the
      // screen is read.
      final h = await givenLiveCamera(tester);
      expect(h.activeSourceKind, CaptureSourceKind.camera,
          reason: 'AC-1 Given: the active source is the live camera');

      // When: the Capture screen opens on the live camera source
      // (givenLiveCamera has pumped it on-screen).

      // The scripted acceptance source is not the real-device camera, so it
      // surfaces no native CameraPreview (VIEW-5/D-9): this scenario therefore
      // exercises the painted-frame path, which is exactly what the Then below
      // asserts. (The native-preview render is device-only, coverage-ignored,
      // and verified at the SIGNOFF-3 walkthrough.)
      expect(h.controller.previewWidget, isNull,
          reason: 'AC-1: the scripted source has no native preview, so the '
              'painted-frame path is the one under test');

      // Then: the live view renders the camera's frames — the frame-render
      // widget carries a real frame — and no longer shows the flat grey
      // placeholder surface. Red until VIEW-2 feeds the source's frames in.
      expect(h.showsPlaceholder, isFalse,
          reason: 'AC-1: the flat grey placeholder is gone once frames render');
      final liveView =
          tester.widget<LiveFrameView>(find.byKey(CaptureLiveView.liveViewKey));
      expect(liveView.frame, isNotNull,
          reason: 'AC-1: the live view paints the active source frame '
              '(rejects a view that keeps the placeholder / ignores frames)');
    },
  );

  acTestWidgets(
    'AC-2',
    'TestAC02_FrameConversion — device camera buffers convert to the correct '
        'colour',
    (tester) async {
      // Given: a device frame whose pixels are a known reticle colour, in each
      // platform's native buffer layout — checked by asserting the raw buffer's
      // documented bytes before converting.
      final bgra = _bgraImage(RETICLE_CYAN);
      expect(
        bgra.planes.single.bytes.sublist(0, 4),
        <int>[RETICLE_CYAN.b, RETICLE_CYAN.g, RETICLE_CYAN.r, 255],
        reason: 'AC-2 Given: the iOS buffer holds c1 in B,G,R,A order',
      );
      final yuv = _yuvImage(RETICLE_CYAN);
      expect(yuv.planes.first.bytes.first, _yOf(RETICLE_CYAN),
          reason: 'AC-2 Given: the Android Y plane holds c1 luma');

      // When: each buffer is converted into the app's Frame model.
      // Then: the Frame's pixel at the reticle equals the known colour within
      // tolerance (exact for BGRA, 8-bit-rounding for YUV).
      final bgraPx = _convertedCentre(bgra, 'iOS BGRA');
      expect(_l1(bgraPx, RETICLE_CYAN), lessThanOrEqualTo(_bgraToleranceL1),
          reason: 'AC-2: the BGRA frame reproduces c1');
      // Rejects a BGR↔RGB channel swap (which would yield c1 with R and B
      // swapped — far away for this red≠blue colour).
      final swapped = Pixel(RETICLE_CYAN.b, RETICLE_CYAN.g, RETICLE_CYAN.r);
      expect(_l1(bgraPx, swapped), greaterThan(100),
          reason: 'AC-2: rejects a BGR↔RGB channel swap');

      final yuvPx = _convertedCentre(yuv, 'Android YUV420');
      expect(_l1(yuvPx, RETICLE_CYAN), lessThanOrEqualTo(_yuvToleranceL1),
          reason: 'AC-2: the YUV420 frame reproduces c1 within tolerance '
              '(rejects a mis-ranged YUV conversion)');

      // Control: a second, different known colour converts to a correspondingly
      // different pixel — rejecting a constant / fixed pixel.
      final bgraPx2 = _convertedCentre(_bgraImage(RETICLE_ORANGE), 'iOS BGRA');
      expect(_l1(bgraPx2, RETICLE_ORANGE), lessThanOrEqualTo(_bgraToleranceL1),
          reason: 'AC-2: a different colour (c2) converts correspondingly');
      expect(_l1(bgraPx, bgraPx2), greaterThan(100),
          reason: 'AC-2 control: distinct buffers yield distinct pixels '
              '(rejects a constant pixel)');
    },
  );

  acTestWidgets(
    'AC-4',
    'TestAC04_ValueOnlyLive — value-only greys the live feed but not the '
        'readings',
    (tester) async {
      // Given: the Capture screen is reading the live camera source and a colour
      // frame is visible — the live view paints a real frame (not the
      // placeholder). Red until VIEW-2/VIEW-3 render the live frame.
      final h = await givenLiveCamera(tester);
      final liveView =
          tester.widget<LiveFrameView>(find.byKey(CaptureLiveView.liveViewKey));
      expect(liveView.frame, isNotNull,
          reason: 'AC-4 Given: a live colour frame is shown (VIEW-2)');
      expect(h.showsPlaceholder, isFalse,
          reason: 'AC-4 Given: the feed is a colour frame, not the placeholder');

      // When: the painter turns on value-only mode.
      await h.whenToggleValueOnly();

      // Then: the live view renders the camera frame in grayscale — the
      // frame-render widget sits under a saturation-0 ColorFiltered…
      expect(
        find.ancestor(
          of: find.byKey(CaptureLiveView.liveViewKey),
          matching: find.byType(ColorFiltered),
        ),
        findsOneWidget,
        reason: 'AC-4: the feed is wrapped in a grayscale ColorFiltered',
      );
      // …and the overlaid readings stay in colour: the accuracy label is NOT
      // under that filter (rejects graying the whole screen incl. the readings).
      expect(
        find.ancestor(
          of: find.byKey(CaptureLiveView.accuracyKey),
          matching: find.byType(ColorFiltered),
        ),
        findsNothing,
        reason: 'AC-4: the readings sit outside the grayscale filter, in colour',
      );
    },
  );
}
