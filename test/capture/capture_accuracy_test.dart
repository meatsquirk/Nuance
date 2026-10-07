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
}
