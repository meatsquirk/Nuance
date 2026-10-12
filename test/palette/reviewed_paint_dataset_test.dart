import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/palette/paint_dataset.dart';

/// Guards the bundled reviewed-paint dataset (`assets/paints/reviewed_paints.csv`)
/// against the `kReviewedPaints` const that mirrors it — the const is what runs
/// (the catalogue is served synchronously), so drift between the two would
/// silently diverge from the committed source of truth.
void main() {
  test('kReviewedPaints mirrors assets/paints/reviewed_paints.csv exactly', () {
    final csv = File('assets/paints/reviewed_paints.csv').readAsStringSync();
    final parsed = parseReviewedPaints(csv);
    expect(parsed, kReviewedPaints);
  });
}
