import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';

/// The WCAG 2.2 AA text-contrast floor (mirrors Flutter's
/// `MinimumTextContrastGuideline.kMinimumRatioNormalText` / `…LargeText`, the
/// constants the AC-5 contrast rule evaluates on the rendered screens). Pinned
/// here so the enforcement test states the floor it checks against.
const double _aaNormal = 4.5;
const double _aaLarge = 3.0;

/// The relative luminance of [color] per WCAG 2.x (sRGB → linear → weighted).
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// The WCAG contrast ratio between [a] and [b] (order-independent, 1..21).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

// The wireframe's warm-paper THEME tokens (bs-17 THEME-3, D-2/D-5) the light
// scheme overlays. Mirror the hexes in `lib/app/theme.dart` (and the
// acceptance suite's `WarmPaper` fixture) verbatim, so a wrong token value in
// the theme fails here in the fast unit lane.
const Color _bg = Color(0xFFF3F1EC); // --bg  warm paper background
const Color _sf = Color(0xFFFFFFFF); // --sf  raised surface (paper white)
const Color _sf2 = Color(0xFFE9E6DF); // --sf2 sunken surface (muted paper)
const Color _ink = Color(0xFF16150F); // --ink primary text (near-black)
const Color _mut = Color(0xFF57544C); // --mut secondary text (warm grey)
const Color _ln = Color(0xFFCFCAC0); // --ln  hairline / divider
const Color _acc = Color(0xFF2F55C8); // --acc cobalt accent (CTA)
const Color _accInk = Color(0xFFFFFFFF); // --accInk label on accent (white)

void main() {
  test('light() installs the warm-paper scheme over stock M3 (bs-17 THEME-3)',
      () {
    final theme = AppTheme.light();
    final cs = theme.colorScheme;
    expect(cs.brightness, Brightness.light);

    // The warm-paper surface / neutral / accent roles are the wireframe tokens.
    expect(cs.surface, _bg);
    expect(cs.surfaceContainerLowest, _sf);
    expect(cs.surfaceContainer, _sf2);
    expect(cs.onSurface, _ink);
    expect(cs.onSurfaceVariant, _mut);
    expect(cs.outline, _ln);
    expect(cs.outlineVariant, _ln);
    expect(cs.primary, _acc);
    expect(cs.onPrimary, _accInk);

    // It diverged from the stock M3 light scheme it overlays …
    final stock = ThemeData(useMaterial3: true, brightness: Brightness.light);
    expect(cs.surface, isNot(stock.colorScheme.surface));
    expect(cs.primary, isNot(stock.colorScheme.primary));
    expect(cs.onSurface, isNot(stock.colorScheme.onSurface));
    // … but is an overlay: a role THEME-3 does not touch keeps its stock value.
    expect(cs.secondary, stock.colorScheme.secondary);

    // The type is still stock M3 — THEME-4 sets the Atkinson families.
    expect(theme.textTheme, stock.textTheme);
  });

  test('dark() captures the stock Material-3 dark tokens (dark deferred, D-3)',
      () {
    final theme = AppTheme.dark();
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    expect(theme.colorScheme, base.colorScheme);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.textTheme, base.textTheme);
  });

  test('themeData installs the warm-paper scheme buildApp runs over', () {
    final theme = AppTheme.light();
    final data = theme.themeData;
    expect(data.useMaterial3, isTrue);
    expect(data.colorScheme, theme.colorScheme);
    // The reassembled theme carries the warm-paper scheme buildApp installs on
    // the MaterialApp — the same palette the AC-4 contrast rule runs over …
    expect(data.colorScheme, AppTheme.warmPaperScheme);
    // … no longer the stock M3 scheme adopted before bs-17.
    expect(data.colorScheme, isNot(ThemeData(useMaterial3: true).colorScheme));
  });

  test('light and dark are distinct themes', () {
    expect(AppTheme.light().colorScheme, isNot(AppTheme.dark().colorScheme));
  });

  // AC-4 enforcement (A11Y-3): the shipped theme pins a 48dp padded tap target
  // as the single chokepoint, so every Material control reserves a ≥48dp
  // interactive area regardless of the host platform's default. Pinning it here
  // fails a future edit that drops the floor in the fast unit lane, before the
  // on-device tap-target rule (checks/target.dart) would catch it on a screen.
  test('themeData pins the 48dp padded tap-target size (AC-4 floor)', () {
    expect(
      AppTheme.light().themeData.materialTapTargetSize,
      MaterialTapTargetSize.padded,
    );
  });

  // AC-4 enforcement (bs-17 THEME-3): the shipped warm-paper scheme is the
  // single source the on-device contrast rule (textContrastGuideline) and the
  // acceptance suite's TestAC04 evaluate. Re-prove the WCAG 2.2 AA floor over
  // the warm-paper tokens — bs-11's AA guarantee is preserved by this proof,
  // not by equality to the stock scheme — so a future token edit that drops any
  // meaningful text-on-surface pairing below AA fails here, in the fast unit
  // lane, before it can reach a screen.
  test('the warm-paper scheme meets the WCAG 2.2 AA contrast floor (AC-4)', () {
    final cs = AppTheme.light().colorScheme;

    // The meaningful warm-paper text-on-surface pairings (the same set
    // TestAC04_ContrastFloor measures): ink and muted text on each of the three
    // surface tones, and the accent label on the accent fill.
    final pairings = <String, List<Color>>{
      'ink / background': [cs.onSurface, cs.surface],
      'ink / paper-white': [cs.onSurface, cs.surfaceContainerLowest],
      'ink / sunken': [cs.onSurface, cs.surfaceContainer],
      'muted / background': [cs.onSurfaceVariant, cs.surface],
      'muted / paper-white': [cs.onSurfaceVariant, cs.surfaceContainerLowest],
      'muted / sunken': [cs.onSurfaceVariant, cs.surfaceContainer],
      'accentInk / accent': [cs.onPrimary, cs.primary],
    };

    pairings.forEach((label, pair) {
      final ratio = _contrast(pair[0], pair[1]);
      expect(ratio, greaterThanOrEqualTo(_aaNormal),
          reason: '$label is ${ratio.toStringAsFixed(2)}:1 — below AA '
              '$_aaNormal:1 (a warm-paper edit dropped a pairing)');
    });

    // Sanity: the floor constants are the WCAG 2.2 AA values the rule uses.
    expect(_aaNormal, 4.5);
    expect(_aaLarge, 3.0);
  });

  // bs-17 design-system token accessors (THEME-3 sets the colour ones to the
  // warm-paper values; monoLabel stays stock-derived until THEME-4/5 set the
  // Mono family, weight and spacing). These pin the accessor values and keep
  // the gate at 100% line coverage on theme.dart.
  group('bs-17 design-system token accessors', () {
    final stock = ThemeData(useMaterial3: true, brightness: Brightness.light);

    test('sunkenSurface is the warm-paper sunken tone --sf2', () {
      expect(AppTheme.sunkenSurface, _sf2);
      expect(AppTheme.sunkenSurface, isNot(stock.colorScheme.surfaceContainer));
    });

    test('inverted is the warm-paper dark-paper / light-ink pair', () {
      final pair = AppTheme.inverted;
      expect(pair.paper, _ink); // ink-toned fill --ink
      expect(pair.ink, _bg); // paper-toned text --bg
    });

    test('monoLabel is the stock labelSmall style (Mono set by THEME-4/5)', () {
      expect(AppTheme.monoLabel, stock.textTheme.labelSmall);
    });

    test('border weights are the 1/2/3px design ladder', () {
      expect(AppTheme.hairlineBorderWidth, 1.0);
      expect(AppTheme.standardBorderWidth, 2.0);
      expect(AppTheme.emphasisBorderWidth, 3.0);
    });
  });
}
