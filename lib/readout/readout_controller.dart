import 'package:flutter/foundation.dart';

import '../a11y/haptics.dart';
import '../a11y/speech.dart';
import '../app/router.dart';
import '../color_science/color_science.dart';
import '../domain/sample.dart';

/// The colour spaces the readout can show, one at a time (AC-5).
///
/// The shell renders the selector over these four options; the exclusive
/// show-one-hide-the-rest behaviour and each space's real values land in
/// READOUT-4.
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
/// the current sample, the injected services the behaviour phases derive through
/// ([ColorScience] → READOUT-2/4, [Speech] → A11Y-2, [AppRouter] → READOUT-6),
/// the selected colour space (→ READOUT-4) and the just-captured state (→
/// A11Y-2). This shell phase wires the seam and holds the state; **no colour is
/// derived here** — the [ColorScience] stub throws until COLOR-2/3, so the shell
/// reads only the sample's own fields and shows placeholders for the rest.
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
        _selectedSpace = ReadoutSpace.cielch;

  Sample _sample;

  /// Derives every presentable form of the sample's colour (used by the
  /// behaviour phases; the shell does not call it — the stub throws).
  final ColorScience colorScience;

  /// Spoken-output sink the speak action drives (wired in A11Y-2).
  final Speech speech;

  /// Haptic sink the just-captured confirmation drives (wired in A11Y-2).
  final Haptics haptics;

  /// Typed navigation into comparison / recipes (wired in READOUT-6).
  final AppRouter router;

  ReadoutSpace _selectedSpace;

  /// The sample currently being read.
  Sample get sample => _sample;

  /// The colour space the selector is currently showing.
  ReadoutSpace get selectedSpace => _selectedSpace;

  /// Whether this reading was just captured and not yet acknowledged (AC-12).
  bool get justCaptured => _sample.justCaptured;

  /// The sample's plain-language name, or a placeholder until it is named.
  ///
  /// The nearest-name derivation (AC-3) lands in COLOR-3 / READOUT-3; the shell
  /// shows the sample's own [Sample.name] when present.
  String get nameText => _sample.name ?? 'Unnamed sample';

  /// Shows [space] in the selector, hiding the others.
  ///
  /// The shell tracks the selection and notifies; the exclusive rendering of
  /// each space's values (AC-5) lands in READOUT-4.
  void selectSpace(ReadoutSpace space) {
    if (space == _selectedSpace) return;
    _selectedSpace = space;
    notifyListeners();
  }

  /// Acknowledges a just-captured reading, clearing its [justCaptured] marker.
  ///
  /// The haptic confirmation fired on first render (AC-12) is wired in A11Y-2;
  /// the shell only clears the marker so the acknowledge control has a seam.
  void acknowledge() {
    if (!_sample.justCaptured) return;
    _sample = _sample.copyWith(justCaptured: false);
    notifyListeners();
  }
}
