import 'package:flutter/material.dart';

/// The app's single source of visual tokens — a [ColorScheme], a [TextTheme]
/// and the assembled [ThemeData] — replacing the inline
/// `ThemeData(useMaterial3: true)` that `buildApp` constructed before.
///
/// A11Y-1 introduced this as the single theme chokepoint, deriving the tokens
/// from the stock Material-3 defaults. **A11Y-2** then verified those tokens
/// against the WCAG 2.2 AA text-contrast floor (4.5:1 normal, 3:1 large): every
/// meaningful text-on-surface pairing of the stock M3 light scheme clears the
/// floor with margin (the lowest, primary-on-surface, is ~6.1:1), so A11Y-2
/// **adopts the stock scheme unchanged as the AA-compliant palette** rather than
/// recolouring the app — and pins that guarantee with a contrast unit test
/// (`test/app/theme_test.dart`), so a future token edit that drops any pairing
/// below AA fails the build. Screens read these tokens via `Theme.of(context)`
/// instead of hardcoding colours; A11Y-3 adds the 48dp tap-target size here.
class AppTheme {
  const AppTheme._(this.colorScheme, this.textTheme);

  /// The light-mode tokens — the stock Material-3 light scheme and typography,
  /// verified by A11Y-2 to meet the WCAG 2.2 AA contrast floor for every text
  /// pairing and adopted unchanged as the app's AA-compliant palette. This is
  /// the scheme `buildApp` installs; the AC-5 contrast rule runs over it.
  factory AppTheme.light() => AppTheme._fromBrightness(Brightness.light);

  /// The dark-mode tokens. Exposed as API now; `buildApp` still wires only
  /// [AppTheme.light] (the app's current single-theme behaviour), and a later
  /// phase decides dark wiring.
  factory AppTheme.dark() => AppTheme._fromBrightness(Brightness.dark);

  factory AppTheme._fromBrightness(Brightness brightness) {
    // Adopt the exact tokens Flutter derives for the stock Material-3 theme:
    // reassembling a ThemeData from them reproduces today's look, and the light
    // scheme already clears WCAG 2.2 AA for every text-on-surface pairing
    // (verified in test/app/theme_test.dart — recolouring is neither needed nor
    // desirable). A later phase can override a specific token here only if a
    // pairing ever regresses below the floor.
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
