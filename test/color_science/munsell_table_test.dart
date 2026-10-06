import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/conversions.dart';

/// Guards the bundled Munsell hue table (`assets/color/munsell.csv`) against the
/// `kMunsellHueAnchors` const that mirrors it — the const is what runs (the
/// interface is synchronous), so drift between the two would silently diverge
/// from the committed source of truth.
void main() {
  test('kMunsellHueAnchors mirrors assets/color/munsell.csv exactly', () {
    final lines = File('assets/color/munsell.csv').readAsLinesSync();
    final rows = <MunsellHueAnchor>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (trimmed == 'hue,cielab_hue_deg') continue; // header
      final parts = trimmed.split(',');
      rows.add((hue: parts[0], angleDeg: double.parse(parts[1])));
    }

    expect(rows, hasLength(kMunsellHueAnchors.length),
        reason: 'asset row count must match the const');
    for (var i = 0; i < rows.length; i++) {
      expect(rows[i].hue, kMunsellHueAnchors[i].hue,
          reason: 'hue at row $i');
      expect(rows[i].angleDeg, kMunsellHueAnchors[i].angleDeg,
          reason: 'angle at row ${rows[i].hue}');
    }
  });
}
