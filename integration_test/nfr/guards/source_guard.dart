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
//
// These scans read the repo source tree through `dart:io`, so they run on the
// host VM (cwd = repo root), where the existing repo-file tests live
// (`test/color_science/munsell_table_test.dart` reads `assets/…` the same way).
// The app-pumping ACs in the same suite are `flutter_tester`-compatible, so the
// whole bs-12 acceptance file runs there too.

import 'dart:io';

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
// Rule scans
//
// [forbiddenDependencies] / [offDeviceSenders] (GUARD-4, AC-7 / AC-8) and
// [concreteTypeReferences] (GUARD-5, AC-14 / AC-15) are the real scans;
// [conversionOffenders] / [deltaEOffenders] / [platformOffenders] remain GUARD-2
// stubs until GUARD-6 fills them. Each reuses the shared [maskCommentsAndStrings]
// machinery GUARD-4 lays at the foot of this file.
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
/// With no [resolvedNames] it reads the resolved dependency set from the
/// `pubspec.lock` at the repo root ([resolvedDependencyNames]); an AC test
/// passes [resolvedNames] (e.g. the real set plus a planted forbidden package)
/// to assert the rule flags it. The result keeps [forbiddenDependencyNames]'
/// order so it is deterministic.
List<String> forbiddenDependencies({Iterable<String>? resolvedNames}) {
  final present = (resolvedNames ?? resolvedDependencyNames()).toSet();
  return <String>[
    for (final name in forbiddenDependencyNames)
      if (present.contains(name)) name,
  ];
}

/// Sites under [roots] that send data off the device without explicit opt-in
/// consent (AC-8, D-6): constructing an outbound connection or issuing an HTTP
/// request. Empty while the invariant holds — v1 ships no off-device path.
///
/// [roots] defaults to [kDefaultSourceRoots] (the real `lib/` sweep); an AC test
/// points it at the control fixtures to assert the rule flags the planted
/// unconsented sender. Comments and string literals are excluded, so a doc
/// comment or log string naming an egress API is never a false offender.
List<SourceOffender> offDeviceSenders({
  Iterable<String> roots = kDefaultSourceRoots,
}) =>
    _scanSource(roots, ruleOffDeviceSender, _offDeviceSendPatterns);

/// Sites under [roots] that couple a caller to the concrete type [typeName]
/// directly instead of its interface (AC-14 the mixing engine, AC-15 the CVD
/// model). Empty while the invariant holds — a caller must depend on the
/// interface, so the engine / model can be swapped without touching it.
///
/// A *coupling* is a use of [typeName] in a type position — declaring a field,
/// variable, parameter or return of the concrete type, or naming it as a type
/// argument / supertype — which a swap could not survive without a caller edit.
/// It is **not** a coupling to:
///   * construct the shipped default (`const SubtractiveMixingEngine()`), the
///     dependency-injection binding every injectable defaults to — matched when
///     [typeName] is immediately followed by `(`;
///   * import or export the concrete name (so a file can construct that
///     default) — matched on an `import` / `export` directive line;
///   * define the type itself — its own definition file (the file declaring
///     `class` / `mixin` / `enum` / `extension` [typeName]) is skipped whole.
///
/// Comments and string literals are excluded ([maskCommentsAndStrings]), so a
/// doc comment or log string naming the concrete type is never a false
/// offender. [roots] defaults to [kDefaultSourceRoots] (the real `lib/` sweep);
/// an AC test points it at the control fixtures to assert the rule flags a
/// planted bound-to-concrete caller.
List<SourceOffender> concreteTypeReferences(
  String typeName, {
  Iterable<String> roots = kDefaultSourceRoots,
}) {
  // A type-position use of the name: a word-boundary match NOT immediately
  // followed by `(` (which would be a constructor invocation — the DI default).
  final reference = RegExp('\\b$typeName\\b(?!\\s*\\()');
  // The type's own definition — the file declaring it is never a caller.
  final definition = RegExp('\\b(?:class|mixin|enum|extension)\\s+$typeName\\b');
  final offenders = <SourceOffender>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final masked = maskCommentsAndStrings(source);
      if (definition.hasMatch(masked)) continue; // the type's own definition
      final maskedLines = masked.split('\n');
      final rawLines = source.split('\n');
      for (var i = 0; i < maskedLines.length; i++) {
        final maskedLine = maskedLines[i];
        final trimmed = maskedLine.trimLeft();
        // An import / export directive brings the name into scope so the file
        // can construct the shipped default — not a caller coupling.
        if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
          continue;
        }
        for (final _ in reference.allMatches(maskedLine)) {
          offenders.add(SourceOffender(
            path: file.path,
            line: i + 1,
            rule: ruleConcreteTypeReference,
            snippet: (i < rawLines.length ? rawLines[i] : '').trim(),
          ));
        }
      }
    }
  }
  return offenders;
}

// ---------------------------------------------------------------------------
// Shared scan machinery (GUARD-4 — reused by GUARD-5 / GUARD-6)
// ---------------------------------------------------------------------------

/// The off-device-send API surface the AC-8 scan flags: opening an outbound
/// socket / HTTP client or issuing an HTTP request. A v1 build has none in
/// `lib/`; the planted control fixture (`control_off_device_sender.dart`) opens
/// an `HttpClient` and POSTs, so the scan must list it.
final List<RegExp> _offDeviceSendPatterns = <RegExp>[
  RegExp(r'\bHttpClient\s*\('),
  RegExp(r'\b(?:Secure)?Socket\s*\.\s*(?:connect|startConnect)\b'),
  RegExp(r'\bRaw(?:Secure)?Socket\s*\.\s*connect\b'),
  RegExp(r'\bWebSocket\s*\.\s*connect\b'),
  RegExp(r'\bRawDatagramSocket\s*\.\s*bind\b'),
  RegExp(r'\bhttp\s*\.\s*(?:get|post|put|patch|delete|head|read)\s*\('),
];

/// Walks every `.dart` file under each of [roots] (recursively, sorted for a
/// deterministic order) and returns one [SourceOffender] per line matching any
/// of [patterns], tagged [rule]. A missing root is skipped. The file text is run
/// through [maskCommentsAndStrings] first, so only real code is matched; the
/// reported snippet is the raw source line.
///
/// Paths are resolved against the current directory (the repo root on the host
/// VM, where these scans run — see the file header).
List<SourceOffender> _scanSource(
  Iterable<String> roots,
  String rule,
  List<RegExp> patterns,
) {
  final offenders = <SourceOffender>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final masked = maskCommentsAndStrings(source);
      final rawLines = source.split('\n');
      for (final pattern in patterns) {
        for (final match in pattern.allMatches(masked)) {
          final line =
              '\n'.allMatches(masked.substring(0, match.start)).length + 1;
          final snippet =
              (line - 1 < rawLines.length ? rawLines[line - 1] : '').trim();
          offenders.add(SourceOffender(
            path: file.path,
            line: line,
            rule: rule,
            snippet: snippet,
          ));
        }
      }
    }
  }
  return offenders;
}

/// Returns [source] with every line comment, block comment and string literal
/// blanked to spaces — newlines preserved, so line numbers are unchanged — so a
/// rule scan matches real code only. A doc comment naming `HttpClient(` or a log
/// string mentioning a forbidden API is therefore never a false offender
/// (module plan, Interface reconciliation). Handles `//` and `/* … */`
/// comments and single / double / triple-quoted strings, honouring `\` escapes
/// in single-line non-raw strings and the `r` raw-string prefix.
String maskCommentsAndStrings(String source) {
  final out = StringBuffer();
  final n = source.length;
  var i = 0;
  while (i < n) {
    final c = source[i];
    final next = i + 1 < n ? source[i + 1] : '';
    // Line comment: blank to end of line.
    if (c == '/' && next == '/') {
      while (i < n && source[i] != '\n') {
        out.write(' ');
        i++;
      }
      continue;
    }
    // Block comment: blank through the closing `*/` (may span lines).
    if (c == '/' && next == '*') {
      out.write('  ');
      i += 2;
      while (
          i < n && !(source[i] == '*' && i + 1 < n && source[i + 1] == '/')) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      if (i < n) {
        out.write('  ');
        i += 2;
      }
      continue;
    }
    // String literal (single / double, optionally triple, optionally raw).
    if (c == '"' || c == "'") {
      final isRaw = i > 0 &&
          source[i - 1] == 'r' &&
          (i < 2 || !_isIdentChar(source[i - 2]));
      final triple = next == c && i + 2 < n && source[i + 2] == c;
      final delim = c;
      if (triple) {
        out.write('   ');
        i += 3;
        while (i < n &&
            !(source[i] == delim &&
                i + 2 < n &&
                source[i + 1] == delim &&
                source[i + 2] == delim)) {
          out.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
        if (i < n) {
          out.write('   ');
          i += 3;
        }
      } else {
        out.write(' ');
        i++;
        while (i < n && source[i] != delim && source[i] != '\n') {
          if (!isRaw && source[i] == r'\' && i + 1 < n) {
            out.write('  ');
            i += 2;
            continue;
          }
          out.write(' ');
          i++;
        }
        if (i < n && source[i] == delim) {
          out.write(' ');
          i++;
        }
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

bool _isIdentChar(String ch) => RegExp(r'[A-Za-z0-9_$]').hasMatch(ch);

/// The resolved dependency names from the lockfile at [lockPath] (default
/// `pubspec.lock` at the repo root), or an empty set when it is absent.
Set<String> resolvedDependencyNames({String lockPath = 'pubspec.lock'}) {
  final file = File(lockPath);
  if (!file.existsSync()) return const <String>{};
  return parseLockPackageNames(file.readAsStringSync());
}

/// Parses the resolved package names from a `pubspec.lock` [text] — the keys of
/// its top-level `packages:` map (the 2-space-indented entries under it).
Set<String> parseLockPackageNames(String text) {
  final names = <String>{};
  final entry = RegExp(r'^  ([A-Za-z0-9_]+):\s*$');
  var inPackages = false;
  for (final line in text.split('\n')) {
    // A line with no leading space and some content is a top-level key; we are
    // inside the package map only while that key is `packages:`.
    if (line.isNotEmpty && !line.startsWith(' ')) {
      inPackages = line.trimRight() == 'packages:';
      continue;
    }
    if (!inPackages) continue;
    final match = entry.firstMatch(line);
    if (match != null) names.add(match.group(1)!);
  }
  return names;
}
