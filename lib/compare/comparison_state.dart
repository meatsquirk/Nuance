import '../domain/sample.dart';
import 'difference.dart';

/// The observable state of the comparison: the two chosen slots and the
/// relational reading derived from them.
///
/// A plain immutable snapshot held by the [ComparisonController] and surfaced to
/// the Comparison screen and the acceptance read endpoint. [slotA] / [slotB]
/// carry the chosen samples (null until chosen); [comparison] is the DIFF
/// reading of the pair and [confusable] the CVD flag — both derived by the
/// controller and **null / false unless both slots are set** (which drives the
/// AC-12 "choose a second sample" invite: no second sample ⇒ no statement).
///
/// COMPARE-2 fixes this shape; the behaviour phases move the slots (selection
/// COMPARE-3, swap COMPARE-5) and fill the real [comparison] math (ΔE00 + the
/// decomposition DIFF-2/DIFF-3) and the real [confusable] detector (CVD-2).
class ComparisonState {
  /// Creates a snapshot of the two slots and their derived reading.
  const ComparisonState({
    this.slotA,
    this.slotB,
    this.comparison,
    this.confusable = false,
  });

  /// The sample chosen into slot A, or null until one is chosen (AC-1).
  final Sample? slotA;

  /// The sample chosen into slot B, or null until one is chosen (AC-2, AC-12).
  final Sample? slotB;

  /// The relational reading of the pair (ΔE00 + verdict + the three LCh lines),
  /// or null when either slot is empty (AC-4, AC-5, AC-6, AC-12).
  final Comparison? comparison;

  /// Whether the pair is confusable for the painter's CVD profile (AC-7, AC-8).
  /// Always false while either slot is empty.
  final bool confusable;

  /// True once both slots carry a sample — the point at which a relational
  /// statement can be shown (its absence drives the AC-12 invite).
  bool get hasBothSlots => slotA != null && slotB != null;

  @override
  bool operator ==(Object other) =>
      other is ComparisonState &&
      other.slotA == slotA &&
      other.slotB == slotB &&
      other.comparison == comparison &&
      other.confusable == confusable;

  @override
  int get hashCode => Object.hash(slotA, slotB, comparison, confusable);

  @override
  String toString() =>
      'ComparisonState(A: ${slotA?.name ?? '(empty)'}, '
      'B: ${slotB?.name ?? '(empty)'}, '
      '${comparison == null ? 'no comparison' : comparison.toString()}'
      '${confusable ? ', confusable' : ''})';
}
