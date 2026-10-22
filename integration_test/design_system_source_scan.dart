// bs-17 AC-14 source-scan helper (ITEST-1).
//
// The read endpoint AC-14's "no screen hardcodes a palette colour" rule reads:
// a scan of the `lib/` source tree for hardcoded colour literals
// (`Color(0x…)`, `Color.fromARGB(…)`, `Color.fromRGBO(…)`) sitting *outside*
// the one theme chokepoint. It mirrors the bs-12 source-scan convention
// (`integration_test/nfr/guards/source_guard.dart`) and reuses that guard's
// comment/string masking so a doc comment or log string naming a `Color(0x…)`
// is never a false offender.
//
// The single source of palette colour is `AppTheme` in `lib/app/theme.dart`
// (D-7); it is the authority allowed to hold the warm-paper literals, so it is
// exempt. Capture's fixed "device" colours are intentional non-palette literals
// excluded by D-4; [kCaptureDeviceLiteralFiles] names those files so AC-14's
// test (APPLY-1 closes the rule) can combine them with the authority.
//
// This scan reads the repo source tree through `dart:io`; under `flutter-tester`
// the current directory is the package root, so `Directory('lib')` resolves —
// the same way the bs-12 source-scan ACs run in this suite.
//
// Test-support only — no `lib/` product code (D-7).

import 'dart:io';

import 'nfr/guards/source_guard.dart' show SourceOffender, maskCommentsAndStrings;

export 'nfr/guards/source_guard.dart' show SourceOffender;

/// The rule a [residualPaletteLiterals] hit breaks (AC-14).
const String ruleHardcodedPalette = 'hardcoded-palette-colour';

/// The one file allowed to hold palette colour literals (D-7): the single
/// `AppTheme` chokepoint every screen reads its colours from. A literal here is
/// the theme *defining* a token, not a screen hardcoding one, so it is exempt
/// from the AC-14 sweep.
const String kThemeAuthorityFile = 'lib/app/theme.dart';

/// The capture "device" colour literals D-4 once excluded from the AC-14 sweep
/// — now **empty** (bs-19 VIEW-4, D-8).
///
/// These emulated a camera surface (the live-view feed / viewfinder), not app
/// chrome, so D-4 exempted the one file that held the literal
/// (`capture_live_view.dart`). bs-19 VIEW-4 themed that camera-surface grey
/// through `AppTheme` ([kThemeAuthorityFile]) — `AppTheme.cameraPlaceholderSurface`
/// — so no `lib/` file hardcodes a camera literal any more and the carve-out
/// silences nothing. D-8 retired it: the theme authority is now the sole
/// file-level exemption. The constant stays (AC-14's test combines it with
/// [kThemeAuthorityFile] in its `exempt` set, and pins it empty) so a future
/// camera literal re-opens the decision deliberately rather than slipping in.
const Set<String> kCaptureDeviceLiteralFiles = <String>{};

/// The default roots the sweep walks — the real shipped product code.
const List<String> kDefaultScanRoots = <String>['lib'];

/// Hardcoded colour literals detected by their constructor signature: a
/// hex-literal `Color(0x…)`, or a `Color.fromARGB(…)` / `Color.fromRGBO(…)`
/// call **whose channel arguments are all numeric literals**.
///
/// A *hardcoded palette colour* is a fixed design literal. A bare `Color(`
/// taking a named const (e.g. `Color(someToken)`) is not one, and neither is a
/// `Color.fromARGB(255, rgb.red, rgb.green, rgb.blue)` that reconstructs a
/// Flutter `Color` from a **runtime** measured/computed sRGB value — that is
/// rendering colour *data*, not hardcoding a palette colour (AC-14 / D-4). So
/// the `fromARGB`/`fromRGBO` patterns only match when the argument list is
/// entirely numeric-literal characters (digits, hex `0x…`, `.`, `,`, `_`,
/// whitespace) up to the closing paren; an identifier argument (a `.red`
/// member access, a variable) stops the match before `)`, so a data
/// reconstruction is never flagged. The `fromARGB(255, 1, 2, 3)` /
/// `fromRGBO(1, 2, 3, 1.0)` literal forms still match.
final List<RegExp> _paletteLiteralPatterns = <RegExp>[
  RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]+'),
  RegExp(r'\bColor\s*\.\s*fromARGB\s*\(\s*[0-9a-fA-FxX.,\s_]*\)'),
  RegExp(r'\bColor\s*\.\s*fromRGBO\s*\(\s*[0-9a-fA-FxX.,\s_]*\)'),
];

/// Normalises a scanned path to forward slashes so the `lib/…` exemptions match
/// on every platform.
String _normalise(String path) => path.replaceAll(r'\', '/');

/// Every site under [roots] that hardcodes a palette colour literal, outside the
/// [exempt] files. Empty while the invariant holds.
///
/// Walks every `.dart` file under each root (recursively, sorted for a
/// deterministic order; a missing root is skipped), masks its comments and
/// string literals, and reports one [SourceOffender] per matched line tagged
/// [ruleHardcodedPalette]. A file whose (slash-normalised) path is in [exempt]
/// is skipped whole — the theme authority and the D-4 capture exclusions.
///
/// [roots] defaults to [kDefaultScanRoots] (the real `lib/` sweep); an AC test
/// or guard points it at a planted control to assert the rule flags it. [exempt]
/// defaults to the theme authority alone; AC-14's test adds
/// [kCaptureDeviceLiteralFiles].
List<SourceOffender> residualPaletteLiterals({
  Iterable<String> roots = kDefaultScanRoots,
  Set<String> exempt = const {kThemeAuthorityFile},
}) {
  final normalisedExempt = {for (final e in exempt) _normalise(e)};
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
      if (normalisedExempt.contains(_normalise(file.path))) continue;
      final source = file.readAsStringSync();
      final masked = maskCommentsAndStrings(source);
      final rawLines = source.split('\n');
      for (final pattern in _paletteLiteralPatterns) {
        for (final match in pattern.allMatches(masked)) {
          final line =
              '\n'.allMatches(masked.substring(0, match.start)).length + 1;
          final snippet =
              (line - 1 < rawLines.length ? rawLines[line - 1] : '').trim();
          offenders.add(SourceOffender(
            path: file.path,
            line: line,
            rule: ruleHardcodedPalette,
            snippet: snippet,
          ));
        }
      }
    }
  }
  return offenders;
}
