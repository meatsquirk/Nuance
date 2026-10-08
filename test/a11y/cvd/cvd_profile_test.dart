import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';

void main() {
  group('CvdProfile', () {
    test('defaults severity to full dichromacy (1.0)', () {
      const profile = CvdProfile(type: CvdType.deutan);
      expect(profile.type, CvdType.deutan);
      expect(profile.severity, 1.0);
    });

    test('keeps an explicitly given type and severity', () {
      const profile = CvdProfile(type: CvdType.protan, severity: 0.6);
      expect(profile.type, CvdType.protan);
      expect(profile.severity, 0.6);
    });

    test('equal fields are == and share a hashCode', () {
      // One built at runtime so the const constructor line is covered.
      // ignore: prefer_const_constructors
      final a = CvdProfile(type: CvdType.tritan, severity: 0.5);
      const b = CvdProfile(type: CvdType.tritan, severity: 0.5);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the type differs', () {
      expect(
        const CvdProfile(type: CvdType.deutan, severity: 0.5) ==
            const CvdProfile(type: CvdType.protan, severity: 0.5),
        isFalse,
      );
    });

    test('differs when the severity differs', () {
      expect(
        const CvdProfile(type: CvdType.deutan, severity: 0.5) ==
            const CvdProfile(type: CvdType.deutan, severity: 0.9),
        isFalse,
      );
    });

    test('is not equal to a non-CvdProfile object', () {
      const profile = CvdProfile(type: CvdType.deutan);
      // ignore: unrelated_type_equality_checks
      final isEqual = profile == 'x';
      expect(isEqual, isFalse);
    });

    test('has a readable toString naming the type and severity', () {
      expect(
        const CvdProfile(type: CvdType.deutan, severity: 0.6).toString(),
        'CvdProfile(deutan, severity 0.6)',
      );
    });
  });

  group('CvdType', () {
    test('covers the three dichromacy classes', () {
      expect(CvdType.values,
          containsAll(<CvdType>[CvdType.protan, CvdType.deutan, CvdType.tritan]));
    });
  });
}
