import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/record/content_hash.dart';

void main() {
  group('contentHashOf', () {
    test('is deterministic — same input hashes to the same value', () {
      expect(contentHashOf('abc'), contentHashOf('abc'));
    });

    test('distinct inputs hash to distinct values', () {
      expect(contentHashOf('abc'), isNot(contentHashOf('abd')));
    });

    test('returns a 16-char lowercase hex string', () {
      final hash = contentHashOf('a mix record canonical form');
      expect(hash.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(hash), isTrue);
    });

    test('hashes the empty string to a stable, well-formed value', () {
      final empty = contentHashOf('');
      expect(empty.length, 16);
      expect(empty, contentHashOf(''));
    });

    test('is sensitive to ordering (not a commutative sum)', () {
      expect(contentHashOf('ab'), isNot(contentHashOf('ba')));
    });
  });
}
