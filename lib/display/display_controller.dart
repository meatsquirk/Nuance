import 'package:flutter/foundation.dart';

import '../a11y/cvd/cvd_profile.dart';
import 'display_settings.dart';

/// The single owner of the app-wide [DisplaySettings] (bs-08 DISPLAY-2).
///
/// A [ChangeNotifier] holding one [DisplaySettings], exposed down the tree by
/// `DisplayScope` so every colour-rendering surface reads one source of truth.
/// The three setters change exactly their field and notify; they drive no
/// rendering yet (the shell wires the seams inert), and the behaviour phases
/// make the renders consume the state:
///
/// * DISPLAY-3/4 project swatches through `color_simulation.dart` when
///   [DisplaySettings.simulationType] is set (AC-2/AC-3);
/// * DISPLAY-5 feeds [DisplaySettings.simulationSeverity] into the projection
///   (AC-4);
/// * DISPLAY-6 makes [setGrayscale] clear an active simulation (AC-5, D-3);
/// * DISPLAY-7 makes the root grayscale filter active (AC-6).
///
/// [defaultSimulationType] is the type the settings panel pre-selects when the
/// painter first turns simulation on (D-2) — seeded from `AppDependencies`'
/// `CvdProfile` by `buildApp` — so the default matches the painter's own vision.
class DisplayController extends ChangeNotifier {
  /// Creates the controller over an [initialSettings] value (the shipped view by
  /// default) and the [defaultSimulationType] the settings panel pre-selects.
  DisplayController({
    this.defaultSimulationType = CvdType.deutan,
    DisplaySettings initialSettings = const DisplaySettings(),
  }) : _settings = initialSettings;

  /// The CVD class a newly enabled simulation defaults to (D-2); the painter may
  /// still pick another through [setSimulationType]. Read by the settings panel
  /// (SETTINGS-1); it does not change the current view on its own.
  final CvdType defaultSimulationType;

  DisplaySettings _settings;

  /// The live display settings every rendering surface reads.
  DisplaySettings get settings => _settings;

  /// Sets the simulated CVD [type] (null turns simulation off — the trichromat
  /// view, AC-2) and notifies listeners. A no-op when unchanged.
  void setSimulationType(CvdType? type) {
    if (type == _settings.simulationType) return;
    _settings = DisplaySettings(
      simulationType: type,
      simulationSeverity: _settings.simulationSeverity,
      grayscale: _settings.grayscale,
      daltonization: _settings.daltonization,
    );
    notifyListeners();
  }

  /// Sets the simulation [severity] (0..1 — AC-4) and notifies listeners. A
  /// no-op when unchanged.
  void setSimulationSeverity(double severity) {
    if (severity == _settings.simulationSeverity) return;
    _settings = DisplaySettings(
      simulationType: _settings.simulationType,
      simulationSeverity: severity,
      grayscale: _settings.grayscale,
      daltonization: _settings.daltonization,
    );
    notifyListeners();
  }

  /// Turns the value-only grayscale view on or off (AC-6) and notifies
  /// listeners. A no-op when unchanged.
  ///
  /// Grayscale and simulation are mutually exclusive views (D-3, AC-5):
  /// turning grayscale **on** clears any active simulation ([simulationType]
  /// becomes null). Turning grayscale **off** leaves the simulation off — it is
  /// never re-enabled; the painter must re-select a type to simulate again.
  void setGrayscale(bool grayscale) {
    if (grayscale == _settings.grayscale) return;
    _settings = DisplaySettings(
      simulationType: grayscale ? null : _settings.simulationType,
      simulationSeverity: _settings.simulationSeverity,
      grayscale: grayscale,
      daltonization: _settings.daltonization,
    );
    notifyListeners();
  }

  /// Turns the display-only daltonization remap on or off (bs-10) and notifies
  /// listeners. A no-op when unchanged.
  ///
  /// An independent control: unlike grayscale and simulation (mutually
  /// exclusive, D-3), daltonization stands on its own axis — it remaps every
  /// swatch at the one display chokepoint to aid distinction, reading the
  /// painter's stored profile (bs-10 D-3), and leaves the other display fields
  /// untouched. Inert in this shell (the remap is identity until DALT-3).
  void setDaltonization(bool daltonization) {
    if (daltonization == _settings.daltonization) return;
    _settings = DisplaySettings(
      simulationType: _settings.simulationType,
      simulationSeverity: _settings.simulationSeverity,
      grayscale: _settings.grayscale,
      daltonization: daltonization,
    );
    notifyListeners();
  }
}
