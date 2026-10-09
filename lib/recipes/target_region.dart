import 'package:flutter/material.dart';

import '../domain/color_coordinates.dart';
import '../domain/sample.dart';
import 'recipe_controller.dart';

/// The target region of the Recipes screen (wireframe S1.R1 — the mixing target,
/// E22 Target selector, E23 Speak target).
///
/// Shows the current mixing target's name on a `Recipe target: <name>` line —
/// the same render the Readout → recipes handoff (bs-01 AC-11) relies on — read
/// from [RecipeController.state]. Below it sit the target controls: the target
/// selector (E22), wired by RECIPE-3 to choose a saved sample or enter a colour
/// by hand (AC-1, AC-2), and the speak-target control (E23), wired by RECIPE-4
/// to speak the target's name and its L, C and hue (AC-11). Any
/// manual-entry error is surfaced under the selector. The region keeps its
/// [regionKey] so the acceptance finders and the behaviour phases have a stable
/// anchor.
class TargetRegion extends StatelessWidget {
  const TargetRegion({required this.controller, super.key});

  /// Stable anchor for the target region.
  static const Key regionKey = ValueKey('recipes-target-region');

  /// Stable anchor for the manual-entry error line (AC-2).
  static const Key manualErrorKey = ValueKey('recipes-target-manual-error');

  /// The controller supplying the current target and the selection actions.
  final RecipeController controller;

  /// Opens the target selector (E22): a saved-sample picker plus a by-hand
  /// CIELAB entry form. Choosing or entering a target drives [controller] and
  /// dismisses the sheet.
  Future<void> _openSelector(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TargetSelectorSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final target = state.target;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recipe target: ${target.name ?? '(unnamed)'}'),
        // E22 Target selector — wired by RECIPE-3 (AC-1, AC-2).
        TextButton(
          onPressed: () => _openSelector(context),
          child: const Text('Choose target'),
        ),
        if (state.manualError != null)
          Text(
            state.manualError!,
            key: manualErrorKey,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        // E23 Speak target — wired by RECIPE-4 (AC-11): speaks the target's
        // name and its L, C and hue through the controller's speech seam.
        TextButton(
          onPressed: () => controller.speakTarget(),
          child: const Text('Speak target'),
        ),
      ],
    );
  }
}

/// The target selector sheet (E22): pick a saved sample, or enter a CIELAB
/// colour by hand.
///
/// Stateful so the three manual-entry fields keep their own controllers. Tapping
/// a saved sample calls [RecipeController.selectTarget]; submitting the manual
/// form calls [RecipeController.enterManualTarget] with the parsed coordinates
/// (an unparseable field becomes `NaN`, which the controller refuses as out of
/// range). Either action pops the sheet.
class _TargetSelectorSheet extends StatefulWidget {
  const _TargetSelectorSheet({required this.controller});

  final RecipeController controller;

  @override
  State<_TargetSelectorSheet> createState() => _TargetSelectorSheetState();
}

class _TargetSelectorSheetState extends State<_TargetSelectorSheet> {
  final TextEditingController _lightness = TextEditingController();
  final TextEditingController _a = TextEditingController();
  final TextEditingController _b = TextEditingController();

  @override
  void dispose() {
    _lightness.dispose();
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _choose(Sample sample) {
    widget.controller.selectTarget(sample);
    Navigator.of(context).pop();
  }

  void _submitManual() {
    widget.controller.enterManualTarget(ColorCoordinates(
      lightness: double.tryParse(_lightness.text) ?? double.nan,
      a: double.tryParse(_a.text) ?? double.nan,
      b: double.tryParse(_b.text) ?? double.nan,
    ));
    Navigator.of(context).pop();
  }

  void _onFieldSubmitted(String _) => _submitManual();

  @override
  Widget build(BuildContext context) {
    final samples = widget.controller.savedSamples;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a saved sample'),
            for (final sample in samples)
              ListTile(
                dense: true,
                title: Text(sample.name ?? '(unnamed)'),
                onTap: () => _choose(sample),
              ),
            const Divider(),
            const Text('Or enter a colour by hand (CIELAB)'),
            TextField(
              controller: _lightness,
              decoration: const InputDecoration(labelText: 'L*'),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              onSubmitted: _onFieldSubmitted,
            ),
            TextField(
              controller: _a,
              decoration: const InputDecoration(labelText: 'a*'),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              onSubmitted: _onFieldSubmitted,
            ),
            TextField(
              controller: _b,
              decoration: const InputDecoration(labelText: 'b*'),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              onSubmitted: _onFieldSubmitted,
            ),
          ],
        ),
      ),
    );
  }
}
