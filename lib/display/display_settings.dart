import '../a11y/cvd/cvd_profile.dart';

/// The cross-cutting display state the painter sets once and the whole app reads
/// (bs-08 DISPLAY-2).
///
/// A plain, immutable value type carrying the three independent display
/// controls the settings panel exposes (AC-1): a CVD-[simulationType] to view
/// the world through (null ⇔ simulation off — the trichromat/identity view,
/// AC-2), the [simulationSeverity] that scales how strongly it is applied
/// (AC-4), and a value-only [grayscale] flag that greys the whole app (AC-6).
///
/// It holds state, not behaviour: the dichromat projection ([projectDichromat],
/// reused unchanged — D-1) lives behind `color_simulation.dart`, and the two
/// views' mutual exclusion (D-3) lives in [DisplayController]. Value equality so
/// two settings compare by content, mirroring [CvdProfile] / `ColorCoordinates`.
class DisplaySettings {
  /// Creates a settings value; the default is the shipped view — no simulation
  /// ([simulationType] null), full [simulationSeverity] (the strength a newly
  /// enabled simulation applies, matching [CvdProfile]'s default), no grayscale.
  const DisplaySettings({
    this.simulationType,
    this.simulationSeverity = 1.0,
    this.grayscale = false,
  });

  /// The CVD class the painter is viewing the app through, or null when
  /// simulation is off (the trichromat identity view — AC-2). D-2: the setting
  /// carries its own type (defaulting from the painter's `CvdProfile`), because
  /// the painter may *choose* which type to simulate.
  final CvdType? simulationType;

  /// How strongly the simulation is applied, 0 (none, the original colour) to 1
  /// (full dichromat) — the 0..100 severity slider mapped to 0..1 (AC-4, D-6).
  /// Ignored while simulation is off.
  final double simulationSeverity;

  /// Whether the value-only grayscale view is on, greying the whole app — camera
  /// feed, swatches and readings alike (AC-6). Mutually exclusive with an active
  /// simulation (D-3), a rule [DisplayController] enforces.
  final bool grayscale;

  /// Whether a CVD simulation is active (⇔ [simulationType] is non-null).
  bool get simulationOn => simulationType != null;

  @override
  bool operator ==(Object other) =>
      other is DisplaySettings &&
      other.simulationType == simulationType &&
      other.simulationSeverity == simulationSeverity &&
      other.grayscale == grayscale;

  @override
  int get hashCode =>
      Object.hash(simulationType, simulationSeverity, grayscale);

  @override
  String toString() =>
      'DisplaySettings(simulationType: $simulationType, '
      'simulationSeverity: $simulationSeverity, grayscale: $grayscale)';
}
