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
/// instead of hardcoding colours; A11Y-3 added the 48dp tap-target size
/// ([MaterialTapTargetSize.padded]) here as the single tap-target chokepoint.
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
  ///
  /// **A11Y-3** pins [MaterialTapTargetSize.padded] here — the single
  /// tap-target chokepoint — so every Material control (`IconButton`,
  /// `TextButton`, `Checkbox`, …) reserves a ≥48dp interactive area regardless
  /// of the host platform's default, satisfying AC-4's 48dp floor (D-5). The
  /// on-device tap-target rule (`checks/target.dart`) enforces the same floor
  /// over the real screens; custom (non-Material) targets are sized ≥48dp at
  /// their call site in the A11Y-3 sweep.
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: textTheme,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );

  // --- Design-system token accessors (bs-17) ---
  //
  // The visual design system (bs-17) introduces a recessed "sunken" surface, an
  // inverted ink/paper pair, a mono micro-label style and three border weights.
  // None map to a clean [ColorScheme] / [TextTheme] slot, so they are exposed
  // here as the single source COMPONENTS (PillButton/SurfaceCard/MonoLabel) and
  // the acceptance suite read (D-7).
  //
  // **Shell (THEME-2):** every accessor returns the current stock-derived value,
  // so the rendered app is unchanged and no accessor is wired into [themeData]
  // yet. The behaviour phases replace these bodies with the warm-paper design
  // values — THEME-3 the colours (and wires them into the scheme), THEME-4/5 the
  // type and shape — pinned by their acceptance tests.

  /// The stock Material-3 light theme these shell accessors derive from, so the
  /// shell values track today's look. THEME-3 supersedes the colour getters.
  static final ThemeData _stockLight =
      ThemeData(useMaterial3: true, brightness: Brightness.light);

  /// The recessed surface behind inset/well content (e.g. a readout trough).
  /// Shell: the stock container tone; THEME-3 → the warm-paper `#E9E6DF`.
  static Color get sunkenSurface => _stockLight.colorScheme.surfaceContainer;

  /// The inverted ink-on-paper pair for emphasis surfaces (dark paper, light
  /// ink). Shell: the stock inverse pair; THEME-3 sets the warm-paper values.
  static ({Color paper, Color ink}) get inverted => (
        paper: _stockLight.colorScheme.inverseSurface,
        ink: _stockLight.colorScheme.onInverseSurface,
      );

  /// The uppercase mono micro-label style (provenance badges, mono captions).
  /// Shell: the stock `labelSmall`; THEME-4/5 set Mono family, weight and spacing.
  static TextStyle get monoLabel => _stockLight.textTheme.labelSmall!;

  /// The 1px hairline border weight (dividers). THEME-5 wires it into the theme.
  static const double hairlineBorderWidth = 1.0;

  /// The 2px standard border weight (card / outlined-button sides).
  static const double standardBorderWidth = 2.0;

  /// The 3px emphasis border weight (warning / emphasised surfaces).
  static const double emphasisBorderWidth = 3.0;
}
