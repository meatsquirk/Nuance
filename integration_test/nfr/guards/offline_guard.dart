// bs-12 offline / network-block guard (GUARD-2 scaffold).
//
// test-support for the offline (AC-1 / AC-2) and privacy (AC-6) guards: an
// [HttpOverrides] that refuses every outbound connection, a [NetworkAttemptSink]
// that will count the refused attempts, and [runUnderNetworkBlock] to run a body
// with the block installed.
//
// GUARD-2 lays the wiring: [runUnderNetworkBlock] installs the override (a body
// that touches the network fails fast), and the sink exists but is not yet
// incremented. GUARD-3 makes [NetworkBlockingOverrides] record each attempt on
// the sink before refusing, then drives every core flow (capture, readout,
// compare, recipe search, save project, export) through [runUnderNetworkBlock]
// and asserts both a terminal state and zero recorded attempts.
//
// This is test-support only — no `lib/` product code (D-7).

import 'dart:async';
import 'dart:io';

/// Counts outbound network attempts observed while the block is installed.
///
/// A scaffold for GUARD-3: [NetworkBlockingOverrides] will call [record] on
/// every connection attempt before refusing it, and the offline / privacy ACs
/// assert [attempts] stays 0 across a full flow. GUARD-2 leaves the sink inert.
class NetworkAttemptSink {
  int _attempts = 0;

  /// The number of outbound connection attempts recorded so far.
  int get attempts => _attempts;

  /// Records one outbound connection attempt.
  ///
  /// Wired into [NetworkBlockingOverrides] in GUARD-3; unused by the GUARD-2
  /// stub, which refuses connections without recording.
  void record() => _attempts++;

  /// Forgets all recorded attempts.
  void reset() => _attempts = 0;
}

/// Raised by [NetworkBlockingOverrides] when code under the block tries to open
/// an [HttpClient], so a network touch fails fast and visibly.
class NetworkBlockedException implements Exception {
  const NetworkBlockedException();

  @override
  String toString() =>
      'NetworkBlockedException: outbound network is blocked under the bs-12 '
      'offline guard';
}

/// An [HttpOverrides] whose client creation is refused, blocking every outbound
/// HTTP connection for code running under it.
///
/// GUARD-2 refuses by throwing [NetworkBlockedException] from
/// [createHttpClient]; GUARD-3 records the attempt on [sink] before refusing so
/// the offline / privacy ACs can assert zero attempts.
class NetworkBlockingOverrides extends HttpOverrides {
  NetworkBlockingOverrides(this.sink);

  /// Where refused attempts are counted (GUARD-3 wires the increment).
  final NetworkAttemptSink sink;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // GUARD-3: `sink.record()` here before refusing.
    throw const NetworkBlockedException();
  }
}

/// Runs [body] with a [NetworkBlockingOverrides] installed, so any outbound HTTP
/// connection it attempts is refused.
///
/// Returns [body]'s result. Pass a [sink] to inspect the recorded attempts
/// after the body completes (GUARD-3 onward); when omitted a fresh sink is used
/// and discarded. The override is scoped to this call via
/// [HttpOverrides.runWithHttpOverrides] and torn down when [body] completes.
Future<T> runUnderNetworkBlock<T>(
  Future<T> Function() body, {
  NetworkAttemptSink? sink,
}) {
  final attempts = sink ?? NetworkAttemptSink();
  return HttpOverrides.runWithHttpOverrides(
    body,
    NetworkBlockingOverrides(attempts),
  );
}
