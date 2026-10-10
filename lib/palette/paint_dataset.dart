import 'dart:convert';

import '../domain/color_coordinates.dart';
import '../domain/paint.dart';
import '../domain/provenance.dart';

/// The shipped **reviewed paint dataset** — the only paints the painter may add
/// to a palette (bs-06 PALETTE-1, plan D-3; spec v1 boundary: no free-hand).
///
/// [kReviewedPaints] is the const the app reads (the catalogue is served
/// synchronously); the bundled asset `assets/paints/reviewed_paints.csv` is the
/// committed source of truth, mirrored verbatim here and guarded against drift
/// by `test/palette/reviewed_paint_dataset_test.dart` through
/// [parseReviewedPaints]. Each entry carries the painter-facing identity the
/// Palette screen lists (brand, line, medium, pigment index) plus its masstone
/// and a provenance tier (G-4: the reviewed dataset defaults to
/// [ProvenanceTier.measured]), which [PaletteController] preserves on add (AC-4).

/// Parses the reviewed-paint-dataset CSV [csv] into [Paint]s (read-only).
///
/// Skips blank lines, `#` comment lines and the single header row, exactly as
/// the sibling `assets/color/*.csv` loaders do; each remaining line is a paint.
/// Empty optional columns (brand / line / pigment index) become null. An
/// unknown [PaintMedium] or [ProvenanceTier] name throws — the dataset is a
/// reviewed artifact, so a malformed row is a build error, not a silent default.
List<Paint> parseReviewedPaints(String csv) {
  const header =
      'id,name,brand,line,medium,pigment_index,provenance,cielab_l,cielab_a,'
      'cielab_b';
  final paints = <Paint>[];
  for (final line in const LineSplitter().convert(csv)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed == header) {
      continue;
    }
    final f = trimmed.split(',');
    paints.add(Paint(
      id: f[0],
      name: f[1],
      brand: f[2].isEmpty ? null : f[2],
      line: f[3].isEmpty ? null : f[3],
      medium: PaintMedium.values.byName(f[4]),
      pigmentIndex: f[5].isEmpty ? null : f[5],
      provenance: ProvenanceTier.values.byName(f[6]),
      masstone: ColorCoordinates(
        lightness: double.parse(f[7]),
        a: double.parse(f[8]),
        b: double.parse(f[9]),
      ),
    ));
  }
  return paints;
}

/// The reviewed paint catalogue the app offers (mirrors the bundled CSV).
const List<Paint> kReviewedPaints = [
  Paint(
    id: 'pw6',
    name: 'Titanium White',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PW6',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
  ),
  Paint(
    id: 'pb29',
    name: 'Ultramarine Blue',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PB29',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 32, a: 18, b: -52),
  ),
  Paint(
    id: 'py35',
    name: 'Cadmium Yellow',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PY35',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 82, a: 8, b: 78),
  ),
  Paint(
    id: 'pr108',
    name: 'Cadmium Red',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PR108',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 48, a: 60, b: 40),
  ),
  Paint(
    id: 'pbk9',
    name: 'Ivory Black',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PBk9',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 12, a: 0, b: 1),
  ),
  Paint(
    id: 'py42',
    name: 'Yellow Ochre',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PY42',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
  ),
  Paint(
    id: 'pbr7',
    name: 'Raw Umber',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PBr7',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 32, a: 8, b: 18),
  ),
  Paint(
    id: 'pg7',
    name: 'Phthalo Green',
    brand: 'Winsor & Newton',
    line: "Artists' Oil",
    medium: PaintMedium.oil,
    pigmentIndex: 'PG7',
    provenance: ProvenanceTier.measured,
    masstone: ColorCoordinates(lightness: 42, a: -42, b: 10),
  ),
];
