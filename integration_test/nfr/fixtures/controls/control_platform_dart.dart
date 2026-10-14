// bs-12 AC-17 CONTROL fixture — a planted *offender* (ITEST-2).
//
// This file deliberately uses platform-conditional constructs (`Platform.is*`
// and a `MethodChannel`) OUTSIDE the one native-capture seam
// (`lib/capture/source/`). It exists ONLY so the AC-17 source guard can prove it
// discriminates: the GUARD-6 scan, pointed at this fixtures directory, MUST list
// this file as a `rulePlatformOutsideSeam` offender.
//
// It lives under `integration_test/nfr/fixtures/controls/`, NOT under `lib/`, so
// the real AC-17 sweep over `lib/` never sees it — the invariant (only native
// capture differs per platform) stays clean. It is never imported; the guard
// reads it as text. The `Platform.is*` here is real code, not a comment or
// string literal, so it is a genuine offender (the scan excludes comments and
// strings, so only live platform code trips it).
//
// Test-support only — no `lib/` product code (D-7).

import 'dart:io';

import 'package:flutter/services.dart';

/// A platform branch living outside `lib/capture/source/` — the AC-17 offence.
String strayPlatformLabel() {
  if (Platform.isIOS) {
    return 'ios';
  } else if (Platform.isAndroid) {
    return 'android';
  }
  return 'other';
}

/// A stray `MethodChannel` outside the capture seam — a second AC-17 offence.
const MethodChannel strayChannel = MethodChannel('com.example.stray/platform');

/// Invokes the stray channel, so the construct is live code (not dead).
Future<int?> strayInvoke() => strayChannel.invokeMethod<int>('ping');
