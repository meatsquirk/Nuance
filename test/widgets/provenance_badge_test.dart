import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

/// Pumps a badge under the warm-paper theme (so `onSurface` is the ink token).
Future<void> _pumpThemed(WidgetTester tester, ProvenanceTier tier) {
  return tester.pumpWidget(MaterialApp(
    theme: AppTheme.light().themeData,
    home: Scaffold(body: ProvenanceBadge(provenance: Provenance(tier))),
  ));
}

/// The [BoxDecoration] of the single [Container] the badge renders (the border
/// or fill carrier). The estimated tier renders no such Container (it uses a
/// [CustomPaint]), so callers use [_painters] there instead.
BoxDecoration _decorationOf(WidgetTester tester) => tester
    .widget<Container>(find.descendant(
      of: find.byType(ProvenanceBadge),
      matching: find.byType(Container),
    ))
    .decoration! as BoxDecoration;

/// The custom painters drawn inside the badge (non-null `painter` only).
Iterable<CustomPainter?> _painters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.descendant(
      of: find.byType(ProvenanceBadge),
      matching: find.byType(CustomPaint),
    ))
    .map((c) => c.painter)
    .where((p) => p != null);

void main() {
  testWidgets('renders the tier label as text', (tester) async {
    await _pump(
      tester,
      const ProvenanceBadge(provenance: Provenance(ProvenanceTier.measured)),
    );
    expect(find.text('Measured'), findsOneWidget);
  });

  testWidgets('renders the note beneath the label when present', (tester) async {
    await _pump(
      tester,
      const ProvenanceBadge(
        provenance: Provenance(
          ProvenanceTier.estimated,
          note: 'Seeded by a model. Treat as a starting point.',
        ),
      ),
    );
    expect(find.text('Estimated'), findsOneWidget);
    expect(
      find.text('Seeded by a model. Treat as a starting point.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no note when the provenance has none', (tester) async {
    await _pump(
      tester,
      const ProvenanceBadge(provenance: Provenance(ProvenanceTier.measured)),
    );
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('announces label only when there is no note', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const ProvenanceBadge(provenance: Provenance(ProvenanceTier.measured)),
    );
    expect(tester.getSemantics(find.byType(ProvenanceBadge)).label, 'Measured');
    handle.dispose();
  });

  testWidgets('folds the note into the semantics announcement', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const ProvenanceBadge(
        provenance: Provenance(ProvenanceTier.estimated, note: 'Not verified.'),
      ),
    );
    expect(
      tester.getSemantics(find.byType(ProvenanceBadge)).label,
      'Estimated. Not verified.',
    );
    handle.dispose();
  });

  // --- bs-17 COMPONENTS-5: the colour-independent border-style signature ---

  group('border-style signature (AC-13)', () {
    testWidgets('measured: a solid ink border, no fill', (tester) async {
      await _pumpThemed(tester, ProvenanceTier.measured);
      final dec = _decorationOf(tester);
      expect(dec.color, isNull, reason: 'measured carries no fill');
      final border = dec.border! as Border;
      expect(border.top.style, BorderStyle.solid);
      expect(border.top.color, AppTheme.warmPaperScheme.onSurface,
          reason: 'the border is the theme ink, read from onSurface');
      expect(border.top.width, AppTheme.standardBorderWidth);
      expect(_painters(tester), isEmpty, reason: 'no dashed paint for measured');
    });

    testWidgets('calculated: a sunken fill, no border', (tester) async {
      await _pumpThemed(tester, ProvenanceTier.calculated);
      final dec = _decorationOf(tester);
      expect(dec.color, AppTheme.sunkenSurface,
          reason: 'calculated is filled with the sunken paper token');
      expect(dec.border, isNull, reason: 'calculated carries no border');
      expect(_painters(tester), isEmpty);
    });

    testWidgets('estimated: a dashed border via a custom painter',
        (tester) async {
      await _pumpThemed(tester, ProvenanceTier.estimated);
      expect(_painters(tester), isNotEmpty,
          reason: 'estimated draws a dashed border (a CustomPaint painter)');
      expect(
        find.descendant(
          of: find.byType(ProvenanceBadge),
          matching: find.byType(Container),
        ),
        findsNothing,
        reason: 'estimated uses a painter, not a BoxDecoration border/fill',
      );
    });

    testWidgets('confirmed: an ink fill with paper-toned label', (tester) async {
      await _pumpThemed(tester, ProvenanceTier.confirmed);
      final dec = _decorationOf(tester);
      expect(dec.color, AppTheme.inverted.paper,
          reason: 'confirmed is filled with the inverted ink token');
      expect(dec.border, isNull);
      // The label flips to the paper-toned ink so it stays legible on the fill.
      final label = tester.widget<RichText>(find.descendant(
        of: find.text('Confirmed'),
        matching: find.byType(RichText),
      ));
      expect((label.text as TextSpan).style!.color, AppTheme.inverted.ink);
      expect(_painters(tester), isEmpty);
    });

    testWidgets('the signature varies across the four tiers', (tester) async {
      // measured (solid border) ≠ calculated (fill) ≠ estimated (dashed paint)
      // ≠ confirmed (ink fill): a colour-only differentiation is rejected.
      await _pumpThemed(tester, ProvenanceTier.measured);
      expect(_decorationOf(tester).border, isNotNull);
      expect(_decorationOf(tester).color, isNull);

      await _pumpThemed(tester, ProvenanceTier.calculated);
      expect(_decorationOf(tester).color, AppTheme.sunkenSurface);

      await _pumpThemed(tester, ProvenanceTier.estimated);
      expect(_painters(tester), isNotEmpty);

      await _pumpThemed(tester, ProvenanceTier.confirmed);
      expect(_decorationOf(tester).color, AppTheme.inverted.paper);
    });

    testWidgets('the dashed painter repaints when its inputs change',
        (tester) async {
      // Exercises _DashedBorderPainter.shouldRepaint: re-pump the estimated
      // badge under a theme whose onSurface (the stroke colour) differs, so the
      // CustomPaint receives a new painter and shouldRepaint is evaluated.
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(onSurface: Color(0xFF111111)),
        ),
        home: const Scaffold(
          body: ProvenanceBadge(provenance: Provenance(ProvenanceTier.estimated)),
        ),
      ));
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(onSurface: Color(0xFF222222)),
        ),
        home: const Scaffold(
          body: ProvenanceBadge(provenance: Provenance(ProvenanceTier.estimated)),
        ),
      ));
      // Same colour again → shouldRepaint takes the "unchanged" path too.
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(onSurface: Color(0xFF222222)),
        ),
        home: const Scaffold(
          body: ProvenanceBadge(provenance: Provenance(ProvenanceTier.estimated)),
        ),
      ));
      expect(_painters(tester), isNotEmpty);
    });
  });
}
