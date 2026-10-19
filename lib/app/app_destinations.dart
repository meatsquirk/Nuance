import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

/// The four primary destinations of the app's bottom navigation (bs-18 AC-1,
/// wireframe E44: Capture / Compare / Recipes / Palette).
///
/// A pure presentation identity — each value carries only its [label], its
/// outline [icon] and its filled [selectedIcon] (the non-colour active
/// indicator the nav uses, so the selected destination is distinguishable
/// without relying on colour; bs-11 / bs-18 AC-13) plus a stable [navItemKey]
/// the acceptance suite anchors on. The *screens* each destination shows are
/// supplied separately to [AppShell] by `build_app.dart` (which owns the
/// dependency wiring), so this enum stays free of assembly concerns and the
/// shell stays unit-testable against fake bodies.
///
/// CHROME-2 introduces this as the nav's data model; CHROME-3 (AC-1) finalises
/// the design-system treatment that reads it.
enum AppDestination {
  /// The capture / reading destination (the app's default landing; the Readout
  /// is reached as a sub of it — wireframe §Capture).
  capture(
    label: 'Capture',
    icon: Icons.camera_alt_outlined,
    selectedIcon: Icons.camera_alt,
  ),

  /// The side-by-side comparison destination (bs-03).
  compare(
    label: 'Compare',
    icon: Icons.compare_outlined,
    selectedIcon: Icons.compare,
  ),

  /// The mixing-recipes destination (bs-04).
  recipes(
    label: 'Recipes',
    icon: Icons.science_outlined,
    selectedIcon: Icons.science,
  ),

  /// The palette / projects organising destination (bs-06).
  palette(
    label: 'Palette',
    icon: Icons.palette_outlined,
    selectedIcon: Icons.palette,
  );

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// The short title shown under the nav glyph.
  final String label;

  /// The outline glyph shown when this destination is not selected.
  final IconData icon;

  /// The filled glyph shown when this destination is selected — the non-colour
  /// half of the active indicator (paired with the bold label), so active state
  /// never rests on colour alone (bs-18 AC-13).
  final IconData selectedIcon;

  /// The stable key the acceptance suite uses to find this destination's nav
  /// item, regardless of its position or selected state.
  Key get navItemKey => Key('app-nav-dest-$name');
}
