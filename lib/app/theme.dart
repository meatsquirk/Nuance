import 'package:flutter/material.dart';

import '../domain/provenance.dart';

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
        // bs-17 THEME-5 (D-7) — the wireframe's shape and border-weight scale,
        // wired into the component themes so every screen inherits it via
        // `Theme.of(context)`: buttons are fully-rounded pills ([StadiumBorder],
        // AC-7); cards are rounded panels at [cardCornerRadius] in the 16–22
        // range (AC-7); dividers are the 1px [hairlineBorderWidth] and the
        // outlined (secondary) pill carries the 2px [standardBorderWidth] side
        // (AC-8). The 3px [emphasisBorderWidth] is drawn by the emphasis/warning
        // components (COMPONENTS, APPLY) off the same token.
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            side: BorderSide(
              color: colorScheme.onSurface,
              width: standardBorderWidth,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardCornerRadius),
          ),
        ),
        dividerTheme: const DividerThemeData(thickness: hairlineBorderWidth),
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

  /// The warm-paper light [TextTheme] (bs-17 THEME-4/5): the stock M3 type scale
  /// rendered in [nextFamily] across every prose/heading/label role, with the
  /// micro-label role ([TextTheme.labelSmall]) switched to the mono micro-label
  /// style ([_monoMicroLabel]) — the single source [monoLabel] reads. (THEME-4
  /// set the families; THEME-5 sets the mono label's weight and letter-spacing.)
  static final TextTheme warmPaperTextTheme =
      _stockLight.textTheme.apply(fontFamily: nextFamily).copyWith(
            labelSmall: _monoMicroLabel,
          );

  /// The micro-label point size (`labelSmall`-scale, the M3 default) — pinned
  /// explicitly because the stock [TextTheme.labelSmall] carries only colour,
  /// not geometry (its `fontSize` is null until the text scaler resolves it), so
  /// [monoLabel] must name the size for its ≈ .06em tracking (and for the
  /// renderer to report one; AC-9).
  static const double _monoLabelFontSize = 11.0;

  /// The mono micro-label style (bs-17): stock [TextTheme.labelSmall] in the
  /// [monoFamily], at [_monoLabelFontSize], **bold (`w700`)** and tracked at
  /// **≈ .06em·fontSize** (THEME-5, AC-9), consumed uppercase by `MonoLabel`.
  static final TextStyle _monoMicroLabel =
      _stockLight.textTheme.labelSmall!.copyWith(
    fontFamily: monoFamily,
    fontSize: _monoLabelFontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.06 * _monoLabelFontSize,
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
  /// THEME-4 set the Mono family ([monoFamily]) via [warmPaperTextTheme]'s
  /// `labelSmall`; THEME-5 set its weight (`w700`) and letter-spacing (≈ .06em).
  static TextStyle get monoLabel => warmPaperTextTheme.labelSmall!;

  /// The rounded-panel corner radius for cards — the wireframe's 16–22 range
  /// (bs-17 THEME-5); wired into `cardTheme` so cards inherit it from the theme.
  static const double cardCornerRadius = 18.0;

  /// The 1px hairline border weight (dividers). THEME-5 wires it into the theme.
  static const double hairlineBorderWidth = 1.0;

  /// The 2px standard border weight (card / outlined-button sides).
  static const double standardBorderWidth = 2.0;

  /// The 3px emphasis border weight (warning / emphasised surfaces).
  static const double emphasisBorderWidth = 3.0;

  // --- Provenance tier tints (bs-17 APPLY-1, D-7) ---
  //
  // The four decorative per-tier provenance tints `ProvenanceIcon.tintFor`
  // reads. The tier's meaning is carried by the glyph and the border-style
  // signature, never by colour alone (D-6; bs-10 AC-4), so the tint is
  // decorative and remapped through the shared display chokepoint. They live
  // here — the single source of palette colour (D-7) — so no widget hardcodes a
  // palette literal (AC-14). The exact hexes are unchanged from the pre-APPLY-1
  // `ProvenanceIcon`, so the bs-10 daltonization / bs-11 contrast behaviour is
  // byte-for-byte preserved.
  static const Color _provMeasured = Color(0xFF1B7F3B); // green
  static const Color _provCalculated = Color(0xFF1565C0); // blue
  static const Color _provEstimated = Color(0xFFC62828); // red
  static const Color _provConfirmed = Color(0xFF6A1B9A); // purple

  /// The decorative tint for a provenance [tier] (bs-17 APPLY-1): the single
  /// palette source `ProvenanceIcon.tintFor` reads (D-7). Decorative only — the
  /// glyph and the border signature carry the tier (D-6), so this tint is safe
  /// to remap under daltonization like any other swatch.
  static Color provenanceTint(ProvenanceTier tier) {
    switch (tier) {
      case ProvenanceTier.measured:
        return _provMeasured;
      case ProvenanceTier.calculated:
        return _provCalculated;
      case ProvenanceTier.estimated:
        return _provEstimated;
      case ProvenanceTier.confirmed:
        return _provConfirmed;
    }
  }

  // --- CVD self-assessment illustration colours (bs-17 APPLY-1, D-7) ---
  //
  // The illustrative original / neutral pair the onboarding result step (bs-07)
  // collapses for the self-calibration demo: the simulated swatch blends from
  // [cvdDemoOriginal] toward [cvdDemoNeutral] as the painter raises the
  // severity. Illustrative sample colours, not app chrome, but held here as the
  // single palette source (D-7) so the screen hardcodes no palette literal
  // (AC-14). Values unchanged from the pre-APPLY-1 `ResultStep`.
  static const Color _cvdDemoOriginal =
      Color(0xFF4CAF50); // representative green
  static const Color _cvdDemoNeutral =
      Color(0xFF9E9E9E); // neutral grey it collapses toward

  /// The illustrative original colour of the CVD self-calibration pair (bs-07).
  static Color get cvdDemoOriginal => _cvdDemoOriginal;

  /// The neutral grey the simulated swatch collapses toward as severity rises
  /// (bs-07).
  static Color get cvdDemoNeutral => _cvdDemoNeutral;

  // --- Live-camera preview surface (bs-19 VIEW-4, D-7/D-8) ---
  //
  // The neutral dark grey shown behind the live-camera preview before a frame
  // streams — a fixed camera-surface tone (a viewfinder reads dark whatever the
  // app theme), not an app-chrome colour. Held here as the single palette
  // source (D-7) so `LiveFrameView` hardcodes no literal (bs-17 AC-14 / D-8);
  // the hex is unchanged from VIEW-1's `0xFF3A3A3A`, so the un-wired preview
  // surface looks byte-for-byte identical.
  static const Color _cameraPlaceholder = Color(0xFF3A3A3A);

  /// The neutral camera-surface grey behind the live-camera preview before a
  /// frame streams (bs-19 VIEW-4). `LiveFrameView` reads this instead of a
  /// hardcoded literal (D-8), so the preview surface is sourced from the theme
  /// authority like every other colour the app paints.
  static Color get cameraPlaceholderSurface => _cameraPlaceholder;
}
