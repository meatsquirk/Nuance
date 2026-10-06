import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/words.dart';

void main() {
  group('valueWord bands the lightness', () {
    test('each band across 0–100', () {
      expect(valueWord(0), 'very low value');
      expect(valueWord(15), 'very low value');
      expect(valueWord(20), 'low value'); // lower boundary of "low"
      expect(valueWord(30), 'low value');
      expect(valueWord(40), 'middle value'); // lower boundary of "middle"
      expect(valueWord(58), 'middle value');
      expect(valueWord(60), 'high value'); // lower boundary of "high"
      expect(valueWord(70), 'high value');
      expect(valueWord(80), 'very high value'); // lower boundary of "very high"
      expect(valueWord(100), 'very high value');
    });

    test('out-of-range lightness is clamped to the end bands', () {
      expect(valueWord(-5), 'very low value');
      expect(valueWord(120), 'very high value');
    });

    test('the AC-2 contract: L58 "middle", L15 low-not-middle, L90 high-not-middle',
        () {
      expect(valueWord(58).toLowerCase(), contains('middle'));
      expect(valueWord(15).toLowerCase(), matches(RegExp(r'\b(low|dark)\b')));
      expect(valueWord(15).toLowerCase(), isNot(contains('middle')));
      expect(valueWord(90).toLowerCase(), contains('high'));
      expect(valueWord(90).toLowerCase(), isNot(contains('middle')));
    });
  });

  group('temperatureWord splits warm / cool / neutral around the hue circle', () {
    test('warm hues (within 60° of the ~60° warm pole)', () {
      expect(temperatureWord(0), 'warm'); // boundary: warmth == 0.5
      expect(temperatureWord(42), 'warm'); // the terracotta fixture
      expect(temperatureWord(60), 'warm'); // the warm pole
      expect(temperatureWord(120), 'warm'); // boundary: warmth == 0.5
    });

    test('cool hues (within 60° of the ~240° cool pole)', () {
      expect(temperatureWord(180), 'cool'); // boundary: warmth == -0.5
      expect(temperatureWord(240), 'cool'); // the cool pole
      expect(temperatureWord(250), 'cool'); // the cool fixture
      expect(temperatureWord(300), 'cool'); // boundary: warmth == -0.5
    });

    test('the transition bands read neutral', () {
      expect(temperatureWord(150), 'neutral'); // green transition
      expect(temperatureWord(330), 'neutral'); // red-violet transition
    });

    test('hue is normalised (negative and over-360 inputs)', () {
      expect(temperatureWord(-30), 'neutral'); // == 330°
      expect(temperatureWord(402), 'warm'); // == 42°
    });

    test('the AC-4 contract: h42 "warm", h250 "cool"', () {
      expect(temperatureWord(42), 'warm');
      expect(temperatureWord(250), 'cool');
    });
  });

  group('hueFamilyWord names the perceptual hue family', () {
    test('each family around the circle', () {
      expect(hueFamilyWord(10), 'red');
      expect(hueFamilyWord(20), 'orange'); // lower boundary of orange
      expect(hueFamilyWord(42), 'orange'); // the terracotta fixture
      expect(hueFamilyWord(50), 'yellow');
      expect(hueFamilyWord(95), 'green');
      expect(hueFamilyWord(160), 'teal');
      expect(hueFamilyWord(200), 'blue');
      expect(hueFamilyWord(260), 'purple');
      expect(hueFamilyWord(310), 'magenta');
      expect(hueFamilyWord(345), 'red'); // wraps back to red
      expect(hueFamilyWord(350), 'red');
    });

    test('hue is normalised (negative and over-360 inputs)', () {
      expect(hueFamilyWord(-10), 'red'); // == 350°
      expect(hueFamilyWord(360), 'red'); // == 0°
    });

    test('the AC-8 contract: h42 is a warm family ("orange"/"red")', () {
      expect(hueFamilyWord(42), matches(RegExp(r'\b(orange|red)\b')));
    });
  });
}
