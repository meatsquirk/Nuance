import '../../domain/color_coordinates.dart';
import 'cvd_profile.dart';

/// Decides whether two colours are **confusable** for a given colour-vision
/// profile — the seam behind the comparison's confusion warning (AC-7, AC-8).
///
/// One [ConfusionCheck] is injected app-wide (registered in `buildApp`) so the
/// detector's model lives behind this interface rather than in the comparison
/// screen — the same architectural seam bs-01 uses for `Speech`/`Haptics`. A
/// pair is confusable when it looks **identical to the painter** yet is
/// **clearly different to normal vision**: formally (D-5) the ΔE00 between the
/// two colours *after* the profile's dichromat projection falls below a small
/// threshold while their normal ΔE00 is clearly-different.
///
/// The shipped detector is a documented dichromat projection (Viénot 1999 /
/// Brettel–Viénot–Mollon LMS, D-4). **bs-08/bs-10** (display simulation,
/// daltonization) reuse that projection behind this same interface. The real
/// math arrives in CVD-2; today only the inert [NoopConfusionCheck] exists.
abstract interface class ConfusionCheck {
  /// Whether colours [a] and [b] are confusable for profile [profile] (D-5).
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile);
}

/// The default [ConfusionCheck]: never flags a pair.
///
/// Wires confusion detection into the assembled app (`AppDependencies`) while
/// the real projection is still unbuilt, so the comparison runs end to end with
/// the detector present but inert. CVD-2 replaces this with the dichromat
/// projection; until then no pair is ever flagged confusable.
class NoopConfusionCheck implements ConfusionCheck {
  const NoopConfusionCheck();

  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile) {
    // Intentionally inert: no projection yet (filled in CVD-2).
    return false;
  }
}
