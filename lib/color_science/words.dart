// Plain-language words for a sample's value, temperature and hue family — the
// COLOR-3 enabler behind ColorScience.valueWord / ColorScience.temperatureWord
// (consumed by AC-2 via READOUT-2 and AC-4 via READOUT-3), plus the hue-family
// word the spoken decomposition states (AC-8).
//
// Each word is a pure function of a primitive (lightness or hue angle), so the
// Readout screen, the spoken decomposition and the acceptance suite share them
// unchanged. All are side-effect free.

/// A plain-language value band for CIELAB [lightness] (L\*, 0–100).
///
/// Five even bands across the clamped lightness range: a middling sample reads
/// "middle value", darker samples "low"/"very low" and lighter ones
/// "high"/"very high" (AC-2 pairs the number with this word and checks it tracks
/// the lightness, not a constant).
String valueWord(double lightness) {
  final l = lightness.clamp(0.0, 100.0);
  if (l < 20) return 'very low value';
  if (l < 40) return 'low value';
  if (l < 60) return 'middle value';
  if (l < 80) return 'high value';
  return 'very high value';
}

/// A plain-language temperature word for a hue angle [hueDeg] (degrees).
///
/// Temperature is measured as the angular distance from two poles: the warm
/// pole (orange, ~60° in CIELAB) and its opposite, the cool pole (blue, ~240°).
/// A hue within 60° of the warm pole reads "warm", within 60° of the cool pole
/// reads "cool", and the transitions between them (the greens and the
/// red-violets) read "neutral" — the neutral axis the temperature is stated
/// relative to. The 60° cut is the cosine-half-angle split (cos 60° = 0.5)
/// computed as an exact arc so the band boundaries are not floating-point
/// fragile.
String temperatureWord(double hueDeg) {
  final h = _normalizeHue(hueDeg);
  if (_arcDegrees(h, 60.0) <= 60.0) return 'warm';
  if (_arcDegrees(h, 240.0) <= 60.0) return 'cool';
  return 'neutral';
}

/// The smaller of the two arcs (degrees, 0–180) between angles [a] and [b].
double _arcDegrees(double a, double b) {
  final d = (a - b).abs() % 360.0;
  return d > 180.0 ? 360.0 - d : d;
}

/// A plain-language hue-family word for a hue angle [hueDeg] (degrees).
///
/// Names the perceptual hue family the angle falls in (red through magenta),
/// so the spoken decomposition can state the hue in words and not only as an
/// angle (AC-8 expects a warm hue family — "orange"/"red" — for the terracotta
/// fixture at ~42°). Achromatic samples are handled by the caller (which has the
/// chroma); this names the hue angle alone.
String hueFamilyWord(double hueDeg) {
  final h = _normalizeHue(hueDeg);
  if (h < 20.0 || h >= 345.0) return 'red';
  if (h < 50.0) return 'orange';
  if (h < 95.0) return 'yellow';
  if (h < 160.0) return 'green';
  if (h < 200.0) return 'teal';
  if (h < 260.0) return 'blue';
  if (h < 310.0) return 'purple';
  return 'magenta';
}

/// [deg] normalised to the 0–360 range.
double _normalizeHue(double deg) {
  final d = deg % 360.0;
  return d < 0 ? d + 360.0 : d;
}
