import 'package:paint_color_assistant/a11y/haptics.dart';

/// A recording [Haptics] for the acceptance suite.
///
/// Stands in for the platform vibrator: instead of buzzing, it counts
/// confirmation pulses. bs-08 injects it only to satisfy `buildApp`'s [Haptics]
/// dependency — no bs-08 AC exercises haptics — while keeping the count seam for
/// the other features that reuse this fake.
class FakeHaptics implements Haptics {
  int _confirmations = 0;

  /// How many times [confirm] has been called.
  int get confirmations => _confirmations;

  @override
  Future<void> confirm() async {
    _confirmations++;
  }
}
