import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The value region: the prominent lightness reading, its grayscale preview and
/// the Munsell value beside it (AC-1, AC-2).
///
/// Shell placeholder: the region and its three anchors (value, grayscale slot,
/// Munsell value) are laid out so finders and later phases have stable targets,
/// but no value is derived yet — the prominence sizing, the real lightness /
/// Munsell numbers (COLOR-2, READOUT-2) and the value word (COLOR-3) land later.
class ValueRegion extends StatelessWidget {
  const ValueRegion({required this.controller, super.key});

  /// Stable anchor for the region.
  static const Key regionKey = ValueKey('readout-value-region');

  /// Stable anchor for the grayscale preview slot.
  static const Key grayscaleKey = ValueKey('readout-grayscale-preview');

  /// The controller the region reads from (unused placeholder fields in the
  /// shell; READOUT-2 derives the value readings through it).
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: regionKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            key: grayscaleKey,
            width: 48,
            height: 48,
            color: const Color(0xFFBDBDBD),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Lightness — · Munsell value —'),
          ),
        ],
      ),
    );
  }
}
