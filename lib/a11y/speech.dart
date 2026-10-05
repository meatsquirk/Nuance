/// Spoken output for the app, behind a thin injectable interface.
///
/// One [Speech] instance is injected app-wide (registered in `buildApp` by
/// CORE-3) so that consistent phrasing lives behind this seam rather than in
/// each screen — later features (bs-08) extend the phrasing without touching
/// callers (SI: accessibility is architectural). The acceptance suite injects a
/// recording `FakeSpeech` (D-6) to observe utterances (AC-8).
abstract interface class Speech {
  /// Speaks [utterance] once.
  Future<void> speak(String utterance);
}

/// The bs-01 production [Speech]: a no-op placeholder.
///
/// bs-01 is pure-Dart logic + widgets with no native integration (D-1), so the
/// shipped app does not yet drive platform text-to-speech — a later feature
/// replaces this with a platform-TTS-backed impl behind the same [Speech] seam.
/// The speak *action* (building the utterance and calling [speak] once) is wired
/// into the readout controller in A11Y-2, where the acceptance test observes it
/// through the injected fake.
class NoopSpeech implements Speech {
  const NoopSpeech();

  @override
  Future<void> speak(String utterance) async {
    // Intentionally does nothing: no platform TTS in bs-01 (D-1).
  }
}
