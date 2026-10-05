import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';

void main() {
  group('SRGBColor', () {
    test('equal triplets are == and share a hashCode', () {
      const a = SRGBColor(red: 200, green: 120, blue: 90);
      const b = SRGBColor(red: 200, green: 120, blue: 90);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differing channels are not equal', () {
      const base = SRGBColor(red: 200, green: 120, blue: 90);
      expect(base == const SRGBColor(red: 0, green: 120, blue: 90), isFalse);
      expect(base == const SRGBColor(red: 200, green: 0, blue: 90), isFalse);
      expect(base == const SRGBColor(red: 200, green: 120, blue: 0), isFalse);
    });

    test('exposes its channels and a readable toString', () {
      const c = SRGBColor(red: 200, green: 120, blue: 90);
      expect(c.red, 200);
      expect(c.green, 120);
      expect(c.blue, 90);
      expect(c.toString(), 'SRGBColor(200, 120, 90)');
    });
  });

  group('CIELCh', () {
    test('equal values are == and share a hashCode', () {
      const a = CIELCh(lightness: 58, chroma: 34, hue: 42);
      const b = CIELCh(lightness: 58, chroma: 34, hue: 42);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differing components are not equal', () {
      const base = CIELCh(lightness: 58, chroma: 34, hue: 42);
      expect(base == const CIELCh(lightness: 0, chroma: 34, hue: 42), isFalse);
      expect(base == const CIELCh(lightness: 58, chroma: 0, hue: 42), isFalse);
      expect(base == const CIELCh(lightness: 58, chroma: 34, hue: 0), isFalse);
    });

    test('exposes its components and a readable toString', () {
      const c = CIELCh(lightness: 58, chroma: 34, hue: 42);
      expect(c.lightness, 58);
      expect(c.chroma, 34);
      expect(c.hue, 42);
      expect(c.toString(), 'CIELCh(L 58.0, C 34.0, h 42.0)');
    });
  });

  group('MunsellColor', () {
    test('equal values are == and share a hashCode', () {
      const a = MunsellColor(hue: '10R', value: 5.5, chroma: 6);
      const b = MunsellColor(hue: '10R', value: 5.5, chroma: 6);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differing components are not equal', () {
      const base = MunsellColor(hue: '10R', value: 5.5, chroma: 6);
      expect(base == const MunsellColor(hue: '5Y', value: 5.5, chroma: 6),
          isFalse);
      expect(base == const MunsellColor(hue: '10R', value: 1, chroma: 6),
          isFalse);
      expect(base == const MunsellColor(hue: '10R', value: 5.5, chroma: 1),
          isFalse);
    });

    test('notation combines hue, value and chroma; toString wraps it', () {
      const c = MunsellColor(hue: '10R', value: 5.5, chroma: 6);
      expect(c.hue, '10R');
      expect(c.value, 5.5);
      expect(c.chroma, 6);
      expect(c.notation, '10R 5.5/6.0');
      expect(c.toString(), 'MunsellColor(10R 5.5/6.0)');
    });
  });
}
