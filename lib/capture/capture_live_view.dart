import 'package:flutter/material.dart';

import '../widgets/surface_card.dart';
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

  /// Wraps one live reading/warning in the wireframe's design-system banner — a
  /// [SurfaceCard] with banner padding — and the inter-banner gap below it, so
  /// the vertical run keeps a consistent rhythm (READ-2 / AC-4).
  Widget _banner(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SurfaceCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: child,
          ),
        ),
      );

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

    // AC-4 (D-6): the live readings and warnings are laid in a single vertical
    // run — one [Column] whose layout keeps every banner in its own band — so no
    // two banner rects can intersect however the system text scales (the old
    // fixed-offset corner `Positioned`s collided at large text sizes). Each is
    // rendered as a design-system banner (a [SurfaceCard]). Every reading keeps
    // its key, text, visibility condition and semantics; only the layout and the
    // banner surface change (presentation only, D-2/D-3). The run stays a Stack
    // sibling of the feed so the value-only grayscale filter touches the feed
    // alone (AC-10), never the readings.
    final readings = <Widget>[
      // The stability indicator ("SETTLING n/12" / "STABLE 12/12").
      _banner(Text(state.stabilityText, key: stabilityKey)),
      // The AE/AWB/AF lock indicator ("… LOCKED" / "… AUTO", E16).
      _banner(Text(state.lockIndicatorText, key: lockIndicatorKey)),
      // The accuracy region carries [accuracyKey] as a wrapper around the label
      // text, so callers can assert the tier word *within* the region
      // (`find.descendant(of: accuracyKey, matching: find.text(...))`).
      _banner(
        KeyedSubtree(
          key: accuracyKey,
          child: Text(state.accuracy.label),
        ),
      ),
      // bs-12 AC-9: when a reading is under one or more poor conditions, name
      // each one in words below the accuracy label, so the painter knows the
      // reading is downgraded and *why* — never returned as if trustworthy.
      // Empty (the trustworthy reading) renders nothing.
      if (downgradeReasons.isNotEmpty)
        _banner(
          Column(
            key: downgradeReasonsKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final reason in downgradeReasons) Text(reason.label),
            ],
          ),
        ),
      // E15's low-light warning, shown only while the state carries it.
      Visibility(
        visible: state.lowLightWarning,
        child: _banner(
          const Text(
            'Low light — reading may be approximate',
            key: warningKey,
          ),
        ),
      ),
      // bs-09 torch colour-temperature warning (AC-1), shown only while the
      // controller has set the warning string (raised by CAPTURE-3's
      // turnTorchOn; AC-1 landed in SCREEN-2).
      Visibility(
        visible: state.torchWarning != null,
        child: _banner(
          Text(state.torchWarning ?? '', key: torchWarningKey),
        ),
      ),
    ];

    // Fills the space its parent gives it (the Capture screen hands it the area
    // above the controls); the readings run down the top-left over the feed.
    return Stack(
      fit: StackFit.expand,
      children: [
        feed,
        // The eyedropper carries [CaptureEyedropper.eyedropperKey] itself; its
        // reticle sizes to the selected sampling radius (AC-3).
        CaptureEyedropper(radiusPx: state.radiusPx),
        // The single vertical run of readings/warnings. `top` only (no `bottom`/
        // `height`) leaves the run's height unbounded, so the Column lays its
        // banners out one under another with no risk of a flex overflow at any
        // text scale; `left`+`right` give it a width so long warnings wrap.
        Positioned(
          left: 8,
          top: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: readings,
          ),
        ),
        // bs-09 marked points (AC-3): each point the painter has marked draws on
        // the feed at its frame position. Empty until markPoint runs (CAPTURE-4).
        for (final point in state.markedPoints)
          Positioned(
            left: point.x.toDouble(),
            top: point.y.toDouble(),
            // The marker's meaning (a marked sample point) must not ride on its
            // white fill alone (SI Accessibility, AC-1/AC-2): a Semantics label
            // states it in words so a screen reader announces it and the colour
            // stays decorative.
            child: Semantics(
              label: 'Marked sample point',
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
          ),
      ],
    );
  }
}
