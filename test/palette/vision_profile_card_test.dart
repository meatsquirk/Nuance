import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/palette/self_assessment_entry_screen.dart';
import 'package:paint_color_assistant/palette/vision_profile_card.dart';

Future<void> _pump(WidgetTester tester, CvdProfile profile) {
  return tester.pumpWidget(
    MaterialApp(
      // Non-const router so its const-constructor coverage comes from router's
      // own tests; the card only calls toSelfAssessment().
      // ignore: prefer_const_constructors
      home: Scaffold(body: VisionProfileCard(profile: profile, router: AppRouter())),
    ),
  );
}

void main() {
  group('VisionProfileCard', () {
    testWidgets('shows the dichromacy class and a moderate severity (AC-11)',
        (tester) async {
      // The suite's AC-11 profile: deutan-type, mid severity.
      await _pump(tester, const CvdProfile(type: CvdType.deutan, severity: 0.6));

      expect(find.byKey(VisionProfileCard.regionKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(VisionProfileCard.regionKey),
          matching: find.textContaining('deutan-type, moderate'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reads "mild" below a third severity', (tester) async {
      await _pump(tester, const CvdProfile(type: CvdType.protan, severity: 0.2));
      expect(find.textContaining('protan-type, mild'), findsOneWidget);
    });

    testWidgets('reads "strong" at a full dichromat severity', (tester) async {
      await _pump(tester, const CvdProfile(type: CvdType.tritan));
      expect(find.textContaining('tritan-type, strong'), findsOneWidget);
    });

    testWidgets('retake navigates to the self-assessment entry (AC-11)',
        (tester) async {
      await _pump(tester, const CvdProfile(type: CvdType.deutan, severity: 0.6));
      expect(find.byType(SelfAssessmentEntryScreen), findsNothing);

      await tester.tap(find.byKey(VisionProfileCard.retakeKey));
      await tester.pumpAndSettle();

      expect(find.byType(SelfAssessmentEntryScreen), findsOneWidget);
      expect(find.byKey(SelfAssessmentEntryScreen.screenKey), findsOneWidget);
    });
  });
}
