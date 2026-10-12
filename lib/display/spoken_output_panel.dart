import 'package:flutter/material.dart';

import '../a11y/repeatable_speech.dart';

/// Exposes the app-wide [RepeatableSpeech] to the spoken-output panel (E50) and
/// any descendant that drives or reflects spoken output (bs-08 SPEECH-1).
///
/// An [InheritedNotifier] over the one [RepeatableSpeech] `buildApp` injects, so
/// a dependent rebuilds when the last utterance changes — mirroring
/// `DisplayScope` over the display controller. `buildApp` wraps the whole app in
/// one, above the `MaterialApp`, so the chrome's panel (built in the
/// `MaterialApp.builder`) reads it like any other surface.
class SpeechScope extends InheritedNotifier<RepeatableSpeech> {
  /// Wraps [child], exposing [speech] to the subtree and rebuilding dependents
  /// when it notifies.
  const SpeechScope({
    required RepeatableSpeech speech,
    required super.child,
    super.key,
  }) : super(notifier: speech);

  /// The [RepeatableSpeech] from the nearest enclosing scope, registering the
  /// caller to rebuild on change. Throws if there is none above [context] —
  /// every surface built under `buildApp` has one.
  static RepeatableSpeech of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SpeechScope>();
    assert(scope != null, 'No SpeechScope found above this widget.');
    return scope!.notifier!;
  }

  /// The [RepeatableSpeech] from the nearest enclosing scope, or null when there
  /// is none — for surfaces that may also render standalone, outside the app
  /// assembly.
  static RepeatableSpeech? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpeechScope>()?.notifier;
}

/// The spoken-output panel (wireframe S1.R1, element E50 — bs-08 SPEECH-1).
///
/// A persistent surface the shared app chrome keeps over every screen: it shows
/// the last spoken output and a repeat control that replays it through the one
/// injected [RepeatableSpeech] (AC-8). It has no timer and nothing dismisses it
/// (SPEECH-4 grades AC-10) — it simply reflects the live [SpeechScope].
///
/// Until something has been spoken there is nothing to repeat, so the panel is
/// inert: it collapses to a keyed, zero-size placeholder that is still found by
/// [panelKey] (so it is present from the start) but shows no control or text and
/// takes up no space, leaving every screen's own layout untouched. Once a
/// reading (or comparison, or recipe) has been spoken, the panel shows the
/// [repeatKey] control — enabled — and the [lastSpokenKey] text, and stays.
class SpokenOutputPanel extends StatelessWidget {
  /// Creates the panel; it reads the app-wide [RepeatableSpeech] from the
  /// nearest [SpeechScope].
  const SpokenOutputPanel({super.key});

  /// Stable anchor for E50 — the spoken-output panel surface.
  static const Key panelKey = ValueKey('spoken-output-e50-panel');

  /// Stable anchor for the repeat-last-spoken control.
  static const Key repeatKey = ValueKey('spoken-output-e50-repeat');

  /// Stable anchor for the last-spoken-output text.
  static const Key lastSpokenKey = ValueKey('spoken-output-e50-last');

  @override
  Widget build(BuildContext context) {
    final speech = SpeechScope.of(context);
    return ListenableBuilder(
      listenable: speech,
      builder: (context, _) {
        final last = speech.lastUtterance;
        if (last == null) {
          // Nothing spoken yet: present (keyed) but inert and zero-size.
          return const SizedBox.shrink(key: panelKey);
        }
        return Material(
          key: panelKey,
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  // Shown only when there is a last utterance, so a repeat
                  // always has something to replay (AC-8).
                  key: repeatKey,
                  onPressed: speech.repeat,
                  icon: const Icon(Icons.replay),
                ),
                Flexible(
                  child: Text(
                    last,
                    key: lastSpokenKey,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
