import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/provenance.dart';
import 'provenance_icon.dart';

/// The badge's rounded-corner radius — a small decorative chip, not a card.
const double _badgeRadius = 8.0;

/// A badge that states a reading's [Provenance] tier in words (+ optional note).
///
/// Renders the tier [Provenance.label] (e.g. "Measured", "Estimated") as text
/// beside a tier [ProvenanceIcon] (glyph) — trust is conveyed by the words and
/// the shape, never by colour alone (SI Accessibility, SI D9, bs-10 AC-4). The
/// icon's tint is decorative and routed through the display chokepoint, so
/// daltonization may remap it without the tier losing its readability. When the
/// provenance carries a [Provenance.note] it is shown beneath the tier label and
/// folded into a single semantics announcement.
///
/// **bs-17 COMPONENTS-5 (AC-13):** the badge also carries a colour-independent
/// *border-style signature* per tier, read from the theme — so the tier reads
/// from the glyph AND the border, never from hue alone (the wireframe's PROV
/// treatment):
///   - [ProvenanceTier.measured] — a solid ink border (2px [AppTheme.standardBorderWidth]);
///   - [ProvenanceTier.calculated] — a sunken ([AppTheme.sunkenSurface]) fill;
///   - [ProvenanceTier.estimated] — a dashed ink border (a [CustomPaint]);
///   - [ProvenanceTier.confirmed] — an ink fill ([AppTheme.inverted]), with the
///     label flipped to the paper-toned ink so it stays legible on the dark fill.
/// The glyph and the semantics label are unchanged (D-6), so bs-10/bs-11's
/// provenance assertions are untouched.
class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge({required this.provenance, super.key});

  /// The provenance whose tier (and optional note) this badge states.
  final Provenance provenance;

  @override
  Widget build(BuildContext context) {
    final note = provenance.note;
    final tier = provenance.tier;
    final ink = Theme.of(context).colorScheme.onSurface;

    // The glyph + label (+ note) content — unchanged from bs-10/bs-11 (D-6).
    final Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProvenanceIcon(tier: tier),
        const SizedBox(width: 8),
        // Flexible so a long caveat note wraps within the available width
        // instead of overflowing the row.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provenance.label),
              if (note != null) Text(note),
            ],
          ),
        ),
      ],
    );

    // The colour-independent tier signature (AC-13): one border style per tier,
    // read from the theme. The glyph+label still carry the meaning; the border
    // is the second, non-colour channel.
    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    const borderRadius = BorderRadius.all(Radius.circular(_badgeRadius));
    final Widget decorated;
    switch (tier) {
      case ProvenanceTier.measured:
        // Solid ink border, no fill.
        decorated = Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: AppTheme.standardBorderWidth),
            borderRadius: borderRadius,
          ),
          child: content,
        );
      case ProvenanceTier.calculated:
        // Sunken (muted-paper) fill, no border.
        decorated = Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.sunkenSurface,
            borderRadius: borderRadius,
          ),
          child: content,
        );
      case ProvenanceTier.estimated:
        // Dashed ink border (drawn — Flutter has no native dashed BorderSide).
        decorated = CustomPaint(
          painter: _DashedBorderPainter(
            color: ink,
            strokeWidth: AppTheme.standardBorderWidth,
            radius: _badgeRadius,
          ),
          child: Padding(padding: padding, child: content),
        );
      case ProvenanceTier.confirmed:
        // Ink fill; the label flips to the paper-toned ink so it stays legible.
        final inverted = AppTheme.inverted;
        decorated = Container(
          padding: padding,
          decoration: BoxDecoration(
            color: inverted.paper,
            borderRadius: borderRadius,
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: inverted.ink),
            child: content,
          ),
        );
    }

    return Semantics(
      label: note == null ? provenance.label : '${provenance.label}. $note',
      excludeSemantics: true,
      child: decorated,
    );
  }
}

/// Paints a dashed, rounded-rectangle border — the [ProvenanceTier.estimated]
/// signature. Flutter has no dashed [BorderSide], so the dashes are stroked
/// along the rounded-rect path. Colour-independent: the dashing is the signal,
/// the stroke colour is decorative.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dash = 4.0;
  static const double _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}
