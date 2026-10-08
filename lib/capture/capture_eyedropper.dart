import 'package:flutter/material.dart';

import 'source/sampling.dart';

/// The centre-point eyedropper marker: a reticle showing where the colour will
/// be sampled (AC-1) and how wide the area average is (AC-3).
///
/// A findable, centred reticle whose edge length tracks the selected sampling
/// radius — 1 px → 8 px, 5 px → 20 px, 21 px → 44 px ([reticleSizeByRadiusPx],
/// AC-3) — so the painter sees the sampled disc grow and shrink with the E18
/// selector. The reticle stays centred over the live view, marking the point the
/// colour is read at (AC-1).
class CaptureEyedropper extends StatelessWidget {
  const CaptureEyedropper({this.radiusPx = kDefaultSamplingRadiusPx, super.key});

  /// Stable anchor for the eyedropper marker.
  static const Key eyedropperKey = ValueKey('capture-eyedropper');

  /// Stable anchor for the reticle ring whose size tracks the sampling radius.
  static const Key reticleKey = ValueKey('capture-reticle');

  /// The reticle's edge length (logical px) for the 5 px default radius — the
  /// size shown before and unless the painter changes the radius.
  static const double placeholderReticleSize = 20;

  /// The spec's exact radius → reticle-size mapping (AC-3): the three selectable
  /// radii each grow the reticle to a matching size.
  static const Map<int, double> reticleSizeByRadiusPx = {1: 8, 5: 20, 21: 44};

  /// The reticle edge length (logical px) for sampling [radiusPx]: the spec size
  /// for a selectable radius, else the default-sized reticle for any other
  /// radius (none is selectable in this build, but the default keeps the marker
  /// sized for an unexpected value rather than vanishing).
  static double reticleSizeFor(int radiusPx) =>
      reticleSizeByRadiusPx[radiusPx] ?? placeholderReticleSize;

  /// The sampling radius the reticle sizes itself to (default
  /// [kDefaultSamplingRadiusPx], 5 px).
  final int radiusPx;

  @override
  Widget build(BuildContext context) {
    final size = reticleSizeFor(radiusPx);
    return Center(
      key: eyedropperKey,
      child: Container(
        key: reticleKey,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
