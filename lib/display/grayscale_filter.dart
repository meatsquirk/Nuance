import 'package:flutter/widgets.dart';

/// The root wrapper that greys the whole app under value-only grayscale (bs-08
/// D-5) — the single place the camera feed, palette swatches and readings are
/// all made achromatic together (AC-6).
///
/// `buildApp` wraps the `MaterialApp` in one, below `DisplayScope`. Inert in the
/// shell (DISPLAY-2): it passes [child] through unchanged, so grayscale is a
/// no-op and nothing renders differently. DISPLAY-7 (AC-6) makes it read the
/// `DisplayScope` grayscale flag and wrap [child] in a saturation-0
/// [ColorFiltered] when it is set — a single root filter rather than a per-
/// surface one, so the live camera greys too.
class GrayscaleFilter extends StatelessWidget {
  /// Wraps [child] as the root of the colour-rendered app.
  const GrayscaleFilter({required this.child, super.key});

  /// The app subtree this filter greys (when active in DISPLAY-7).
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
