import 'package:paint_color_assistant/a11y/haptics.dart';

/// A recording [Haptics] for the acceptance suite.
///
/// Stands in for the platform vibrator (D-6): instead of buzzing, it counts
/// confirmation pulses, so AC-12 can assert a just-captured reading fired exactly
/// one confirm (and that a non-fresh reading fired none).
class FakeHaptics implements Haptics {
  int _confirmations = 0;

  /// How many times [confirm] has been called.
  int get confirmations => _confirmations;

  @override
  Future<void> confirm() async {
    _confirmations++;
  }
}
