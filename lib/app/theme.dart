import 'package:flutter/material.dart';

/// The app's single source of visual tokens — a [ColorScheme], a [TextTheme]
/// and the assembled [ThemeData] — replacing the inline
/// `ThemeData(useMaterial3: true)` that `buildApp` constructed before.
///
/// A11Y-1 introduced this as the single theme chokepoint, deriving the tokens
/// from the stock Material-3 defaults; A11Y-2 verified every meaningful
/// text-on-surface pairing against the WCAG 2.2 AA floor (4.5:1 normal, 3:1
/// large) and pinned that guarantee with a contrast unit test.
///
/// **bs-17 THEME-3** then re-skins the light scheme to the wireframe's
/// *warm-paper* palette (D-2/D-5): the stock M3 light [ColorScheme] with the
/// warm-paper surface / neutral / accent roles overlaid (see [warmPaperScheme]).
/// **bs-17 THEME-4** sets the Atkinson Hyperlegible typeface (see
/// [warmPaperTextTheme]) — prose/headings in [nextFamily], the micro-label in
/// [monoFamily].
/// The AA guarantee is **preserved, not by equality** — `test/app/theme_test.dart`
/// re-proves the WCAG floor over the warm-paper tokens, so a future token edit
/// that drops any pairing below AA still fails the build. Screens read these
/// tokens via `Theme.of(context)` instead of hardcoding colours; A11Y-3 added
/// the 48dp tap-target size ([MaterialTapTargetSize.padded]) here as the single
/// tap-target chokepoint. The dark scheme stays stock (dark wiring deferred,
/// D-3).
class AppTheme {
  const AppTheme._(this.colorScheme, this.textTheme);

  /// The light-mode tokens — the warm-paper [ColorScheme] ([warmPaperScheme],
  /// bs-17 THEME-3) with the Atkinson Hyperlegible [TextTheme]
  /// ([warmPaperTextTheme], bs-17 THEME-4). This is the scheme `buildApp`
  /// installs; the AC-4 contrast rule runs over it.
  factory AppTheme.light() =>
      AppTheme._(warmPaperScheme, warmPaperTextTheme);

  /// The dark-mode tokens. Exposed as API now; `buildApp` still wires only
  /// [AppTheme.light] (the app's current single-theme behaviour), and a later
  /// phase decides dark wiring (D-3) — so the dark scheme stays stock M3.
  factory AppTheme.dark() => AppTheme._fromBrightness(Brightness.dark);

  factory AppTheme._fromBrightness(Brightness brightness) {
    // The stock Material-3 tokens for [brightness]: reassembling a ThemeData
    // from them reproduces Flutter's default look. Used for the dark scheme
    // (D-3); the light scheme is the warm-paper override ([warmPaperScheme]).
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
  /// of the host platform's default. The [colorScheme] carried here is the
  /// warm-paper scheme (bs-17 THEME-3); the on-device tap-target rule
  /// (`checks/target.dart`) enforces the 48dp floor over the real screens.
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: textTheme,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );

  // --- Warm-paper palette tokens (bs-17 THEME-3, D-2/D-5) ---
  //
  // The wireframe's THEME palette — the single source the light [ColorScheme]
  // ([warmPaperScheme]) and the design-token accessors below read. The
  // acceptance suite's `WarmPaper` fixture mirrors these exact hexes.
  static const Color _bg = Color(0xFFF3F1EC); // --bg  warm paper background
  static const Color _sf = Color(0xFFFFFFFF); // --sf  raised surface (paper white)
  static const Color _sf2 = Color(0xFFE9E6DF); // --sf2 sunken surface (muted paper)
  static const Color _ink = Color(0xFF16150F); // --ink primary text (near-black)
  static const Color _mut = Color(0xFF57544C); // --mut secondary text (warm grey)
  static const Color _ln = Color(0xFFCFCAC0); // --ln  hairline / divider
  static const Color _acc = Color(0xFF2F55C8); // --acc cobalt accent (CTA)
  static const Color _accInk = Color(0xFFFFFFFF); // --accInk label on accent

  /// The warm-paper light [ColorScheme] (bs-17 THEME-3): the stock M3 light
  /// scheme with the wireframe's warm-paper surface, neutral and accent roles
  /// overlaid. Roles that are not overlaid keep their stock M3 values (each
  /// already clears WCAG AA). The AA floor over the overlaid pairings is
  /// re-proven in `test/app/theme_test.dart`.
  static final ColorScheme warmPaperScheme = _stockLight.colorScheme.copyWith(
    surface: _bg,
    surfaceContainerLowest: _sf,
    surfaceContainer: _sf2,
    onSurface: _ink,
    onSurfaceVariant: _mut,
    outline: _ln,
    outlineVariant: _ln,
    primary: _acc,
    onPrimary: _accInk,
  );

  // --- Atkinson Hyperlegible typeface (bs-17 THEME-4, D-1) ---
  //
  // The bundled offline font families (declared in `pubspec.yaml`, THEME-1).
  // These exact strings are what the installed [TextTheme] carries and what the
  // acceptance suite's AC-5/AC-6 tests match against.

  /// The prose / heading family — Atkinson Hyperlegible Next.
  static const String nextFamily = 'Atkinson Hyperlegible Next';

  /// The micro-label / numeric-readout family — Atkinson Hyperlegible Mono.
  static const String monoFamily = 'Atkinson Hyperlegible Mono';

  /// The warm-paper light [TextTheme] (bs-17 THEME-4): the stock M3 type scale
  /// rendered in [nextFamily] across every prose/heading/label role, with the
  /// micro-label role ([TextTheme.labelSmall]) switched to [monoFamily] — the
  /// single source [monoLabel] reads. (THEME-5 sets the mono label's weight and
  /// letter-spacing; THEME-4 sets only the families.)
  static final TextTheme warmPaperTextTheme =
      _stockLight.textTheme.apply(fontFamily: nextFamily).copyWith(
            labelSmall: _stockLight.textTheme.labelSmall!
                .copyWith(fontFamily: monoFamily),
          );

  // --- Design-system token accessors (bs-17) ---
  //
  // The visual design system (bs-17) introduces a recessed "sunken" surface, an
  // inverted ink/paper pair, a mono micro-label style and three border weights.
  // None map to a clean [ColorScheme] / [TextTheme] slot, so they are exposed
  // here as the single source COMPONENTS (PillButton/SurfaceCard/MonoLabel) and
  // the acceptance suite read (D-7).
  //
  // **THEME-3** sets the colour accessors ([sunkenSurface], [inverted]) to the
  // warm-paper values; **THEME-4** sets [monoLabel] to the Mono family (via
  // [warmPaperTextTheme]); THEME-5 sets its weight and letter-spacing.

  /// The stock Material-3 light theme the type accessor and the dark scheme
  /// derive from (and the base [warmPaperScheme] overlays its warm-paper roles
  /// onto).
  static final ThemeData _stockLight =
      ThemeData(useMaterial3: true, brightness: Brightness.light);

  /// The recessed surface behind inset/well content (e.g. a readout trough) —
  /// the warm-paper sunken tone `--sf2` (bs-17 THEME-3).
  static Color get sunkenSurface => _sf2;

  /// The inverted ink-on-paper pair for emphasis surfaces (dark paper, light
  /// ink): `paper` is the ink-toned fill `--ink`, `ink` the paper-toned text
  /// `--bg` (bs-17 THEME-3). COMPONENTS-4's inverted [SurfaceCard] reads this.
  static ({Color paper, Color ink}) get inverted => (paper: _ink, ink: _bg);

  /// The uppercase mono micro-label style (provenance badges, mono captions).
  /// THEME-4 sets the Mono family ([monoFamily]) via [warmPaperTextTheme]'s
  /// `labelSmall`; THEME-5 sets the weight and letter-spacing.
  static TextStyle get monoLabel => warmPaperTextTheme.labelSmall!;

  /// The 1px hairline border weight (dividers). THEME-5 wires it into the theme.
  static const double hairlineBorderWidth = 1.0;

  /// The 2px standard border weight (card / outlined-button sides).
  static const double standardBorderWidth = 2.0;

  /// The 3px emphasis border weight (warning / emphasised surfaces).
  static const double emphasisBorderWidth = 3.0;
}
