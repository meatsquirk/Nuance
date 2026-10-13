import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';

void main() {
  test('light() captures the stock Material-3 light tokens', () {
    final theme = AppTheme.light();
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
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

  test('themeData reassembles the tokens without changing today\'s look', () {
    final theme = AppTheme.light();
    final data = theme.themeData;
    expect(data.useMaterial3, isTrue);
    expect(data.colorScheme, theme.colorScheme);
    // The reassembled theme matches the stock inline theme buildApp replaced,
    // so A11Y-1 is behaviour-preserving.
    expect(data.colorScheme, ThemeData(useMaterial3: true).colorScheme);
  });

  test('light and dark are distinct themes', () {
    expect(AppTheme.light().colorScheme, isNot(AppTheme.dark().colorScheme));
  });
}
