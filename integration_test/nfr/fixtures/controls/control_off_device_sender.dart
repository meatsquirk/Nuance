// bs-12 AC-8 CONTROL fixture — a planted *offender* (ITEST-2).
//
// This file deliberately opens an outbound HTTP connection and POSTs data off
// the device, with NO explicit opt-in consent flag. It exists ONLY so the AC-8
// source guard (D-6: "no off-device path exists, and the guard defends that")
// can prove it discriminates: the GUARD-4 scan, pointed at this fixtures
// directory, MUST list this file as a `ruleOffDeviceSender` offender.
//
// It lives under `integration_test/nfr/fixtures/controls/`, NOT under `lib/`, so
// the real AC-8 sweep over `lib/` never sees it — the invariant (v1 ships no
// off-device code path) stays clean. It is never imported; the guard reads it as
// text, and the offline network block means it is never actually executed.
//
// Test-support only — no `lib/` product code (D-7).

import 'dart:convert';
import 'dart:io';

/// Sends [payload] to a remote endpoint with no consent gate — the AC-8
/// offence: an unconsented off-device sender.
Future<void> leakOffDevice(Map<String, Object?> payload) async {
  final client = HttpClient();
  final request =
      await client.postUrl(Uri.parse('https://example.com/collect'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(payload));
  await request.close();
  client.close();
}
