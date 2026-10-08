import '../../domain/color_coordinates.dart';
import '../../domain/paint.dart';
import '../../domain/sample.dart';
import '../palette.dart';
import 'mixing_engine.dart';

/// The v1 [MixingEngine]: a subtractive (Kubelka–Munk class) model (bs-04 D-2,
/// SI D3 — Spectral.js basis).
///
/// A `const` engine wired in as the default [AppDependencies.mixingEngine]. This
/// shell declares it and its shape; **no mixing behaviour is implemented yet** —
/// both methods are stubs behind [_stub]. The behaviour arrives in the ENGINE
/// behaviour phases: [forward] (ENGINE-2; the dry transform ENGINE-6), [inverse]
/// (the solver ENGINE-2, then verdict/ordering/trace/muddying/gamut in
/// ENGINE-3..6). The measured-pigment engine is the deferred swap-in behind the
/// same interface.
class SubtractiveMixingEngine implements MixingEngine {
  /// Creates the (stateless, `const`) v1 engine.
  const SubtractiveMixingEngine();

  /// Marker on every stubbed path: this shell wires the engine in without any
  /// mixing math, so its behaviour can be built and gated one AC at a time.
  static const String _stub =
      'SubtractiveMixingEngine is a shell (ENGINE-1); behaviour lands in '
      'ENGINE-2..6.';

  @override
  ColorCoordinates forward(Map<Paint, double> partsByVolume, {bool dry = false}) {
    // STUB (ENGINE-1): the forward subtractive model lands in ENGINE-2 (wet) and
    // ENGINE-6 (the per-medium dry transform). No prediction yet.
    throw UnimplementedError(_stub);
  }

  @override
  List<Recipe> inverse(Sample target, PaintPalette palette, MixOptions opts) {
    // STUB (ENGINE-1): the palette-constrained subset search lands in ENGINE-2.
    // Returns no recipes so the wired-but-inert screen renders an empty list.
    return const [];
  }
}
