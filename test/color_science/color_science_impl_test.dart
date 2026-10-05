import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

const _lab = ColorCoordinates(lightness: 58, a: 34, b: 30);
const _sample = Sample(
  coordinates: _lab,
  provenance: Provenance(ProvenanceTier.measured),
  name: 'Warm Terracotta',
);

/// Matches an [UnimplementedError] whose message names [member] and [phase].
Matcher _pendingFor(String member, String phase) => throwsA(
      isA<UnimplementedError>().having(
        (e) => e.message,
        'message',
        allOf(contains('ColorScience.$member'), contains(phase)),
      ),
    );

void main() {
  const impl = ColorScienceImpl();

  test('is a ColorScience', () {
    expect(impl, isA<ColorScience>());
  });

  group('every member is pending, pointing at its behaviour phase', () {
    test('COLOR-2 conversions throw UnimplementedError', () {
      expect(() => impl.toSRGB(_lab), _pendingFor('toSRGB', 'COLOR-2'));
      expect(() => impl.toHex(_lab), _pendingFor('toHex', 'COLOR-2'));
      expect(() => impl.toCIELCh(_lab), _pendingFor('toCIELCh', 'COLOR-2'));
      expect(() => impl.toMunsell(_lab), _pendingFor('toMunsell', 'COLOR-2'));
      expect(() => impl.toCIELAB(_lab), _pendingFor('toCIELAB', 'COLOR-2'));
      expect(() => impl.lightness(_lab), _pendingFor('lightness', 'COLOR-2'));
      expect(
          () => impl.grayscaleOf(_lab), _pendingFor('grayscaleOf', 'COLOR-2'));
    });

    test('COLOR-3 naming / words / decomposition throw UnimplementedError', () {
      expect(
          () => impl.nearestName(_lab), _pendingFor('nearestName', 'COLOR-3'));
      expect(() => impl.valueWord(58), _pendingFor('valueWord', 'COLOR-3'));
      expect(() => impl.temperatureWord(42),
          _pendingFor('temperatureWord', 'COLOR-3'));
      expect(() => impl.decompose(_sample), _pendingFor('decompose', 'COLOR-3'));
    });
  });
}
