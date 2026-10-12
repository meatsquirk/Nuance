import 'package:flutter/foundation.dart';

import 'speech.dart';

/// A [Speech] that remembers the last utterance so it can be replayed
/// (bs-08 SPEECH-1, AC-8).
///
/// Wraps an inner [Speech] — production's [NoopSpeech], the acceptance suite's
/// recording `FakeSpeech` — and delegates every [speak] to it unchanged. Because
/// it *implements [Speech]*, the one app-wide seam becomes repeatable without
/// touching any caller: the readout, comparison and recipe speak paths keep
/// speaking through the same injected [Speech] (D-8), and no second phrasing
/// route is introduced (D-9).
///
/// It additionally records [lastUtterance] on each [speak] and adds [repeat],
/// which re-speaks that last utterance through the inner seam (inert when
/// nothing has been spoken yet). A [ChangeNotifier] so the spoken-output panel
/// (E50) rebuilds as the last utterance changes, mirroring how the display
/// surfaces listen to the `DisplayController`.
class RepeatableSpeech extends ChangeNotifier implements Speech {
  /// Wraps [inner] — the real spoken-output sink every [speak] delegates to.
  RepeatableSpeech(this.inner);

  /// The underlying sink each utterance is spoken through (production
  /// [NoopSpeech]; the suite's recording fake).
  final Speech inner;

  String? _lastUtterance;

  /// The most recent utterance passed to [speak], or null if none yet — the
  /// text the panel (E50) shows and [repeat] replays.
  String? get lastUtterance => _lastUtterance;

  /// Whether there is a last utterance available to [repeat] (false until the
  /// first [speak]).
  bool get canRepeat => _lastUtterance != null;

  @override
  Future<void> speak(String utterance) async {
    _lastUtterance = utterance;
    notifyListeners();
    await inner.speak(utterance);
  }

  /// Re-speaks [lastUtterance] through [inner] (AC-8), or does nothing when
  /// nothing has been spoken yet. It does not change [lastUtterance], so a
  /// repeat replays the exact same utterance through the same sink.
  Future<void> repeat() async {
    final last = _lastUtterance;
    if (last == null) return;
    await inner.speak(last);
  }
}
