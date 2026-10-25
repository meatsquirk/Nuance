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
    this.daltonization = false,
    this.accessibilityFeatures = false,
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

  /// Whether the display-only daltonization remap is on — the bs-10 view that
  /// pushes confusable colours apart so the painter can tell them apart,
  /// applied to every swatch at the one display chokepoint (bs-10 D-1).
  ///
  /// Distinct from [simulationType] (how the painter *sees* a colour, bs-08):
  /// daltonization *remaps* the colour to aid distinction, reading the painter's
  /// stored profile (bs-10 D-3). Off by default — the shipped view is untouched.
  final bool daltonization;

  /// Whether the painter has opted into the accessibility-features set (bs-20).
  ///
  /// An independent axis (like [daltonization]): it gates presentation of
  /// accessibility affordances the readout reveals only on request — the Speak
  /// control (bs-20 AC-7/AC-8). Off by default so the shipped readout stays
  /// uncluttered; turning it on changes no colour rendering. Inert in this
  /// shell — the consequence (showing Speak) lands in the READOUT behaviour
  /// phases.
  final bool accessibilityFeatures;

  /// Whether a CVD simulation is active (⇔ [simulationType] is non-null).
  bool get simulationOn => simulationType != null;

  @override
  bool operator ==(Object other) =>
      other is DisplaySettings &&
      other.simulationType == simulationType &&
      other.simulationSeverity == simulationSeverity &&
      other.grayscale == grayscale &&
      other.daltonization == daltonization &&
      other.accessibilityFeatures == accessibilityFeatures;

  @override
  int get hashCode => Object.hash(simulationType, simulationSeverity, grayscale,
      daltonization, accessibilityFeatures);

  @override
  String toString() =>
      'DisplaySettings(simulationType: $simulationType, '
      'simulationSeverity: $simulationSeverity, grayscale: $grayscale, '
      'daltonization: $daltonization, '
      'accessibilityFeatures: $accessibilityFeatures)';
}
