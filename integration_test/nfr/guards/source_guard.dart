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

/// A caller that references a concrete implementation type directly, rather than
/// through its interface (AC-14 / AC-15 — swappable behind an interface).
const String ruleConcreteTypeReference = 'concrete-type-reference';

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

/// The directory root(s) the source-scan rules walk by default — the real
/// invariant sweep over the shipped product code.
///
/// Every scan takes an optional `roots` so an AC test can point the same rule at
/// a planted control fixture (`integration_test/nfr/fixtures/controls/`) and
/// assert the rule flags it (the discriminating control, ITEST-2). The default
/// is the `lib/` sweep; the stubs ignore `roots` until GUARD-4 / GUARD-6 land
/// the real scans, which honour it.
const List<String> kDefaultSourceRoots = <String>['lib'];

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

/// Sites under [roots] computing a colour-space conversion outside
/// [conversionAuthorityFiles] (AC-16). Empty while the invariant holds.
///
/// [roots] defaults to [kDefaultSourceRoots] (the real `lib/` sweep); an AC test
/// points it at the control fixtures to assert the rule flags a planted stray
/// conversion. Stub: GUARD-6 implements the real scan (honouring [roots]).
List<SourceOffender> conversionOffenders({
  Iterable<String> roots = kDefaultSourceRoots,
}) =>
    const <SourceOffender>[];

/// Sites under [roots] computing a ΔE00 outside [deltaEAuthorityFiles] (AC-16).
/// Empty while the invariant holds.
///
/// [roots] defaults to [kDefaultSourceRoots]; an AC test points it at the
/// control fixtures. Stub: GUARD-6 implements the real scan (honouring [roots]).
List<SourceOffender> deltaEOffenders({
  Iterable<String> roots = kDefaultSourceRoots,
}) =>
    const <SourceOffender>[];

/// Sites under [roots] using a platform-specific construct outside
/// [nativeCaptureSeam] (AC-17). Empty while the invariant holds.
///
/// [roots] defaults to [kDefaultSourceRoots]; an AC test points it at the
/// control fixtures. Stub: GUARD-6 implements the real scan (honouring [roots]).
List<SourceOffender> platformOffenders({
  Iterable<String> roots = kDefaultSourceRoots,
}) =>
    const <SourceOffender>[];

/// Dependencies appearing in [forbiddenDependencyNames] (AC-7). Empty while the
/// invariant holds.
///
/// Scans the resolved pubspec / lockfile by default; an AC test passes
/// [resolvedNames] (e.g. the real set plus a planted forbidden package) to
/// assert the rule flags it. Stub: GUARD-4 implements the real scan.
List<String> forbiddenDependencies({Iterable<String>? resolvedNames}) =>
    const <String>[];

/// Sites under [roots] that send data off the device without explicit opt-in
/// consent (AC-8, D-6). Empty while the invariant holds.
///
/// [roots] defaults to [kDefaultSourceRoots]; an AC test points it at the
/// control fixtures. Stub: GUARD-4 implements the real scan (honouring [roots]).
List<SourceOffender> offDeviceSenders({
  Iterable<String> roots = kDefaultSourceRoots,
}) =>
    const <SourceOffender>[];

/// Sites under [roots] that reference the concrete type [typeName] directly
/// instead of its interface (AC-14 the mixing engine, AC-15 the CVD model).
/// Empty while the invariant holds — a caller must depend on the interface, so
/// the engine / model can be swapped without touching it.
///
/// The real scan (GUARD-5, using GUARD-6's scan infrastructure) excludes the
/// type's own definition file and the single production wiring site; everything
/// else referencing the concrete type is an offender. [roots] defaults to
/// [kDefaultSourceRoots]; an AC test points it at the control fixtures to assert
/// the rule flags a planted bound-to-concrete caller. Stub returns empty.
List<SourceOffender> concreteTypeReferences(
  String typeName, {
  Iterable<String> roots = kDefaultSourceRoots,
}) =>
    const <SourceOffender>[];
