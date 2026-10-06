import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/naming.dart';

/// Guards the bundled named-colour table (`assets/color/iscc_nbs.csv`) against
/// the `kNamedColors` const that mirrors it — the const is what runs (naming is
/// synchronous), so drift between the two would silently diverge from the
/// committed source of truth.
void main() {
  test('kNamedColors mirrors assets/color/iscc_nbs.csv exactly', () {
    final lines = File('assets/color/iscc_nbs.csv').readAsLinesSync();
    final rows = <NamedColor>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (trimmed == 'name,cielab_l,cielab_a,cielab_b') continue; // header
      final parts = trimmed.split(',');
      rows.add((
        name: parts[0],
        l: double.parse(parts[1]),
        a: double.parse(parts[2]),
        b: double.parse(parts[3]),
      ));
    }

    expect(rows, hasLength(kNamedColors.length),
        reason: 'asset row count must match the const');
    for (var i = 0; i < rows.length; i++) {
      expect(rows[i].name, kNamedColors[i].name, reason: 'name at row $i');
      expect(rows[i].l, kNamedColors[i].l, reason: 'L at ${rows[i].name}');
      expect(rows[i].a, kNamedColors[i].a, reason: 'a at ${rows[i].name}');
      expect(rows[i].b, kNamedColors[i].b, reason: 'b at ${rows[i].name}');
    }
  });
}
