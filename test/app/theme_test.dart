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

void main() {
  test('light() adopts the stock Material-3 light tokens', () {
    final theme = AppTheme.light();
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    // A11Y-2 adopts the stock M3 light scheme unchanged — it already meets AA
    // (asserted below), so there is nothing to recolour.
    expect(theme.colorScheme, base.colorScheme);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.textTheme, base.textTheme);
  });

  test('dark() captures the stock Material-3 dark tokens', () {
    final theme = AppTheme.dark();
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    expect(theme.colorScheme, base.colorScheme);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.textTheme, base.textTheme);
  });

  test('themeData reassembles the tokens buildApp installs', () {
    final theme = AppTheme.light();
    final data = theme.themeData;
    expect(data.useMaterial3, isTrue);
    expect(data.colorScheme, theme.colorScheme);
    // The reassembled theme matches the scheme buildApp installs on the
    // MaterialApp — the same palette the AC-5 contrast rule runs over.
    expect(data.colorScheme, ThemeData(useMaterial3: true).colorScheme);
  });

  test('light and dark are distinct themes', () {
    expect(AppTheme.light().colorScheme, isNot(AppTheme.dark().colorScheme));
  });

  // AC-5 enforcement (A11Y-2): the shipped light scheme is the single source
  // the on-device contrast rule (textContrastGuideline) evaluates. Pin the AA
  // floor for every meaningful text-on-surface pairing so a future token edit
  // that drops one below WCAG 2.2 AA fails here, in the fast unit lane, before
  // it can reach a screen.
  test('light scheme meets the WCAG 2.2 AA contrast floor on every text pairing',
      () {
    final cs = AppTheme.light().colorScheme;

    // Normal-weight body/label text must clear 4.5:1 on its surface.
    final normal = <String, List<Color>>{
      'onSurface / surface': [cs.onSurface, cs.surface],
      'onSurfaceVariant / surface': [cs.onSurfaceVariant, cs.surface],
      'onSurfaceVariant / surfaceContainerHighest': [
        cs.onSurfaceVariant,
        cs.surfaceContainerHighest,
      ],
      'onSurface / surfaceContainerHighest': [
        cs.onSurface,
        cs.surfaceContainerHighest,
      ],
      'onPrimary / primary': [cs.onPrimary, cs.primary],
      'onPrimaryContainer / primaryContainer': [
        cs.onPrimaryContainer,
        cs.primaryContainer,
      ],
      'onSecondary / secondary': [cs.onSecondary, cs.secondary],
      'onSecondaryContainer / secondaryContainer': [
        cs.onSecondaryContainer,
        cs.secondaryContainer,
      ],
      'onTertiaryContainer / tertiaryContainer': [
        cs.onTertiaryContainer,
        cs.tertiaryContainer,
      ],
      'onError / error': [cs.onError, cs.error],
      'onErrorContainer / errorContainer': [
        cs.onErrorContainer,
        cs.errorContainer,
      ],
      'error / surface': [cs.error, cs.surface],
      'primary / surface': [cs.primary, cs.surface],
      'onInverseSurface / inverseSurface': [
        cs.onInverseSurface,
        cs.inverseSurface,
      ],
    };

    normal.forEach((label, pair) {
      final ratio = _contrast(pair[0], pair[1]);
      expect(ratio, greaterThanOrEqualTo(_aaNormal),
          reason: '$label is ${ratio.toStringAsFixed(2)}:1 — below AA $_aaNormal:1');
    });

    // Sanity: the floor constants are the WCAG 2.2 AA values the rule uses.
    expect(_aaNormal, 4.5);
    expect(_aaLarge, 3.0);
  });
}
