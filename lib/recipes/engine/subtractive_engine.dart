import 'dart:math' as math;

import '../../color_science/words.dart' show temperatureWord;
import '../../compare/difference.dart' show deltaE00;
import '../../domain/color_coordinates.dart';
import '../../domain/paint.dart';
import '../../domain/sample.dart';
import '../palette.dart';
import 'mixing_engine.dart';

/// The v1 [MixingEngine]: a subtractive, Kubelka–Munk–class model (bs-04 D-2,
/// SI D3 — the Spectral.js / KM basis).
///
/// **Forward** (ENGINE-2): each paint's masstone CIELAB is lifted to a smooth
/// reflectance spectrum (an illuminant-E, CIE-1931 pipeline, [_Spectrum.ofLab]);
/// a mix combines the paints' reflectances by the single-constant Kubelka–Munk
/// rule — volume-weighted K/S summed, inverted back to reflectance — and the
/// mixed spectrum is rendered to CIELAB. Mixing in K/S (not by averaging Lab) is
/// what makes a yellow and a blue darken toward green: the subtractive behaviour
/// the feature needs. **Inverse** (ENGINE-2): the palette's paints are
/// enumerated in subsets by ascending size (within a medium — recipes never span
/// media), each subset's volumes optimised to minimise [deltaE00] against the
/// target, and the best distinct mixes returned best-first with their parts and
/// predicted colour.
///
/// The predicted L/C/h are illustrative (G-4): the engine asserts behavioural
/// properties, not pinned literals. The per-recipe verdict (ENGINE-3), the "a
/// touch of" trace and muddying flags (ENGINE-4) and the out-of-gamut marking
/// (ENGINE-5) layer on top of this forward + inverse; the per-medium wet→dry
/// transform (ENGINE-6) is `forward(..., dry: true)`. The measured-pigment
/// engine is the deferred swap-in behind the same [MixingEngine] interface.
///
/// A stateless, `const` engine wired in as the default
/// `AppDependencies.mixingEngine`.
class SubtractiveMixingEngine implements MixingEngine {
  /// Creates the (stateless, `const`) v1 engine.
  const SubtractiveMixingEngine();

  /// A component whose optimised volume share falls at or below this is dropped
  /// from the recipe (and the rest renormalised) so every reported part is
  /// genuinely present — the inverse search drives spurious paints to zero.
  static const double _volumeEpsilon = 1e-3;

  /// A paint whose masstone chroma is below this is treated as (near-)achromatic
  /// when judging muddying (AC-8 / D-9): white, black and the greys carry no
  /// meaningful hue temperature, so they never make a mix cross complements.
  static const double _achromaticChroma = 10.0;

  /// The static technique note shown with a trace component (AC-7 / D-12).
  ///
  /// Measuring a sub-2% share by volume is not realistic at the bench, so the
  /// recipe expresses it as "a touch of" and explains how to add it instead of
  /// reporting an unusable fraction.
  static const String _traceTechniqueNote =
      'Measuring so little by volume is not practical — add a little at a time '
      'and mix fully before judging the colour.';

  /// Two recipes whose ΔE00 differ by less than this count as equally close for
  /// ranking (AC-6 / D-8): ΔE00 ≈ 1 is a just-noticeable difference (the same
  /// perceptual grain the comparison verdict bands use), so at a nearer spacing
  /// the ranking is free to prefer the cleaner mix rather than split hairs over
  /// a difference no eye can see.
  static const double _tieGrain = 1.0;

  /// The plain-language match verdict band edges for a recipe's ΔE00 (D-7; AC-5),
  /// in ascending distance. Each entry pairs the exclusive upper bound of a band
  /// with the word shown for a ΔE00 below it; a value at or above the last bound
  /// is [_verdictAbove]. A close recipe (ΔE00 ≤ 5, the in-gamut range) reads at
  /// least "very close" — the phrase the spec pins (AC-5) — and a farther mix
  /// reads a plainly worse band, so the verdict tracks the distance rather than
  /// being a constant string.
  static const List<(double, String)> _verdictBands = [
    (1.0, 'an almost exact match'),
    (5.0, 'very close'),
    (10.0, 'close'),
    (20.0, 'in the ballpark'),
  ];

  /// The verdict for a ΔE00 at or above the largest [_verdictBands] bound.
  static const String _verdictAbove = 'far off';

  /// The plain-language match verdict for a recipe's ΔE00 (D-7; AC-5).
  static String _verdictBand(double deltaE00) {
    for (final (bound, word) in _verdictBands) {
      if (deltaE00 < bound) return word;
    }
    return _verdictAbove;
  }

  @override
  ColorCoordinates forward(Map<Paint, double> partsByVolume, {bool dry = false}) {
    if (partsByVolume.isEmpty) {
      throw ArgumentError.value(
          partsByVolume, 'partsByVolume', 'a mix needs at least one paint');
    }
    final paints = partsByVolume.keys.toList();
    final weights = [for (final p in paints) partsByVolume[p]!];
    for (final w in weights) {
      if (w < 0) {
        throw ArgumentError.value(w, 'partsByVolume', 'a part cannot be negative');
      }
    }
    if (weights.fold<double>(0, (s, w) => s + w) <= 0) {
      throw ArgumentError.value(partsByVolume, 'partsByVolume',
          'the parts must sum to a positive volume');
    }
    final spectra = [for (final p in paints) _Spectrum.ofLab(p.masstone)];
    final wet = _mix(spectra, weights);
    // The dry prediction (AC-10) is the wet colour shifted by the per-medium
    // drying transform — a pure function of the wet prediction and the medium.
    return dry ? _dryPrediction(wet, _singleMedium(paints)) : wet;
  }

  /// The single [PaintMedium] all [paints] share.
  ///
  /// Recipes never span media (engine-design cross-medium rule), so a dry
  /// prediction is only defined for a single-medium mix; a mixed-medium map is
  /// rejected rather than dried under one arbitrary medium's constants.
  static PaintMedium _singleMedium(List<Paint> paints) {
    final medium = paints.first.medium;
    for (final paint in paints) {
      if (paint.medium != medium) {
        throw ArgumentError.value(paints, 'partsByVolume',
            'a dry prediction needs a single-medium mix (recipes never span media)');
      }
    }
    return medium;
  }

  /// The predicted **dry** colour of a mix whose wet colour is [wet], under
  /// [medium] (AC-10 / D-11).
  ///
  /// Paint dries darker and slightly more muted as its vehicle leaves — the
  /// wet L\* and a\*/b\* are scaled toward the darker, lower-chroma dry state.
  /// Oil shifts far less than acrylic on its first-shot dry (D-11), so its
  /// factor is the smaller. A pure function of [wet] and [medium]: no solve, no
  /// spectra — the exact dry L/C/h are illustrative (G-4), the behavioural
  /// property is the darkening shift.
  static ColorCoordinates _dryPrediction(
      ColorCoordinates wet, PaintMedium medium) {
    final shift = switch (medium) {
      PaintMedium.acrylic => _acrylicDryingShift,
      PaintMedium.oil => _oilDryingShift,
    };
    final keep = 1 - shift;
    return ColorCoordinates(
      lightness: wet.lightness * keep,
      a: wet.a * keep,
      b: wet.b * keep,
    );
  }

  /// Acrylic dries noticeably darker (D-11) — the larger first-shot shift.
  static const double _acrylicDryingShift = 0.04;

  /// Oil shifts far less on drying than acrylic (D-11) — the smaller shift.
  static const double _oilDryingShift = 0.015;

  @override
  List<Recipe> inverse(Sample target, PaintPalette palette, MixOptions opts) {
    if (palette.paints.isEmpty) return const [];

    // Recipes never span media (engine-design cross-medium rule): solve within
    // each medium group and pool the candidates.
    final byMedium = <PaintMedium, List<Paint>>{};
    for (final paint in palette.paints) {
      (byMedium[paint.medium] ??= <Paint>[]).add(paint);
    }

    final targetLab = target.coordinates;
    // Keep the best candidate per distinct set of paints actually used.
    final bestByPaintSet = <String, Recipe>{};

    byMedium.forEach((medium, group) {
      final spectra = {for (final p in group) p: _Spectrum.ofLab(p.masstone)};
      final maxSize = math.min(opts.maxPaints, group.length);
      for (var size = 1; size <= maxSize; size++) {
        for (final subset in _combinations(group, size)) {
          final subSpectra = [for (final p in subset) spectra[p]!];
          final volumes = _optimise(subSpectra, targetLab);

          // Drop the paints the search zeroed out, then renormalise so the
          // reported parts are all positive and sum to one.
          final kept = <Paint>[];
          final keptVolumes = <double>[];
          final keptSpectra = <_Spectrum>[];
          for (var i = 0; i < subset.length; i++) {
            if (volumes[i] > _volumeEpsilon) {
              kept.add(subset[i]);
              keptVolumes.add(volumes[i]);
              keptSpectra.add(subSpectra[i]);
            }
          }
          if (kept.isEmpty) continue;
          final total = keptVolumes.fold<double>(0, (s, v) => s + v);

          final predicted = _mix(keptSpectra, keptVolumes);
          final de = deltaE00(predicted, targetLab);
          final components = [
            for (var i = 0; i < kept.length; i++)
              _component(kept[i], keptVolumes[i] / total, opts),
          ];
          final recipe = Recipe(
            medium: medium,
            components: components,
            predictedColor: predicted,
            deltaE00: de,
            verdict: _verdictBand(de),
            muddying: _isMuddying(kept),
          );

          final key = (kept.map((p) => p.id).toList()..sort()).join('+');
          final existing = bestByPaintSet[key];
          if (existing == null || de < existing.deltaE00) {
            bestByPaintSet[key] = recipe;
          }
        }
      }
    });

    final recipes = bestByPaintSet.values.toList()
      ..sort((a, b) => _rankCompare(a, b, targetLab));
    if (recipes.length > opts.topK) {
      return recipes.sublist(0, opts.topK);
    }
    return recipes;
  }

  /// The CIELAB of mixing [spectra] at the given [volumes] (any non-negative
  /// scale; only the ratios matter), under the single-constant Kubelka–Munk rule.
  ColorCoordinates _mix(List<_Spectrum> spectra, List<double> volumes) {
    final total = volumes.fold<double>(0, (s, v) => s + v);
    final bands = _Spectral.bandCount;
    final reflectance = List<double>.filled(bands, 0);
    for (var b = 0; b < bands; b++) {
      var ksMix = 0.0;
      for (var i = 0; i < spectra.length; i++) {
        ksMix += (volumes[i] / total) * spectra[i].ks[b];
      }
      // Invert K/S back to reflectance: R = 1 + K/S − sqrt((K/S)² + 2·K/S).
      final r = 1 + ksMix - math.sqrt(ksMix * ksMix + 2 * ksMix);
      reflectance[b] = r.clamp(_Spectral.minReflectance, 1.0);
    }
    return _Spectral.reflectanceToLab(reflectance);
  }

  /// The volume shares (summing to one, index-aligned with [spectra]) that bring
  /// the mix nearest [target] by [deltaE00].
  ///
  /// A single paint has the trivial share; otherwise a coarse search over the
  /// composition simplex seeds a coordinate-descent refinement that shifts
  /// volume between paints at a shrinking step.
  List<double> _optimise(List<_Spectrum> spectra, ColorCoordinates target) {
    final n = spectra.length;
    if (n == 1) return const [1.0];

    double cost(List<double> w) => deltaE00(_mix(spectra, w), target);

    // Coarse simplex grid.
    List<double> best = List<double>.filled(n, 1 / n);
    var bestCost = cost(best);
    _simplexGrid(n, _gridSteps, (w) {
      final c = cost(w);
      if (c < bestCost) {
        bestCost = c;
        best = w;
      }
    });

    // Coordinate descent: move `step` of volume from one paint to another while
    // it helps; halve the step when a full sweep finds no improvement.
    var step = 1 / _gridSteps;
    while (step > _refineFloor) {
      var improved = false;
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          if (i == j || best[j] < step) continue;
          final trial = List<double>.of(best);
          trial[i] += step;
          trial[j] -= step;
          final c = cost(trial);
          if (c < bestCost - 1e-9) {
            bestCost = c;
            best = trial;
            improved = true;
          }
        }
      }
      if (!improved) step /= 2;
    }
    return best;
  }

  /// Compositions of the inverse search's coarse simplex grid use this many
  /// divisions.
  static const int _gridSteps = 12;

  /// Coordinate descent stops once the volume step falls below this.
  static const double _refineFloor = 1e-3;

  /// Calls [visit] with every composition of [n] non-negative volume shares that
  /// sum to one, on a grid of [steps] divisions.
  static void _simplexGrid(int n, int steps, void Function(List<double>) visit) {
    void recur(int index, int remaining, List<int> acc) {
      if (index == n - 1) {
        visit([for (final a in acc) a / steps, remaining / steps]);
        return;
      }
      for (var v = 0; v <= remaining; v++) {
        recur(index + 1, remaining - v, [...acc, v]);
      }
    }

    recur(0, steps, const []);
  }

  /// Every size-[k] subset of [items], in a stable order.
  static List<List<Paint>> _combinations(List<Paint> items, int k) {
    final result = <List<Paint>>[];
    void recur(int start, List<Paint> acc) {
      if (acc.length == k) {
        result.add(acc);
        return;
      }
      for (var i = start; i < items.length; i++) {
        recur(i + 1, [...acc, items[i]]);
      }
    }

    recur(0, const []);
    return result;
  }

  /// Ranks two candidate recipes against [target] (AC-6 / D-8): best-first by
  /// ΔE00, with a tie-break toward the *cleaner* mix.
  ///
  /// The ΔE00 is bucketed to [_tieGrain], so two recipes closer than a
  /// just-noticeable difference land in the same band and count as equally
  /// close. Within a band the ranking prefers, in order, fewer paints, then the
  /// mix that adds less chroma over the target (the cleaner, less muddy one),
  /// then the finer ΔE00 — so a cleaner two-paint mix ranks above a muddier
  /// four-paint mix at a similar distance. Bucketing keeps this a total order
  /// (the comparison is lexicographic over crisp keys, never a fuzzy
  /// within-tolerance equality), so the sort stays deterministic.
  static int _rankCompare(Recipe a, Recipe b, ColorCoordinates target) {
    final bandA = (a.deltaE00 / _tieGrain).floor();
    final bandB = (b.deltaE00 / _tieGrain).floor();
    if (bandA != bandB) return bandA.compareTo(bandB);
    final byCount = a.components.length.compareTo(b.components.length);
    if (byCount != 0) return byCount;
    final byChroma = _addedChroma(a.predictedColor, target)
        .compareTo(_addedChroma(b.predictedColor, target));
    if (byChroma != 0) return byChroma;
    return a.deltaE00.compareTo(b.deltaE00);
  }

  /// How much chroma [predicted] adds over [target] (never below zero) — the
  /// "added chroma" the D-8 tie-break prefers to keep low, since an
  /// over-saturated mix is the muddier one at a similar distance.
  static double _addedChroma(ColorCoordinates predicted, ColorCoordinates target) {
    double chroma(ColorCoordinates c) => math.sqrt(c.a * c.a + c.b * c.b);
    final added = chroma(predicted) - chroma(target);
    return added > 0 ? added : 0;
  }

  /// Builds a [RecipeComponent] for [paint] at [share] of the mix, flagging it a
  /// trace — "a touch of" plus a static technique note (AC-7 / D-12) — when its
  /// share falls below [MixOptions.traceThreshold].
  static RecipeComponent _component(Paint paint, double share, MixOptions opts) {
    final isTrace = share < opts.traceThreshold;
    return RecipeComponent(
      paint: paint,
      partsFraction: share,
      isTrace: isTrace,
      techniqueNote: isTrace ? _traceTechniqueNote : null,
    );
  }

  /// Whether a mix of [paints] is liable to muddy: it spans a complementary hue
  /// pair (AC-8 / D-9), i.e. it combines a chromatic **warm** paint with a
  /// chromatic **cool** one, the opposite temperature camps of the warm/cool
  /// model in `words.dart`. Near-achromatic paints (white, black, greys) carry
  /// no meaningful temperature and are ignored, so lightening or darkening a
  /// single hue never counts as a crossing.
  static bool _isMuddying(List<Paint> paints) {
    var hasWarm = false;
    var hasCool = false;
    for (final paint in paints) {
      final lab = paint.masstone;
      if (math.sqrt(lab.a * lab.a + lab.b * lab.b) < _achromaticChroma) {
        continue;
      }
      var hue = math.atan2(lab.b, lab.a) * 180 / math.pi;
      if (hue < 0) hue += 360;
      switch (temperatureWord(hue)) {
        case 'warm':
          hasWarm = true;
        case 'cool':
          hasCool = true;
      }
    }
    return hasWarm && hasCool;
  }
}

/// A paint's Kubelka–Munk K/S spectrum, precomputed once per paint so the
/// inverse search's inner loop only mixes and renders.
class _Spectrum {
  _Spectrum._(this.ks);

  /// K/S = (1 − R)² / (2R) per band — the quantity Kubelka–Munk mixes linearly.
  final List<double> ks;

  /// Lifts a masstone CIELAB to a reflectance spectrum (exact in XYZ) and its
  /// per-band K/S.
  factory _Spectrum.ofLab(ColorCoordinates lab) {
    final reflectance = _Spectral.labToReflectance(lab);
    final ks = [
      for (final r in reflectance) (1 - r) * (1 - r) / (2 * r),
    ];
    return _Spectrum._(ks);
  }
}

/// The illuminant-E, CIE-1931 spectral pipeline shared by the engine: analytic
/// colour-matching functions, a smooth three-primary reflectance basis, and the
/// reflectance ↔ CIELAB conversions built on them.
///
/// Illuminant E (equal energy) keeps the pipeline self-contained — no tabulated
/// SPD — and self-consistent: a single paint's reconstructed reflectance renders
/// back to its own masstone, so a 100%-of-one-paint "mix" reproduces that paint
/// and intermediate mixes interpolate in reflectance (the subtractive
/// behaviour). The CIELAB values are internally consistent and compared only to
/// one another via [deltaE00]; the pinned spec L/C/h are illustrative (G-4).
abstract final class _Spectral {
  static const double _lambdaMin = 380;
  static const double _lambdaMax = 730;
  static const double _lambdaStep = 10;

  /// A mixed reflectance is floored here so K/S stays finite (R → 0 ⇒ K/S → ∞).
  static const double minReflectance = 1e-4;

  /// The number of sampled wavelength bands.
  static final int bandCount = _lambdas.length;

  static final List<double> _lambdas = () {
    final out = <double>[];
    for (var l = _lambdaMin; l <= _lambdaMax + 1e-9; l += _lambdaStep) {
      out.add(l);
    }
    return out;
  }();

  // CIE 1931 2° colour-matching functions, analytic multi-lobe-Gaussian fit
  // (Wyman, Sloan & Shirley, JCGT 2013) — no tables.
  static double _piecewiseGaussian(double x, double mu, double s1, double s2) {
    final t = (x - mu) * (x < mu ? s1 : s2);
    return math.exp(-0.5 * t * t);
  }

  static double _xBar(double l) =>
      1.056 * _piecewiseGaussian(l, 599.8, 0.0264, 0.0323) +
      0.362 * _piecewiseGaussian(l, 442.0, 0.0624, 0.0374) -
      0.065 * _piecewiseGaussian(l, 501.1, 0.0490, 0.0382);

  static double _yBar(double l) =>
      0.821 * _piecewiseGaussian(l, 568.8, 0.0213, 0.0247) +
      0.286 * _piecewiseGaussian(l, 530.9, 0.0613, 0.0322);

  static double _zBar(double l) =>
      1.217 * _piecewiseGaussian(l, 437.0, 0.0845, 0.0278) +
      0.681 * _piecewiseGaussian(l, 459.0, 0.0385, 0.0725);

  static final List<double> _x = [for (final l in _lambdas) _xBar(l)];
  static final List<double> _y = [for (final l in _lambdas) _yBar(l)];
  static final List<double> _z = [for (final l in _lambdas) _zBar(l)];

  // Three broad, overlapping Gaussian reflectance primaries (red / green / blue
  // bands). Their overlap is what lets a yellow (red+green reflectance) and a
  // blue mix down toward green rather than to a flat grey.
  static double _primary(double l, double centre) {
    final t = (l - centre) / _basisSigma;
    return math.exp(-0.5 * t * t);
  }

  static const double _basisSigma = 65;
  static final List<double> _basisR = [for (final l in _lambdas) _primary(l, 610)];
  static final List<double> _basisG = [for (final l in _lambdas) _primary(l, 545)];
  static final List<double> _basisB = [for (final l in _lambdas) _primary(l, 465)];

  /// Normaliser so a perfect reflector (R ≡ 1) renders to Y = 100.
  static final double _k = 100.0 /
      () {
        var s = 0.0;
        for (final v in _y) {
          s += v * _lambdaStep;
        }
        return s;
      }();

  static double _integrate(List<double> reflectance, List<double> cmf) {
    var s = 0.0;
    for (var i = 0; i < reflectance.length; i++) {
      s += reflectance[i] * cmf[i] * _lambdaStep;
    }
    return _k * s;
  }

  /// The illuminant-E white point XYZ (a perfect reflector).
  static final List<double> _white = () {
    final flat = List<double>.filled(bandCount, 1.0);
    return [_integrate(flat, _x), _integrate(flat, _y), _integrate(flat, _z)];
  }();

  /// The 3×3 matrix taking basis coefficients to rendered XYZ.
  static final List<List<double>> _basisToXyz = [
    [_integrate(_basisR, _x), _integrate(_basisG, _x), _integrate(_basisB, _x)],
    [_integrate(_basisR, _y), _integrate(_basisG, _y), _integrate(_basisB, _y)],
    [_integrate(_basisR, _z), _integrate(_basisG, _z), _integrate(_basisB, _z)],
  ];

  static double _f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16.0 / 116;

  static double _fInverse(double f) {
    final cubed = f * f * f;
    return cubed > 0.008856 ? cubed : (f - 16.0 / 116) / 7.787;
  }

  static List<double> _labToXyz(ColorCoordinates lab) {
    final fy = (lab.lightness + 16) / 116;
    final fx = fy + lab.a / 500;
    final fz = fy - lab.b / 200;
    return [
      _fInverse(fx) * _white[0],
      _fInverse(fy) * _white[1],
      _fInverse(fz) * _white[2],
    ];
  }

  /// CIELAB from a rendered reflectance spectrum, under the illuminant-E white
  /// point.
  static ColorCoordinates reflectanceToLab(List<double> reflectance) {
    final x = _integrate(reflectance, _x);
    final y = _integrate(reflectance, _y);
    final z = _integrate(reflectance, _z);
    final fx = _f(x / _white[0]);
    final fy = _f(y / _white[1]);
    final fz = _f(z / _white[2]);
    return ColorCoordinates(
      lightness: 116 * fy - 16,
      a: 500 * (fx - fy),
      b: 200 * (fy - fz),
    );
  }

  /// A smooth reflectance spectrum for [lab]: solve the three basis coefficients
  /// that render to [lab]'s XYZ, then clamp the curve into the physical range.
  static List<double> labToReflectance(ColorCoordinates lab) {
    final coeffs = _solve3(_basisToXyz, _labToXyz(lab));
    return [
      for (var i = 0; i < bandCount; i++)
        (coeffs[0] * _basisR[i] + coeffs[1] * _basisG[i] + coeffs[2] * _basisB[i])
            .clamp(minReflectance, 1.0),
    ];
  }

  /// Solves the 3×3 system m·x = v by Cramer's rule (m is well-conditioned by
  /// construction — three distinct, overlapping primaries).
  static List<double> _solve3(List<List<double>> m, List<double> v) {
    double det3(List<List<double>> a) =>
        a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) -
        a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0]) +
        a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]);

    final d = det3(m);
    List<List<double>> withColumn(int col) => [
          for (var r = 0; r < 3; r++)
            [for (var c = 0; c < 3; c++) c == col ? v[r] : m[r][c]],
        ];
    return [
      det3(withColumn(0)) / d,
      det3(withColumn(1)) / d,
      det3(withColumn(2)) / d,
    ];
  }
}
