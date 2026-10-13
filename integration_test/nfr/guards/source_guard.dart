// bs-12 source-scan guard (GUARD-2 scaffold).
//
// A test-support utility that reads the `lib/` source tree and reports, per
// rule, the sites that break a bs-12 invariant:
//   * AC-16 — a colour-space conversion ([conversionOffenders]) or a ΔE00
//     computation ([deltaEOffenders]) written outside the colour authorities.
//   * AC-17 — a platform-specific construct ([platformOffenders]) outside the
//     one native-capture seam.
//   * AC-7  — a forbidden dependency ([forbiddenDependencies]) in the resolved
//     pubspec / lockfile.
//   * AC-8  — an off-device sender ([offDeviceSenders]).
//
// GUARD-2 lays the signatures, the authority / allow-list constants and
// empty-result stubs, so the existing suite stays green and ITEST-1's smoke
// test can call every rule. The real scans land later: GUARD-6 fills
// [conversionOffenders] / [deltaEOffenders] / [platformOffenders] (AC-16/17)
// and GUARD-4 fills [forbiddenDependencies] / [offDeviceSenders] (AC-7/8). Each
// scan must read text while *excluding* comments and string literals, so a doc
// comment naming `Platform.is` or a log string mentioning a forbidden package
// is never a false offender (module plan, Interface reconciliation).
//
// This is test-support only — no `lib/` product code (D-7).

/// A single site in `lib/` that breaks one of the source-scan rules.
///
/// Reported by the rule scans so a failing assertion can name exactly where the
/// invariant was broken (path, 1-based line, the offending snippet and which
/// rule it tripped). The scans return an empty list while the invariant holds.
class SourceOffender {
  const SourceOffender({
    required this.path,
    required this.line,
    required this.rule,
    required this.snippet,
  });

  /// Repo-relative path of the offending file (e.g. `lib/foo/bar.dart`).
  final String path;

  /// 1-based line number of the offending site.
  final int line;

  /// The rule this site breaks (one of the `rule*` constants below).
  final String rule;

  /// The offending source text (comments / strings already excluded).
  final String snippet;

  @override
  String toString() => '$path:$line [$rule] $snippet';
}

// ---------------------------------------------------------------------------
// Rule identifiers
// ---------------------------------------------------------------------------

/// A colour-space conversion computed outside [conversionAuthorityFiles].
const String ruleStrayConversion = 'stray-colour-conversion';

/// A ΔE00 (CIEDE2000) computed outside [deltaEAuthorityFiles].
const String ruleStrayDeltaE = 'stray-delta-e';

/// A platform-specific construct outside [nativeCaptureSeam].
const String rulePlatformOutsideSeam = 'platform-outside-capture-seam';

/// An off-device sender reachable without explicit, opt-in consent.
const String ruleOffDeviceSender = 'off-device-sender';

// ---------------------------------------------------------------------------
// Authorities and allow-lists
// ---------------------------------------------------------------------------

/// The only files allowed to compute a colour-space conversion (AC-16).
///
/// `lib/color_science/` holds the one tested colour-science library
/// (`ColorScience` + its impl + the `conversions.dart` primitives); any other
/// `lib/` file computing a conversion is a [conversionOffenders] offender.
const Set<String> conversionAuthorityFiles = {
  'lib/color_science/color_science.dart',
  'lib/color_science/color_science_impl.dart',
  'lib/color_science/conversions.dart',
};

/// The only files allowed to compute a ΔE00 (AC-16).
///
/// The shipped CIEDE2000 lives in `lib/compare/difference.dart`; every other
/// feature reads it through `compare(...)` / `Comparison.deltaE00` rather than
/// computing a second copy.
const Set<String> deltaEAuthorityFiles = {
  'lib/compare/difference.dart',
};

/// The one seam allowed to hold platform-specific code (AC-17).
///
/// Only native capture differs per platform; a `Platform.is*` / `MethodChannel`
/// / `EventChannel` / platform conditional import anywhere under this directory
/// prefix is allowed, and anywhere else is a [platformOffenders] offender.
const String nativeCaptureSeam = 'lib/capture/source/';

/// Package names a v1 (offline, no-account, no-telemetry) build must not depend
/// on (AC-7 / AC-8).
///
/// Analytics / crash / telemetry SDKs and account / remote-sync clients. The
/// [forbiddenDependencies] scan reports any of these present in the resolved
/// dependency set; a planted name is the control that proves the scan trips.
const Set<String> forbiddenDependencyNames = {
  'firebase_analytics',
  'firebase_crashlytics',
  'firebase_core',
  'firebase_auth',
  'sentry',
  'sentry_flutter',
  'amplitude_flutter',
  'mixpanel_flutter',
  'segment_analytics',
  'google_sign_in',
  'amplify_flutter',
  'supabase_flutter',
  'posthog_flutter',
  'datadog_flutter_plugin',
};

// ---------------------------------------------------------------------------
// Rule scans (GUARD-2 stubs — real scans land in GUARD-4 / GUARD-6)
// ---------------------------------------------------------------------------

/// `lib/` sites computing a colour-space conversion outside
/// [conversionAuthorityFiles] (AC-16). Empty while the invariant holds.
///
/// Stub: GUARD-6 implements the real scan.
List<SourceOffender> conversionOffenders() => const <SourceOffender>[];

/// `lib/` sites computing a ΔE00 outside [deltaEAuthorityFiles] (AC-16). Empty
/// while the invariant holds.
///
/// Stub: GUARD-6 implements the real scan.
List<SourceOffender> deltaEOffenders() => const <SourceOffender>[];

/// `lib/` sites using a platform-specific construct outside [nativeCaptureSeam]
/// (AC-17). Empty while the invariant holds.
///
/// Stub: GUARD-6 implements the real scan.
List<SourceOffender> platformOffenders() => const <SourceOffender>[];

/// Resolved dependencies that appear in [forbiddenDependencyNames] (AC-7).
/// Empty while the invariant holds.
///
/// Stub: GUARD-4 implements the real scan over the pubspec / lockfile.
List<String> forbiddenDependencies() => const <String>[];

/// `lib/` sites that send data off the device without explicit opt-in consent
/// (AC-8, D-6). Empty while the invariant holds.
///
/// Stub: GUARD-4 implements the real scan.
List<SourceOffender> offDeviceSenders() => const <SourceOffender>[];
