// Coverage gate: enforces 100% line coverage on the Dart library files this
// branch touches.
//
// Rationale (see specs/.../references/verification.md): `flutter test
// --coverage` emits LINE coverage only — the Dart toolchain does not produce
// branch coverage. This gate therefore enforces 100% *line* coverage on every
// touched `lib/**.dart` file; per-branch exercise of new code is a review
// requirement enforced by the phase, not by this tool.
//
// Usage:
//   flutter test --coverage        # produces coverage/lcov.info
//   dart run tool/coverage_gate.dart [<base-ref>]
//
// Base ref resolution (what counts as "touched"): the first CLI argument, else
// the COVERAGE_GATE_BASE environment variable, else `main`. A file is "touched"
// if it differs from the base ref OR is a new untracked file under `lib/`.
//
// Exit codes: 0 = every touched file fully covered (or nothing touched);
// 1 = at least one touched file has uncovered or missing coverage;
// 2 = usage / environment error (no lcov file, git failure).

import 'dart:io';

/// Library files that are generated and therefore exempt from the gate.
bool _isExcluded(String path) {
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.mocks.dart');
}

void main(List<String> args) {
  final baseRef = args.isNotEmpty
      ? args.first
      : (Platform.environment['COVERAGE_GATE_BASE'] ?? 'main');

  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
        'coverage_gate: coverage/lcov.info not found — run '
        '`flutter test --coverage` first.');
    exit(2);
  }

  final touched = _touchedLibFiles(baseRef);
  if (touched.isEmpty) {
    stdout.writeln('coverage_gate: no touched lib/**.dart files vs "$baseRef" '
        '— nothing to gate. PASS');
    exit(0);
  }

  final coverage = _parseLcov(lcov.readAsLinesSync());

  final problems = <String>[];
  for (final file in touched) {
    final lines = _lookup(coverage, file);
    if (lines == null) {
      problems.add('$file: NO COVERAGE DATA (file not present in lcov.info)');
      continue;
    }
    final uncovered = lines.entries
        .where((e) => e.value == 0)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (uncovered.isNotEmpty) {
      final found = lines.length;
      final hit = found - uncovered.length;
      problems.add('$file: $hit/$found lines covered — uncovered lines: '
          '${uncovered.join(', ')}');
    }
  }

  stdout.writeln('coverage_gate: base="$baseRef", '
      '${touched.length} touched lib file(s):');
  for (final f in touched) {
    stdout.writeln('  - $f');
  }

  if (problems.isEmpty) {
    stdout.writeln('coverage_gate: 100% line coverage on all touched files. '
        'PASS');
    exit(0);
  }

  stderr.writeln('coverage_gate: FAIL — line coverage below 100% on touched '
      'files:');
  for (final p in problems) {
    stderr.writeln('  * $p');
  }
  exit(1);
}

/// The set of `lib/**.dart` files changed vs [baseRef] or newly added.
List<String> _touchedLibFiles(String baseRef) {
  final result = <String>{};

  // Tracked changes vs the base ref (committed, staged, and working-tree).
  final diff = _git(['diff', '--name-only', baseRef, '--', 'lib']);
  // New files not yet tracked by git.
  final untracked =
      _git(['ls-files', '--others', '--exclude-standard', '--', 'lib']);

  for (final path in [...diff, ...untracked]) {
    if (!path.endsWith('.dart')) continue;
    if (_isExcluded(path)) continue;
    if (!File(path).existsSync()) continue; // skip deletions
    result.add(path);
  }

  final sorted = result.toList()..sort();
  return sorted;
}

List<String> _git(List<String> args) {
  final r = Process.runSync('git', args);
  if (r.exitCode != 0) {
    stderr.writeln('coverage_gate: `git ${args.join(' ')}` failed: '
        '${r.stderr}');
    exit(2);
  }
  return (r.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

/// Parses lcov records into: source-file-path -> {lineNumber: hitCount}.
Map<String, Map<int, int>> _parseLcov(List<String> lines) {
  final map = <String, Map<int, int>>{};
  String? current;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).trim();
      map[current] = <int, int>{};
    } else if (line.startsWith('DA:') && current != null) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final ln = int.tryParse(parts[0]);
        final hits = int.tryParse(parts[1]);
        if (ln != null && hits != null) {
          map[current]![ln] = hits;
        }
      }
    } else if (line == 'end_of_record') {
      current = null;
    }
  }
  return map;
}

/// Finds the coverage map for [file], matching either the exact lcov path or
/// any lcov source whose path ends with the touched file's path.
Map<int, int>? _lookup(Map<String, Map<int, int>> coverage, String file) {
  if (coverage.containsKey(file)) return coverage[file];
  for (final entry in coverage.entries) {
    if (entry.key == file ||
        entry.key.endsWith('/$file') ||
        file.endsWith('/${entry.key}')) {
      return entry.value;
    }
  }
  return null;
}
