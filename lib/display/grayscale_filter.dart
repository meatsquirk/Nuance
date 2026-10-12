import 'package:flutter/widgets.dart';

import 'display_scope.dart';

/// The root wrapper that greys the whole app under value-only grayscale (bs-08
/// D-5) — the single place the camera feed, palette swatches and readings are
/// all made achromatic together (AC-6).
///
/// `buildApp` wraps the app (the spoken-output root + `MaterialApp`) in one,
/// below `DisplayScope`. DISPLAY-7 (AC-6) makes it read the `DisplayScope`
/// grayscale flag and wrap the app in a saturation-0 [ColorFiltered] when it is
/// set — a *single root* filter rather than a per-surface one, so the live
/// camera preview and the palette swatches grey together with the readings.
/// When grayscale is off no [ColorFiltered] wraps the app (full colour).
///
/// The wrapped app is held under a [KeyedSubtree] with a stable [GlobalKey], so
/// toggling grayscale **reparents** that one element in and out of the
/// [ColorFiltered] rather than rebuilding it. Without the key, turning grayscale
/// on would change the child slot's widget type (app → `ColorFiltered`) and
/// remount the whole app — losing the open settings panel and disposing the
/// app-wide speech (what broke AC-5/AC-6 before this guard).
class GrayscaleFilter extends StatefulWidget {
  /// Wraps [child] as the root of the colour-rendered app.
  const GrayscaleFilter({required this.child, super.key});

  /// The app subtree this filter greys when value-only grayscale is on.
  final Widget child;

  @override
  State<GrayscaleFilter> createState() => _GrayscaleFilterState();
}

class _GrayscaleFilterState extends State<GrayscaleFilter> {
  /// Stable identity for the app subtree, so wrapping/unwrapping it in the
  /// [ColorFiltered] moves the same element (and its state) rather than
  /// remounting the whole app on every grayscale toggle.
  final GlobalKey _appSubtree = GlobalKey();

  /// A saturation-0 colour matrix: every output channel is the Rec. 709 luma of
  /// the input (0.2126 R + 0.7152 G + 0.0722 B), so all hues collapse to grey
  /// while alpha is preserved. One matrix for the whole app (D-5).
  static const ColorFilter _desaturate = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    // Depends on the DisplayScope, so toggling grayscale rebuilds this root and
    // the whole app below it greys or un-greys in one place.
    final grayscale = DisplayScope.of(context).settings.grayscale;
    final app = KeyedSubtree(key: _appSubtree, child: widget.child);
    if (!grayscale) return app;
    return ColorFiltered(colorFilter: _desaturate, child: app);
  }
}
