// bs-13 reusable integrity-guard harness (GUARD-1 scaffold).
//
// Test-support only — **no `lib/` product code** (bs-12 D-7). These guards live
// under `integration_test/` and are consumed by the bs-13 acceptance suite
// (ITEST-1 binds to them). They never ship in `lib/`.
//
// This file holds the shared machinery the three bs-13 guards are built on:
//   * a small **source scanner** ([scanDartSources]) that walks a set of roots
//     (directories or individual files), masks comments and string literals so
//     only real code matches, and returns one [SourceMatch] per matching line;
//   * a **schema-check** convenience ([scanSchema]) that points the same scanner
//     at the SEED type-definition file(s) to catch a forbidden field
//     declaration; and
//   * the [GuardOffender] result type every guard returns (empty list = pass)
//     plus the [ruleNotYetEnforced] sentinel the GUARD-1 stubs return.
//
// GUARD-1 lays this machinery, the result type, the default roots and the
// stub guards. The real rule scans — the forbidden patterns and the schema
// field rules — land at GUARD-2 (AC-3 + the AC-1 / AC-4 structural augments);
// each guard then returns real offenders (empty over the shipped seed, the
// planted control listed).
//
// Like bs-12's source guard, these scans read the repo source tree through
// `dart:io`, so they run on the host VM where the cwd is the repo root. bs-13's
// own suite is pure-Dart and runs on `flutter-tester`.

import 'dart:io';

/// The rule identifier the GUARD-1 stubs report while a guard is not yet
/// implemented.
///
/// Every guard here is a stub that returns a single [GuardOffender] tagged with
/// this rule (see [notYetEnforced]). The pending bs-13 acceptance tests assert a
/// guard reports **zero** offenders over the shipped `lib/`, so against these
/// stubs that assertion fails — the intended red baseline (ITEST-2 / ITEST-3).
/// GUARD-2 replaces the stub bodies with the real scans and this sentinel stops
/// appearing.
const String ruleNotYetEnforced = 'not-yet-enforced';

/// The directory root(s) the guards sweep by default — the shipped product code.
///
/// Each guard takes an overridable `roots` so an acceptance test can point the
/// same rule at a planted control fixture and assert the rule flags it (the
/// discriminating control, ITEST). The default is the `lib/` sweep.
const List<String> kLibRoots = <String>['lib'];

/// The SEED type-definition file(s) the schema checks inspect (the no-ratio /
/// no-answer-mapping / no-claimed-value invariants are enforced at the schema
/// level over these definitions).
const List<String> kSeedSchemaFiles = <String>[
  'lib/dataset/seed_dataset.dart',
];

/// A single located site in the scanned source — a line matching a rule pattern.
///
/// Reported by [scanDartSources] / [scanSchema] so a failing assertion can name
/// exactly where an invariant was broken: the repo-relative [path], the 1-based
/// [line], and the raw source [snippet] (comments / strings already excluded
/// from matching).
class SourceMatch {
  /// Creates a located match.
  const SourceMatch({
    required this.path,
    required this.line,
    required this.snippet,
  });

  /// Repo-relative path of the matching file (e.g. `lib/dataset/seed_dataset.dart`).
  final String path;

  /// 1-based line number of the match.
  final int line;

  /// The raw source line that matched (comments / strings excluded from the
  /// match itself, but shown verbatim here).
  final String snippet;

  @override
  String toString() => '$path:$line  $snippet';
}

/// One site that breaks a bs-13 integrity invariant, as reported by a guard.
///
/// A guard returns a list of these; an **empty** list means the invariant holds
/// (pass). The acceptance tests assert "zero offenders" over the shipped code
/// and assert the planted control is listed. A GUARD-1 stub returns a single
/// offender tagged [ruleNotYetEnforced] (see [notYetEnforced]).
class GuardOffender {
  /// Creates an offender for [rule] with a human-readable [detail]; [path] and
  /// [line] locate it when it comes from a source scan.
  const GuardOffender({
    required this.rule,
    required this.detail,
    this.path,
    this.line,
  });

  /// The invariant this site breaks (a rule identifier; [ruleNotYetEnforced] for
  /// the GUARD-1 stubs).
  final String rule;

  /// A human-readable description of the offending site.
  final String detail;

  /// Repo-relative path of the offending file, when it came from a source scan.
  final String? path;

  /// 1-based line number of the offending site, when known.
  final int? line;

  @override
  String toString() {
    final where = path == null ? '' : ' ($path:${line ?? '?'})';
    return '[$rule] $detail$where';
  }
}

/// The single offender a GUARD-1 stub returns, tagging [guardName] as not yet
/// implemented. Centralised so every stub reports the sentinel identically.
List<GuardOffender> notYetEnforced(String guardName) => <GuardOffender>[
      GuardOffender(
        rule: ruleNotYetEnforced,
        detail: '$guardName not yet enforced (GUARD-1 shell; '
            'real scan lands at GUARD-2)',
      ),
    ];

/// Walks every `.dart` file under each of [roots] and returns one [SourceMatch]
/// per line matching any of [patterns].
///
/// A root that names a directory is walked recursively; a root that names a
/// single `.dart` file is scanned directly (so [scanSchema] can target the SEED
/// definition file). Files are visited in a deterministic sorted order and a
/// missing root is skipped. Each file's text is run through
/// [maskCommentsAndStrings] before matching, so a doc comment or string literal
/// naming a forbidden token is never a false match; the reported [SourceMatch.snippet]
/// is the raw source line.
///
/// When [isAllowed] is given, a file whose path it accepts is an exempt
/// authority and is skipped whole — so the scan reports only files that are
/// *not* permitted to carry the construct. Paths resolve against the current
/// directory (the repo root on the host VM).
List<SourceMatch> scanDartSources({
  Iterable<String> roots = kLibRoots,
  required List<RegExp> patterns,
  bool Function(String path)? isAllowed,
}) {
  final matches = <SourceMatch>[];
  for (final file in _dartFilesUnder(roots)) {
    if (isAllowed != null && isAllowed(file.path)) continue;
    final source = file.readAsStringSync();
    final masked = maskCommentsAndStrings(source);
    final rawLines = source.split('\n');
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(masked)) {
        final line =
            '\n'.allMatches(masked.substring(0, match.start)).length + 1;
        final snippet =
            (line - 1 < rawLines.length ? rawLines[line - 1] : '').trim();
        matches.add(SourceMatch(
          path: _normaliseScanPath(file.path),
          line: line,
          snippet: snippet,
        ));
      }
    }
  }
  return matches;
}

/// Scans the SEED type-definition [schemaFiles] for a forbidden field
/// declaration matching any of [fieldPatterns].
///
/// A thin convenience over [scanDartSources] that treats the schema files as
/// the roots — used by the no-ratio / no-answer-mapping / no-claimed-value
/// schema checks (GUARD-2) to prove the seed schema carries no ratio field, no
/// target→recipe answer mapping and no claimed spectral/ratio field.
List<SourceMatch> scanSchema({
  Iterable<String> schemaFiles = kSeedSchemaFiles,
  required List<RegExp> fieldPatterns,
}) =>
    scanDartSources(roots: schemaFiles, patterns: fieldPatterns);

/// Every `.dart` file reachable from [roots], sorted for determinism. A root
/// that is a directory is walked recursively; a root that is an existing `.dart`
/// file is yielded directly; anything else is skipped.
List<File> _dartFilesUnder(Iterable<String> roots) {
  final files = <File>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (dir.existsSync()) {
      files.addAll(dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')));
      continue;
    }
    final file = File(root);
    if (file.existsSync() && root.endsWith('.dart')) files.add(file);
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// Normalises a scanned file path to forward slashes so the `lib/…` path
/// constants match on every platform.
String _normaliseScanPath(String path) => path.replaceAll(r'\', '/');

/// Returns [source] with every line comment, block comment and string literal
/// blanked to spaces — newlines preserved, so line numbers are unchanged — so a
/// rule scan matches real code only.
///
/// A doc comment naming a forbidden field or a log string mentioning a forbidden
/// token is therefore never a false match. Handles `//` and `/* … */` comments
/// and single / double / triple-quoted strings, honouring `\` escapes in
/// single-line non-raw strings and the `r` raw-string prefix. (Ported from the
/// bs-12 source guard — shared test-support machinery.)
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
