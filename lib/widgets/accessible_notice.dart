import 'package:flutter/material.dart';

/// A notice surface that **never** auto-dismisses.
///
/// Replaces `SnackBar`/toast surfaces that vanish on a timer (WCAG 2.2 "Enough
/// Time" / SI Accessibility): the [message] stays until the viewer dismisses it
/// through the explicit control, so a screen-reader user is never raced off a
/// message before they have read it. This is the **A11Y-1 shell** — the
/// primitive exists and is unit-covered but is used nowhere yet; A11Y-7 routes
/// every transient surface through it (AC-8).
///
/// By construction it holds **no** `Timer` and takes **no** `Duration`: there is
/// no code path that dismisses it on its own.
class AccessibleNotice extends StatelessWidget {
  const AccessibleNotice({
    required this.message,
    this.onDismiss,
    this.dismissLabel = 'Dismiss',
    super.key,
  }) : assert(
          message != '',
          'AccessibleNotice requires a non-empty message.',
        );

  /// The notice text, announced to assistive tech as a live region.
  final String message;

  /// Invoked when the viewer presses the explicit dismiss control. When null no
  /// control is shown and the notice is dismissed by its host instead.
  final VoidCallback? onDismiss;

  /// The label on the dismiss control (when [onDismiss] is provided).
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        children: [
          Expanded(child: Text(message)),
          if (onDismiss != null)
            TextButton(onPressed: onDismiss, child: Text(dismissLabel)),
        ],
      ),
    );
  }
}
