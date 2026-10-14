import 'package:flutter/material.dart';

import '../a11y/cvd/cvd_profile.dart';
import '../onboarding/cvd_profile_read_endpoint.dart';
import '../store/cvd_profile_store.dart';
import 'display_controller.dart';
import 'display_scope.dart';

/// The open-display-settings entry (wireframe S1.R1, element E2 — bs-08
/// SETTINGS-1).
///
/// A single findable control the shared app chrome ([DisplayChrome]) surfaces on
/// every screen, so the display and simulation settings are reachable from
/// anywhere (AC-1). Tapping it runs [onPressed] — the chrome opens the
/// [DisplaySettingsScreen] panel over the current screen. A plain [IconButton]
/// so it needs only a [Material] ancestor (the chrome provides one); SETTINGS-2
/// grades the open-from-any-screen behaviour against this anchor.
class DisplaySettingsButton extends StatelessWidget {
  /// Creates the entry, invoking [onPressed] when the painter taps it.
  const DisplaySettingsButton({required this.onPressed, super.key});

  /// Stable anchor for E2 — open the display and simulation settings.
  static const Key openKey = ValueKey('display-e2-open-settings');

  /// Opens the settings panel (the chrome shows it over the current screen).
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // No tooltip: the chrome sits above the Navigator's Overlay, and a tooltip
    // requires an Overlay ancestor.
    return IconButton(
      key: openKey,
      onPressed: onPressed,
      icon: const Icon(Icons.contrast),
    );
  }
}

/// The app-wide chrome that surfaces the display-settings entry (E2) on every
/// screen and shows the [DisplaySettingsScreen] panel over the current one
/// (bs-08 SETTINGS-1).
///
/// Wired as the `MaterialApp.builder` in `buildApp`, so it wraps every route's
/// content: the entry ([DisplaySettingsButton]) sits in a corner above the
/// screen, and tapping it reveals the panel as a full-screen overlay that does
/// not replace the feature screen underneath (it closes back to it). Placed
/// below the `DisplayScope`/`AppScope` (which are above the `MaterialApp`), so
/// the panel reads the live [DisplayController] like any other surface.
class DisplayChrome extends StatefulWidget {
  /// Wraps [child] — the app's navigator — with the settings entry and panel.
  const DisplayChrome({required this.child, super.key});

  /// The app content the chrome overlays (the `MaterialApp`'s navigator).
  final Widget child;

  @override
  State<DisplayChrome> createState() => _DisplayChromeState();
}

class _DisplayChromeState extends State<DisplayChrome> {
  /// Whether the settings panel is shown over the current screen.
  bool _open = false;

  void _openSettings() => setState(() => _open = true);

  void _close() => setState(() => _open = false);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        // The E2 entry, present on every screen through this shared chrome.
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Material(
              type: MaterialType.transparency,
              child: DisplaySettingsButton(onPressed: _openSettings),
            ),
          ),
        ),
        // The panel is shown over (not instead of) the current screen. It is
        // hosted in its own Overlay so its Material controls (the slider, the
        // switch) have the Overlay ancestor they require — the chrome sits above
        // the app's Navigator, which would otherwise be the nearest one.
        if (_open)
          Positioned.fill(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => DisplaySettingsScreen(onClose: _close),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The display and simulation settings panel (wireframe S1.R1, elements E46–E48
/// plus a theme control — bs-08 SETTINGS-1).
///
/// Reads the app-wide [DisplayController] through [DisplayScope] and lays out
/// the three independent controls the painter sets (AC-1), each a findable,
/// keyed region bound to a controller setter:
///
///   * the CVD simulation selector (E47 — [simulationKey]): off plus one option
///     per [CvdType], driving [DisplayController.setSimulationType] (null ⇔ off);
///   * the value-only grayscale toggle (E46 — [grayscaleKey]), driving
///     [DisplayController.setGrayscale];
///   * the simulation-severity slider (E48 — [severityKey], 0..100), driving
///     [DisplayController.setSimulationSeverity] over 0..1 (D-6);
///   * a theme (light/dark) control (D-11 — [themeKey]) **shown** to satisfy
///     AC-1 but presentation only: its selection is local and drives no
///     behaviour this feature grades (theme is a spec boundary).
///
/// bs-10 adds, on their own axis (D-3/D-5):
///
///   * the daltonization on/off toggle ([daltonizationKey]), driving
///     [DisplayController.setDaltonization] — the remap itself lands in the
///     DALT behaviour phases;
///   * a no-saved-profile region ([noProfileRegionKey]) — prompts for a
///     self-assessment when no profile has been saved, so daltonization does
///     not silently remap against the const default (AC-10).
///
/// This is the SETTINGS-1 shell: the controls are wired to the setters, but the
/// *rendering* consequences (simulating swatches, greying the app) land in the
/// DISPLAY behaviour phases. The selector reads
/// [DisplayController.defaultSimulationType] to show the painter the type a
/// newly enabled simulation would default to (D-2).
class DisplaySettingsScreen extends StatelessWidget {
  /// Creates the panel, closing back to the current screen via [onClose].
  const DisplaySettingsScreen({required this.onClose, super.key});

  /// Stable anchor for the panel surface.
  static const Key panelKey = ValueKey('display-settings-panel');

  /// Stable anchor for the panel's close control.
  static const Key closeKey = ValueKey('display-settings-close');

  /// Stable anchor for E47 — the CVD simulation selector region.
  static const Key simulationKey = ValueKey('display-e47-simulation');

  /// Stable anchor for E46 — the value-only grayscale toggle.
  static const Key grayscaleKey = ValueKey('display-e46-grayscale');

  /// Stable anchor for E48 — the simulation-severity slider.
  static const Key severityKey = ValueKey('display-e48-severity');

  /// Stable anchor for the theme (light/dark) control (D-11, presentation).
  static const Key themeKey = ValueKey('display-theme');

  /// Stable anchor for the bs-10 daltonization on/off toggle, driving
  /// [DisplayController.setDaltonization]. Daltonization is beyond the drawn
  /// mock (scope §5.4), so it carries no wireframe element id.
  static const Key daltonizationKey = ValueKey('display-bs10-daltonization');

  /// Stable anchor for the bs-10 no-saved-profile region ([_NoSavedProfileRegion]).
  ///
  /// When [CvdProfileStore.hasSavedProfile] is false (nothing saved, or no store
  /// mounted) it prompts for a self-assessment before colours can be remapped;
  /// when a profile is saved it renders nothing and the remap applies (AC-10,
  /// CONTROL-2).
  static const Key noProfileRegionKey = ValueKey('display-bs10-no-profile');

  /// Stable per-option anchor under [simulationKey], one per selectable
  /// simulation ([type] null ⇔ the "off"/trichromat option).
  static Key simulationOptionKey(CvdType? type) =>
      ValueKey('display-e47-sim-${type?.name ?? 'off'}');

  /// The simulation options the E47 selector offers: off (trichromat) plus one
  /// per [CvdType].
  static const List<CvdType?> simulationOptions = [
    null,
    CvdType.protan,
    CvdType.deutan,
    CvdType.tritan,
  ];

  /// Closes the panel, returning to the screen underneath.
  final VoidCallback onClose;

  /// The painter-facing label for a simulation [type] (null ⇔ off).
  static String _simulationLabel(CvdType? type) =>
      type == null ? 'Off' : type.name;

  @override
  Widget build(BuildContext context) {
    final controller = DisplayScope.of(context);
    return Material(
      key: panelKey,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final settings = controller.settings;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Display and simulation settings'),
                    ),
                    IconButton(
                      key: closeKey,
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                // E47: the CVD simulation selector — off plus one per type.
                Column(
                  key: simulationKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CVD simulation'),
                    Text(
                      'Default for your vision: '
                      '${controller.defaultSimulationType.name}',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final type in simulationOptions)
                          TextButton(
                            key: simulationOptionKey(type),
                            onPressed: () => controller.setSimulationType(type),
                            child: Text(
                              settings.simulationType == type
                                  ? '✓ ${_simulationLabel(type)}'
                                  : _simulationLabel(type),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // E46: the value-only grayscale toggle.
                SwitchListTile(
                  key: grayscaleKey,
                  title: const Text('Value-only grayscale'),
                  value: settings.grayscale,
                  onChanged: controller.setGrayscale,
                ),
                // E48: the simulation-severity slider, 0..100 → 0..1 (D-6).
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Simulation severity'),
                      Slider(
                        key: severityKey,
                        min: 0,
                        max: 100,
                        value: (settings.simulationSeverity * 100)
                            .clamp(0.0, 100.0)
                            .toDouble(),
                        onChanged: (value) =>
                            controller.setSimulationSeverity(value / 100),
                      ),
                    ],
                  ),
                ),
                // bs-10: the daltonization on/off toggle, an independent axis
                // from simulation/grayscale (D-3/D-5), driving
                // DisplayController.setDaltonization. The rendering consequence
                // (remapping swatches) lands in the DALT behaviour phases.
                SwitchListTile(
                  key: daltonizationKey,
                  title: const Text('Daltonize colours'),
                  value: settings.daltonization,
                  onChanged: controller.setDaltonization,
                ),
                // bs-10 (AC-10): without a saved profile, prompt for a
                // self-assessment instead of remapping against the const
                // default; with one saved, show nothing (the remap applies).
                const _NoSavedProfileRegion(key: noProfileRegionKey),
                // The theme control — shown (AC-1) but presentation only (D-11).
                const _ThemeControl(key: themeKey),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The no-saved-profile affordance in the daltonization control (bs-10 AC-10).
///
/// Daltonization needs a known colour-vision type and severity to remap
/// against, so it is only meaningful once the painter has **saved** a profile
/// (a self-assessment, bs-07 PROFILE-2) — not while the pipeline is running on
/// the const default `loadCvdProfile` falls back to (D-4). This region consults
/// [CvdProfileStore.hasSavedProfile] (reached through the app-root
/// [CvdProfileReadEndpoint]) and, when nothing is saved, tells the painter a
/// self-assessment is needed; when a profile is saved — or no store is mounted
/// (a bare panel test) — it renders nothing, and the remap applies as usual.
///
/// The query is a one-shot [Future] resolved once per mount (re-run only if the
/// endpoint's store changes), so toggling other controls does not re-issue it.
class _NoSavedProfileRegion extends StatefulWidget {
  const _NoSavedProfileRegion({super.key});

  @override
  State<_NoSavedProfileRegion> createState() => _NoSavedProfileRegionState();
}

class _NoSavedProfileRegionState extends State<_NoSavedProfileRegion> {
  /// Whether the painter has saved a profile, or null while no store is mounted
  /// above this region (no prompt in that case).
  Future<bool>? _hasSavedProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read the store through the app-root endpoint; re-query only when it (and
    // so the store) actually changes — the InheritedWidget dependency rebuilds
    // this only on `updateShouldNotify`, not on the controller's own ticks.
    final store = CvdProfileReadEndpoint.maybeOf(context);
    _hasSavedProfile = store?.hasSavedProfile();
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedProfile = _hasSavedProfile;
    // No store mounted (a standalone panel test): no profile concept, no prompt.
    if (hasSavedProfile == null) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: hasSavedProfile,
      builder: (context, snapshot) {
        // Prompt only once we know nothing is saved; while loading (null) or
        // when a profile is saved (true), show nothing so the remap applies.
        if (snapshot.data == false) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No colour-vision profile saved yet — take a self-assessment '
              'before colours can be remapped for your vision.',
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// The theme (light/dark) control shown in the settings panel (D-11).
///
/// Present to satisfy AC-1's "the theme controls are shown", but presentation
/// only: theme is outside this feature's boundary, so the selection is kept in
/// local state and drives no app-wide behaviour. A later feature may wire it.
class _ThemeControl extends StatefulWidget {
  const _ThemeControl({super.key});

  @override
  State<_ThemeControl> createState() => _ThemeControlState();
}

class _ThemeControlState extends State<_ThemeControl> {
  /// The locally selected theme brightness (presentation only).
  bool _dark = false;

  /// Stable per-option anchor for the [dark] / light choice.
  static Key optionKey({required bool dark}) =>
      ValueKey('display-theme-${dark ? 'dark' : 'light'}');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme'),
        Wrap(
          spacing: 8,
          children: [
            for (final dark in const [false, true])
              TextButton(
                key: optionKey(dark: dark),
                onPressed: () => setState(() => _dark = dark),
                child: Text(
                  _dark == dark
                      ? '✓ ${dark ? 'Dark' : 'Light'}'
                      : (dark ? 'Dark' : 'Light'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
