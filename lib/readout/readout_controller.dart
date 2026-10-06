import 'package:flutter/widgets.dart';

import '../a11y/haptics.dart';
import '../a11y/speech.dart';
import '../app/router.dart';
import '../color_science/color_science.dart';
import '../domain/sample.dart';

/// The colour spaces the readout can show, one at a time (AC-5).
///
/// The selector renders over these four options; selecting one shows that
/// space's values (see [ReadoutController.readoutForSpace]) and hides the rest.
enum ReadoutSpace {
  /// Cylindrical CIELCh (L\*, C\*, h).
  cielch,

  /// Munsell notation (e.g. `10R 5.5/6`).
  munsell,

  /// sRGB triplet + hex.
  srgb,

  /// Canonical CIELAB (L\*, a\*, b\*).
  cielab,
}

/// Holds the [Sample] the Readout screen presents and the view state over it.
///
/// A thin seam the screen is a view over (READOUT module interface): it carries
/// the current sample, the injected services it derives and drives through
/// ([ColorScience] for every reading, [Speech] for [speak], [Haptics] for the
/// just-captured confirmation, [AppRouter] for the navigation handoffs), the
/// selected colour space and the just-captured state. The screen is a pure view
/// over this controller; all derivation and the spoken/haptic actions live here.
class ReadoutController extends ChangeNotifier {
  /// Creates a controller over [sample] with the app-injected services.
  ReadoutController({
    required Sample sample,
    required this.colorScience,
    required this.speech,
    required this.haptics,
    required this.router,
  })  : // The field is private (_sample); the public named parameter is `sample`.
        _sample = sample, // ignore: prefer_initializing_formals
        _selectedSpace = ReadoutSpace.cielch {
    // A reading that arrives already just-captured confirms with a haptic as the
    // readout first lands (AC-12), exactly as [load] does for a later capture.
    _confirmIfJustCaptured();
  }

  Sample _sample;

  /// Derives every presentable form of the sample's colour (used by the
  /// behaviour phases; the shell does not call it — the stub throws).
  final ColorScience colorScience;

  /// Spoken-output sink the [speak] action drives (AC-8).
  final Speech speech;

  /// Haptic sink the just-captured confirmation drives (AC-12).
  final Haptics haptics;

  /// Typed navigation into comparison / recipes (the actions bar pushes the
  /// routes [comparisonRoute] / [recipesRoute] build).
  final AppRouter router;

  ReadoutSpace _selectedSpace;

  /// The sample currently being read.
  Sample get sample => _sample;

  /// The colour space the selector is currently showing.
  ReadoutSpace get selectedSpace => _selectedSpace;

  /// Whether this reading was just captured and not yet acknowledged (AC-12).
  bool get justCaptured => _sample.justCaptured;

  /// The sample's plain-language name shown large at the top (AC-3).
  ///
  /// The sample's own [Sample.name] when it carries one; otherwise the nearest
  /// ISCC-NBS colour name derived from its coordinates, so an un-named sample
  /// still reads as a real colour name rather than a placeholder.
  String get nameText =>
      _sample.name ?? colorScience.nearestName(_sample.coordinates);

  /// The sample's temperature stated as a plain-language word — "warm", "cool"
  /// or "neutral" (AC-4).
  ///
  /// Derived from the sample's hue angle (its CIELCh hue) relative to the
  /// neutral axis, so the temperature reads as a word that tracks the colour and
  /// is never the raw hue angle.
  String get temperatureWord => colorScience
      .temperatureWord(colorScience.toCIELCh(_sample.coordinates).hue);

  /// The sample's perceptual lightness (CIELAB L\*) — the prominent reading the
  /// value region shows largest (AC-1).
  double get lightness => colorScience.lightness(_sample.coordinates);

  /// The plain-language value word paired with [lightness] (e.g. "middle
  /// value"), derived from the lightness so it tracks the number (AC-2).
  String get valueWord => colorScience.valueWord(lightness);

  /// The sample in Munsell notation; the value region shows its Munsell
  /// [MunsellColor.value] beside the lightness (AC-1).
  MunsellColor get munsell => colorScience.toMunsell(_sample.coordinates);

  /// The sample's lightness shown as a neutral — the grayscale preview that
  /// accompanies the value reading (AC-1).
  SRGBColor get grayscale => colorScience.grayscaleOf(_sample.coordinates);

  /// The selected colour space's values, formatted for display (AC-5).
  ///
  /// The selector shows only this space's reading; selecting another space
  /// replaces it, so the other spaces are no longer shown (the one-at-a-time
  /// rule). Derived live, so it tracks [selectedSpace] and [load].
  String get spaceReadout => readoutForSpace(_selectedSpace);

  /// Formats [space]'s values from the current sample (AC-5).
  ///
  /// Exposed so each space's formatting is unit-testable independently of the
  /// selection state. Each space reads through [ColorScience]:
  ///
  /// * CIELCh — `L <l>, C <c>, h <h>°` (the cylindrical readout, rounded);
  /// * Munsell — the familiar `<hue> <value>/<chroma>` notation (e.g. `10R 5.5/6`);
  /// * sRGB — the 8-bit `r, g, b` triplet and the `#rrggbb` hex value;
  /// * CIELAB — `L <l>, a <a>, b <b>` (the canonical coordinates).
  String readoutForSpace(ReadoutSpace space) {
    switch (space) {
      case ReadoutSpace.cielch:
        final lch = colorScience.toCIELCh(_sample.coordinates);
        return 'L ${lch.lightness.round()}, C ${lch.chroma.round()}, '
            'h ${lch.hue.round()}°';
      case ReadoutSpace.munsell:
        final m = colorScience.toMunsell(_sample.coordinates);
        return '${m.hue} ${_trimZero(m.value)}/${_trimZero(m.chroma)}';
      case ReadoutSpace.srgb:
        final rgb = colorScience.toSRGB(_sample.coordinates);
        final hex = colorScience.toHex(_sample.coordinates);
        return '${rgb.red}, ${rgb.green}, ${rgb.blue}  $hex';
      case ReadoutSpace.cielab:
        final lab = colorScience.toCIELAB(_sample.coordinates);
        return 'L ${lab.lightness.round()}, a ${lab.a.toStringAsFixed(2)}, '
            'b ${lab.b.toStringAsFixed(2)}';
    }
  }

  /// Renders [v] without a redundant trailing `.0` (e.g. `6.0` → `6`, `5.5`
  /// stays `5.5`), so the Munsell notation reads as the familiar `10R 5.5/6`.
  static String _trimZero(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  /// Speaks the whole readout as a single utterance (AC-8).
  ///
  /// Builds the spoken decomposition of the current sample — its name, value,
  /// temperature word, hue in words, chroma and hue angle — via
  /// [ColorScience.decompose] and sends it to [Speech.speak] exactly once, so the
  /// painter hears the entire reading as one utterance rather than a stream of
  /// fragments. The action does not change the reading, so it does not notify.
  Future<void> speak() => speech.speak(colorScience.decompose(_sample));

  /// A route that carries this reading into comparison [slot] (AC-9, AC-10).
  ///
  /// The actions bar pushes it when the painter chooses "compare as A"/"B"; the
  /// current [sample] is placed into the chosen slot, so the Comparison screen
  /// opens with this reading there (and the other slot empty).
  Route<void> comparisonRoute(ComparisonSlot slot) =>
      router.toComparison(_sample, slot);

  /// A route to a recipe search with this reading as the mixing target (AC-11).
  ///
  /// The actions bar pushes it when the painter asks to find mixing recipes; the
  /// current [sample] becomes the Recipes screen's target.
  Route<void> recipesRoute() => router.toRecipes(_sample);

  /// Shows [space] in the selector, hiding the others.
  ///
  /// Tracks the selection and notifies; [spaceReadout] then renders only the
  /// newly selected space, so the others are no longer shown (AC-5).
  void selectSpace(ReadoutSpace space) {
    if (space == _selectedSpace) return;
    _selectedSpace = space;
    notifyListeners();
  }

  /// Replaces the sample being read, notifying listeners.
  ///
  /// The screen calls this when a different sample is injected into the same
  /// Readout (e.g. a new capture replacing the app's initial sample on the
  /// running app — bs-02, D-1); the selected colour space is kept. A re-load of
  /// the same sample instance is a no-op. A just-captured sample confirms with a
  /// haptic as the new reading lands (AC-12).
  void load(Sample sample) {
    if (identical(sample, _sample)) return;
    _sample = sample;
    _confirmIfJustCaptured();
    notifyListeners();
  }

  /// Acknowledges a just-captured reading, clearing its [justCaptured] marker.
  ///
  /// The marker is shown until the painter acknowledges the fresh capture, when
  /// it clears (AC-12); acknowledging a reading that is not just-captured is a
  /// no-op. No further haptic fires — [_confirmIfJustCaptured] pulses only when a
  /// fresh reading first lands, never on acknowledge or a plain rebuild.
  void acknowledge() {
    if (!_sample.justCaptured) return;
    _sample = _sample.copyWith(justCaptured: false);
    notifyListeners();
  }

  /// Fires one haptic confirmation when the current reading is just-captured.
  ///
  /// Called as a reading first becomes current — on construction and on [load] —
  /// so a freshly captured reading pulses [Haptics.confirm] exactly once as it
  /// lands (AC-12); a non-fresh reading fires nothing. Rebuilds don't call this,
  /// so the pulse is tied to the capture, not repeated on every render.
  void _confirmIfJustCaptured() {
    if (_sample.justCaptured) {
      haptics.confirm();
    }
  }
}
