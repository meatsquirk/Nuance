import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';

void main() {
  test('approximate is the card-less tier, within ΔE00 8', () {
    expect(CaptureAccuracy.approximate.label, 'Approximate');
    expect(CaptureAccuracy.approximate.maxDeltaE, 8);
  });

  test('calibrated is the reference-card tier, within ΔE00 3', () {
    expect(CaptureAccuracy.calibrated.label, 'Calibrated');
    expect(CaptureAccuracy.calibrated.maxDeltaE, 3);
  });

  test('calibrated promises a tighter bound than approximate', () {
    expect(
      CaptureAccuracy.calibrated.maxDeltaE,
      lessThan(CaptureAccuracy.approximate.maxDeltaE),
    );
  });

  group('AccuracyDowngradeReason (AC-9 seam — bs-12 D-5)', () {
    test('names exactly the spec\'s three poor conditions', () {
      expect(AccuracyDowngradeReason.values, <AccuracyDowngradeReason>[
        AccuracyDowngradeReason.lowLight,
        AccuracyDowngradeReason.exposureUnlocked,
        AccuracyDowngradeReason.missingReferenceCard,
      ]);
    });

    test('each reason carries a user-facing label (words, not colour)', () {
      expect(AccuracyDowngradeReason.lowLight.label,
          'Low light — reading may be approximate');
      expect(AccuracyDowngradeReason.exposureUnlocked.label,
          'Exposure not locked — reading may be approximate');
      expect(AccuracyDowngradeReason.missingReferenceCard.label,
          'No reference card — reading may be approximate');
    });
  });
}
