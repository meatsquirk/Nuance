import 'package:flutter/material.dart';

/// The app's single source of visual tokens — a [ColorScheme], a [TextTheme]
/// and the assembled [ThemeData] — replacing the inline
/// `ThemeData(useMaterial3: true)` that `buildApp` constructed before.
///
/// This is the **A11Y-1 shell**: the tokens are derived from the stock
/// Material-3 defaults the app already shipped with, so routing `buildApp`
/// through [AppTheme] changes nothing a user sees. Centralising them here gives
/// later phases one chokepoint to tune to the WCAG 2.2 AA floor — contrast in
/// A11Y-2, the 48dp tap-target size in A11Y-3 — instead of colours hardcoded
/// across screens.
class AppTheme {
  const AppTheme._(this.colorScheme, this.textTheme);

  /// The light-mode tokens: today's default Material-3 light scheme and
  /// typography, captured so a later phase can replace them with AA-tuned
  /// values without touching call sites.
  factory AppTheme.light() => AppTheme._fromBrightness(Brightness.light);

  /// The dark-mode tokens, captured for the same reason. Exposed as API now;
  /// `buildApp` still wires only [AppTheme.light] (A11Y-1 keeps the app's
  /// current single-theme behaviour), and a later phase decides dark wiring.
  factory AppTheme.dark() => AppTheme._fromBrightness(Brightness.dark);

  factory AppTheme._fromBrightness(Brightness brightness) {
    // Capture the exact tokens Flutter derives for the stock Material-3 theme,
    // so reassembling a ThemeData from them reproduces today's look. Later
    // phases swap in AA-tuned tokens here.
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    return AppTheme._(base.colorScheme, base.textTheme);
  }

  /// The colour tokens every screen should read via `Theme.of(context)` instead
  /// of hardcoding. Decorative-only; meaning is never carried by colour alone.
  final ColorScheme colorScheme;

  /// The type tokens for the theme.
  final TextTheme textTheme;

  /// The assembled [ThemeData] `buildApp` installs on the [MaterialApp].
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
}
