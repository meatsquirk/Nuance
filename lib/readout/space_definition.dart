import 'package:flutter/material.dart';

import 'space_selector.dart' show SpaceSelector;
import 'readout_controller.dart';

/// A single colour space's name, openable to reveal a fuller plain-language
/// definition and an example (AC-5).
///
/// The space's *values* are always shown by [AllSpacesRegion]; this widget adds
/// the educational layer on top: the space's name is a tappable control
/// ([nameKey]) and opening it reveals a fuller plain-language definition with an
/// example ([definitionKey]), tapping again hides it. The definition text is
/// presentation-level help copy (D-4) — not new colour science — authored from
/// the spec's B2 draft; the owner may edit [definitionFor].
///
/// READOUT-6 — renders the real tappable name and the revealed definition. (The
/// READOUT-2 shell rendered only an empty [nameKey] placeholder.)
class SpaceDefinition extends StatefulWidget {
  const SpaceDefinition({required this.space, super.key});

  /// Stable anchor for [space]'s tappable name.
  static Key nameKey(ReadoutSpace space) =>
      ValueKey('readout-space-name-${space.name}');

  /// Stable anchor for [space]'s revealed definition (+ example), shown once the
  /// name is opened (READOUT-6).
  static Key definitionKey(ReadoutSpace space) =>
      ValueKey('readout-space-definition-${space.name}');

  /// The colour space this definition is for.
  final ReadoutSpace space;

  /// The fuller plain-language definition of [space], with an example (AC-5).
  ///
  /// Presentation-level help copy (D-4), authored from the spec's B2 draft; the
  /// owner may edit it. Each definition names an everyday example ("e.g. …") so
  /// a painter unfamiliar with the space learns what it means.
  static String definitionFor(ReadoutSpace space) {
    switch (space) {
      case ReadoutSpace.cielch:
        return 'A perceptual space that describes a color by its lightness, '
            'its chroma (how vivid it is) and its hue angle — close to how the '
            'eye judges color. E.g. a bright red and a muted red share a hue '
            'but differ in chroma.';
      case ReadoutSpace.munsell:
        return 'An artist’s notation that names a color by Hue, Value '
            '(lightness from 0 to 10) and Chroma (strength). For example, '
            '10R 5/6 is a medium-light, moderately strong red.';
      case ReadoutSpace.srgb:
        return 'The red, green and blue a screen mixes to display the color, '
            'each from 0 to 255 and often written as a hex code. E.g. #C65D3B '
            'is a warm terracotta.';
      case ReadoutSpace.cielab:
        return 'A device-independent space that places a color by its '
            'lightness and two axes: a* from green to red and b* from blue to '
            'yellow. For instance, a positive a* and b* fall in the warm '
            'orange-red region.';
    }
  }

  @override
  State<SpaceDefinition> createState() => _SpaceDefinitionState();
}

class _SpaceDefinitionState extends State<SpaceDefinition> {
  /// Whether the fuller definition is revealed (the name has been opened).
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = SpaceSelector.labelFor(widget.space);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The tappable space name (AC-5): opening it reveals the definition,
        // tapping again hides it. The label text lives inside [nameKey] so the
        // acceptance test finds the name as an openable label.
        InkWell(
          key: SpaceDefinition.nameKey(widget.space),
          onTap: _toggle,
          // bs-20 READOUT-9 (restores bs-11 AC-4): reserve a ≥48dp tap target so
          // this tappable space name clears the 48dp floor the accessibility
          // sweep enforces — the bare `labelLarge` + 18px-icon row fell below it.
          // The row stays left-aligned and vertically centred, so AC-5's
          // tap-to-reveal and the all-spaces layout are unchanged.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(width: 4),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  semanticLabel:
                      _open ? 'Hide $label definition' : 'Show $label definition',
                ),
              ],
            ),
          ),
        ),
        // The revealed definition + example (AC-5): present only while open, so
        // it is hidden until the name is tapped.
        if (_open)
          Padding(
            key: SpaceDefinition.definitionKey(widget.space),
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              SpaceDefinition.definitionFor(widget.space),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
