import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/seen_set.dart';

import '_support.dart';

void main() {
  test('registers a new record and reports it newly added', () {
    final seen = SeenSet();
    expect(seen.register(record('a')), isTrue);
    expect(seen.contains(record('a')), isTrue);
    expect(seen.length, 1);
  });

  test('a byte-identical record (same content hash) is a dedup drop', () {
    final seen = SeenSet();
    seen.register(record('a'));
    // A distinct object with the same fields hashes the same and is dropped.
    expect(seen.register(record('a')), isFalse);
    expect(seen.length, 1);
  });

  test('distinct records are each remembered', () {
    final seen = SeenSet();
    seen.register(record('a'));
    seen.register(record('b'));
    expect(seen.contains(record('a')), isTrue);
    expect(seen.contains(record('b')), isTrue);
    expect(seen.contains(record('c')), isFalse);
    expect(seen.length, 2);
  });
}
