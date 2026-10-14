import 'package:flutter/material.dart';

import '../a11y/cvd/cvd_profile.dart';
import '../app/build_app.dart';
import '../display/color_simulation.dart';
import '../display/display_scope.dart';
import '../display/display_settings.dart';
import '../domain/provenance.dart';

/// The provenance tier rendered as a shape (an [Icon]) and a decorative tint.
///
/// A provenance tier must stay distinguishable from its *label and icon*, never
/// from colour alone (SI Accessibility, SI D9, bs-10 AC-4): the [iconFor] glyph
/// (a distinct shape per tier) carries the meaning, and the [tintFor] colour is
/// decorative. Because it is only decorative, the tint is routed through the
/// one shared display chokepoint [displayedSwatchColor] (bs-10 D-1) — exactly as
/// `ColorChip`'s swatch is — so with daltonization on it is remapped for the
/// painter's stored profile, while the glyph and the accompanying label stay
/// put. The remap moving the tint therefore never costs the tier its
/// readability.
///
/// Rendered with daltonization (and simulation) off, the tint is the identity of
/// [tintFor] — the colour a trichromat sees. Standalone (no `DisplayScope` /
/// `AppScope` above it, as in a widget test) it falls back to default settings
/// (both views off) and the const default profile, so the tint is the identity
/// there too.
class ProvenanceIcon extends StatelessWidget {
  const ProvenanceIcon({required this.tier, super.key});

  /// The provenance tier whose glyph and tint this renders.
  final ProvenanceTier tier;

  /// The shape that states [tier] — distinct per tier, so the tier reads from
  /// the glyph without relying on colour (AC-4).
  static IconData iconFor(ProvenanceTier tier) {
    switch (tier) {
      case ProvenanceTier.measured:
        return Icons.straighten; // a measuring rule — read from an instrument
      case ProvenanceTier.calculated:
        return Icons.calculate; // derived by calculation
      case ProvenanceTier.estimated:
        return Icons.auto_awesome; // model-seeded, not yet verified
      case ProvenanceTier.confirmed:
        return Icons.verified; // confirmed by the painter
    }
  }

  /// The decorative tint for [tier] — never load-bearing (the glyph and label
  /// carry the meaning), so it is remapped under daltonization like any swatch.
  static Color tintFor(ProvenanceTier tier) {
    switch (tier) {
      case ProvenanceTier.measured:
        return const Color(0xFF1B7F3B); // green
      case ProvenanceTier.calculated:
        return const Color(0xFF1565C0); // blue
      case ProvenanceTier.estimated:
        return const Color(0xFFC62828); // red
      case ProvenanceTier.confirmed:
        return const Color(0xFF6A1B9A); // purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        DisplayScope.maybeOf(context)?.settings ?? const DisplaySettings();
    // The painter's stored profile drives the daltonization remap (bs-10 D-3);
    // the deutan default matches `AppDependencies.cvdProfile` and is used only
    // when this renders standalone (no `AppScope` above it) — where
    // daltonization is off anyway, so the fallback never alters the tint.
    final profile = AppScope.maybeOf(context)?.cvdProfile ??
        const CvdProfile(type: CvdType.deutan);
    // The tint goes through the one shared chokepoint, so daltonization (or a
    // simulation) transforms it exactly as it does every other swatch.
    final tint = displayedSwatchColor(tintFor(tier), settings, profile);
    return Icon(iconFor(tier), color: tint);
  }
}
