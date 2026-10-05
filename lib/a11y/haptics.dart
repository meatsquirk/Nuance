/// Haptic feedback for the app, behind a thin injectable interface.
///
/// One [Haptics] instance is injected app-wide (registered in `buildApp` by
/// CORE-3). Keeping it behind this seam lets later features add vibration
/// patterns without touching callers (SI: accessibility is architectural). The
/// acceptance suite injects a recording `FakeHaptics` (D-6) to observe pulses
/// (AC-12).
abstract interface class Haptics {
  /// Fires a single confirmation pulse (e.g. a captured reading has landed).
  Future<void> confirm();
}

/// The bs-01 production [Haptics]: a no-op placeholder.
///
/// bs-01 has no native integration (D-1), so the shipped app does not yet drive
/// the platform vibrator — a later feature replaces this with a platform-backed
/// impl behind the same [Haptics] seam. The confirm *action* (firing
/// [confirm] when a just-captured readout renders) is wired into the readout
/// controller in A11Y-2, where the acceptance test observes it through the
/// injected fake.
class NoopHaptics implements Haptics {
  const NoopHaptics();

  @override
  Future<void> confirm() async {
    // Intentionally does nothing: no platform haptics in bs-01 (D-1).
  }
}
