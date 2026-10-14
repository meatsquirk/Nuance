import 'package:flutter/material.dart';

import 'capture_accuracy.dart';
import 'capture_eyedropper.dart';
import 'capture_state.dart';

/// The live camera viewport: the feed surface, the centre eyedropper, and the
/// text readings laid over it (stability, accuracy, low-light warning).
///
/// SCREEN-1 shell — it renders a placeholder feed surface (a flat colour; the
/// real frame render and the value-only grayscale toggle land in SOURCE-2 /
/// SCREEN-3) with the [CaptureEyedropper] centred over it, and surfaces the
/// observable [CaptureState] as text so no reading rests on colour alone (the
/// bs-01 label contract): the stability indicator, the accuracy tier and the
/// low-light warning are words, not bare colour. It reads a plain [CaptureState]
/// so it renders any state without driving the controller.
///
/// bs-09 adds two observable regions over the same feed: the torch
/// colour-temperature warning banner (AC-1), a sibling to the low-light warning
/// shown only while [CaptureState.torchWarning] is set (CAPTURE-3), and the
/// marked points (AC-3) drawn at their frame positions (CAPTURE-4). Both are
/// empty in this shell.
class CaptureLiveView extends StatelessWidget {
  const CaptureLiveView({
    required this.state,
    this.downgradeReasons = const <AccuracyDowngradeReason>{},
    super.key,
  });

  /// Stable anchor for the feed surface.
  static const Key liveViewKey = ValueKey('capture-live-view');

  /// Stable anchor for the "SETTLING n/12" / "STABLE 12/12" indicator.
  static const Key stabilityKey = ValueKey('capture-stability-indicator');

  /// Stable anchor for the "AE · AWB · AF LOCKED" / "… AUTO" lock indicator (E16).
  static const Key lockIndicatorKey = ValueKey('capture-lock-indicator');

  /// Stable anchor for the stated-accuracy label.
  static const Key accuracyKey = ValueKey('capture-accuracy-label');

  /// Stable anchor for the low-light warning (E15's subject).
  static const Key warningKey = ValueKey('capture-low-light-warning');

  /// Stable anchor for the reliability downgrade-reasons region (bs-12 AC-9):
  /// the words naming *why* a reading under poor conditions is downgraded, so no
  /// honesty signal rests on colour alone. Absent when nothing is downgraded.
  static const Key downgradeReasonsKey = ValueKey('capture-downgrade-reasons');

  /// Stable anchor for the torch colour-temperature warning banner (bs-09 AC-1).
  static const Key torchWarningKey = ValueKey('capture-torch-warning');

  /// Stable anchor for the marked point drawn on the feed at ([MarkedPoint.x],
  /// [MarkedPoint.y]) for multi-point sampling (bs-09 AC-3).
  static Key markedPointKey(MarkedPoint point) =>
      ValueKey('capture-marked-point-${point.x}-${point.y}');

  /// The capture state this viewport reflects.
  final CaptureState state;

  /// The poor-capture conditions currently in effect (bs-12 AC-9), surfaced as
  /// words over the feed so the painter is told *why* a reading would be
  /// downgraded (never trusting colour alone). Empty — the trustworthy case —
  /// renders nothing. Fed by the Capture screen from
  /// [CaptureController.activeDowngradeReasons].
  final Set<AccuracyDowngradeReason> downgradeReasons;

  /// Saturation-0 (luminance-preserving) colour matrix: maps every channel to
  /// the pixel's luma, so the feed renders as value-only grayscale (AC-10).
  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    // Placeholder feed surface; SOURCE-2 renders real frames here. In value-only
    // mode (AC-10) the feed is wrapped in a saturation-0 [ColorFiltered] so it
    // renders grayscale, leaving the overlaid readings in colour.
    const Widget feedSurface =
        ColoredBox(key: liveViewKey, color: Color(0xFF3A3A3A));
    final Widget feed = state.valueOnly
        ? const ColorFiltered(
            colorFilter: ColorFilter.matrix(_grayscaleMatrix),
            child: feedSurface,
          )
        : feedSurface;

    // Fills the space its parent gives it (the Capture screen hands it the area
    // above the controls); the readings are laid over the feed.
    return Stack(
      fit: StackFit.expand,
      children: [
        feed,
        // The eyedropper carries [CaptureEyedropper.eyedropperKey] itself; its
        // reticle sizes to the selected sampling radius (AC-3).
        CaptureEyedropper(radiusPx: state.radiusPx),
        // The text readings, laid over the feed so none rests on colour alone.
        Positioned(
          left: 8,
          top: 8,
          child: Text(
            state.stabilityText,
            key: stabilityKey,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          // The accuracy region carries [accuracyKey] as a wrapper around the
          // label text, so callers can assert the tier word *within* the region
          // (`find.descendant(of: accuracyKey, matching: find.text(...))`).
          child: KeyedSubtree(
            key: accuracyKey,
            child: Text(
              state.accuracy.label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: 32,
          child: Text(
            state.lockIndicatorText,
            key: lockIndicatorKey,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        // bs-12 AC-9: when a reading is under one or more poor conditions, name
        // each one in words below the accuracy label, so the painter knows the
        // reading is downgraded and *why* — never returned as if trustworthy.
        // Empty (the trustworthy reading) renders nothing.
        if (downgradeReasons.isNotEmpty)
          Positioned(
            right: 8,
            top: 32,
            child: Column(
              key: downgradeReasonsKey,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final reason in downgradeReasons)
                  Text(
                    reason.label,
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Visibility(
            visible: state.lowLightWarning,
            child: const Text(
              'Low light — reading may be approximate',
              key: warningKey,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        // bs-09 torch colour-temperature warning (AC-1): a sibling banner above
        // the low-light warning, shown only while the controller has set the
        // warning string (raised by CAPTURE-3's turnTorchOn; AC-1 landed in
        // SCREEN-2).
        Positioned(
          left: 8,
          bottom: 32,
          child: Visibility(
            visible: state.torchWarning != null,
            child: Text(
              state.torchWarning ?? '',
              key: torchWarningKey,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        // bs-09 marked points (AC-3): each point the painter has marked draws on
        // the feed at its frame position. Empty until markPoint runs (CAPTURE-4).
        for (final point in state.markedPoints)
          Positioned(
            left: point.x.toDouble(),
            top: point.y.toDouble(),
            child: Container(
              key: markedPointKey(point),
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
