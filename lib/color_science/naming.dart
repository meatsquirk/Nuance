import '../domain/color_coordinates.dart';

/// Plain-language colour naming — the COLOR-3 enabler behind
/// [ColorScience.nearestName] (consumed by AC-3 via READOUT-3).
///
/// A sample is named by the nearest entry in a curated named-colour catalogue
/// ([kNamedColors]): the colour name whose canonical CIELAB anchor is the least
/// CIE76 ΔE from the sample. This follows the ISCC-NBS idea of naming a colour
/// by its nearest named region (SI D4, plan D-2) while keeping the names the
/// painter-facing ones the app ships; the catalogue is bundled data
/// (`assets/color/iscc_nbs.csv`) so names stay swappable without touching the
/// colour maths.
///
/// Side-effect free and synchronous, so the Readout screen, the spoken
/// decomposition ([decompose]) and the acceptance suite all share it unchanged.

/// One catalogue entry: a plain-language [name] at its canonical CIELAB anchor.
typedef NamedColor = ({String name, double l, double a, double b});

/// The curated named-colour catalogue, anchored in canonical CIELAB.
///
/// Mirrors `assets/color/iscc_nbs.csv` (same order); the const is what runs and
/// the asset is the committed source of truth, so
/// `test/color_science/named_color_table_test.dart` guards the two against
/// drift. The three acceptance fixtures are anchored at their exact fixture
/// coordinates so a reading of that colour resolves to that name.
const List<NamedColor> kNamedColors = [
  (name: 'Black', l: 10, a: 0, b: 0),
  (name: 'Dark Grey', l: 30, a: 0, b: 0),
  (name: 'Neutral Grey', l: 55, a: 0, b: 0),
  (name: 'Light Grey', l: 80, a: 0, b: 0),
  (name: 'White', l: 96, a: 0, b: 0),
  (name: 'Crimson Red', l: 45, a: 60, b: 35),
  (name: 'Warm Terracotta', l: 58, a: 25.27, b: 22.75),
  (name: 'Bright Orange', l: 66, a: 38, b: 62),
  (name: 'Golden Yellow', l: 80, a: 8, b: 78),
  (name: 'Lemon Yellow', l: 90, a: -8, b: 80),
  (name: 'Deep Olive Green', l: 40, a: -8, b: 24),
  (name: 'Forest Green', l: 45, a: -42, b: 32),
  (name: 'Emerald Green', l: 60, a: -50, b: 20),
  (name: 'Teal', l: 50, a: -28, b: -9),
  (name: 'Sky Blue', l: 72, a: -14, b: -32),
  (name: 'Cool Periwinkle', l: 55, a: -11.63, b: -31.95),
  (name: 'Royal Blue', l: 38, a: 18, b: -52),
  (name: 'Deep Purple', l: 32, a: 38, b: -32),
  (name: 'Magenta', l: 52, a: 68, b: -24),
  (name: 'Rose Pink', l: 70, a: 38, b: 8),
  (name: 'Chocolate Brown', l: 32, a: 18, b: 24),
  (name: 'Cream', l: 92, a: 1, b: 14),
];

/// The plain-language name of the [kNamedColors] entry nearest [lab] in CIELAB.
///
/// "Nearest" is the least CIE76 ΔE (Euclidean distance in L\*a\*b\*); distance
/// is compared squared, since the square root is monotonic and the actual ΔE is
/// never needed. The catalogue is non-empty, so a nearest entry always exists.
String nearestColorName(ColorCoordinates lab) {
  var best = kNamedColors.first;
  var bestDistSq = _distanceSq(lab, best);
  for (final candidate in kNamedColors.skip(1)) {
    final distSq = _distanceSq(lab, candidate);
    if (distSq < bestDistSq) {
      best = candidate;
      bestDistSq = distSq;
    }
  }
  return best.name;
}

/// The squared CIELAB distance between sample [lab] and catalogue entry [c].
double _distanceSq(ColorCoordinates lab, NamedColor c) {
  final dl = lab.lightness - c.l;
  final da = lab.a - c.a;
  final db = lab.b - c.b;
  return dl * dl + da * da + db * db;
}
