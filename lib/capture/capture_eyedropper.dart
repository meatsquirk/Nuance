import 'package:flutter/material.dart';

/// The centre-point eyedropper marker: a reticle showing where the colour will
/// be sampled (AC-1) and how wide the area average is (AC-3).
///
/// This is the SCREEN-1 shell marker — a findable, centred reticle of a fixed
/// placeholder size. The real centring assertion (AC-1) and the exact reticle
/// sizing for each radius (1 px → 8 px, 5 px → 20 px, 21 px → 44 px — AC-3) land
/// in SCREEN-2; this shell renders the reticle so the live view has a findable
/// centre marker to build those on.
class CaptureEyedropper extends StatelessWidget {
  const CaptureEyedropper({super.key});

  /// Stable anchor for the eyedropper marker.
  static const Key eyedropperKey = ValueKey('capture-eyedropper');

  /// Stable anchor for the reticle ring whose size SCREEN-2 drives from the
  /// sampling radius.
  static const Key reticleKey = ValueKey('capture-reticle');

  /// The reticle's placeholder edge length, in logical pixels.
  ///
  /// A fixed shell size (SCREEN-2 replaces it with the exact per-radius sizes);
  /// chosen as the 5 px-radius target so the default reading looks right.
  static const double placeholderReticleSize = 20;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: eyedropperKey,
      child: Container(
        key: reticleKey,
        width: placeholderReticleSize,
        height: placeholderReticleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
